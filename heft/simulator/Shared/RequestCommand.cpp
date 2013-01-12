#include "StdAfx.h"
#include "RequestCommand.h"
#include "ResponseCommand.h"

const int ciTransactionDeclinedAmount = 1000;
const int ciUserCancelAmount = 2000;
const int ciSignRequestAmount = 3000;

ResponseCommand* RequestCommand::CreateResponse()const{return new ResponseCommand(m_cmd);}

ResponseCommand* RequestCommand::CreateResponseOnCancel()const{return new ResponseCommand(m_cmd, EFT_PP_STATUS_USER_CANCELLED);}

FinanceRequestCommand::FinanceRequestCommand(UINT32 type, const string& currency_code, UINT32 trans_amount, UINT8 card_present) 
	: RequestCommand(type)
	, state(eWaitingCard), amount(trans_amount)
{
	const int currency_code_length = 4;
	
	static const struct CurrencyCode{
		char name[4];
		char code[currency_code_length + 1];
	} ISO4217CurrencyCodes[] = {
		"USD", "0840"
		, "EUR", "0978"
		, "GBP", "0826"
		, "ISK", "0352"
	};
	
	bool fCheckCodeSize = true;
	const char* code = currency_code.c_str();
	for(int i = 0; i < dim(ISO4217CurrencyCodes); ++i){
		CurrencyCode cc = ISO4217CurrencyCodes[i];
		if(!currency_code.compare(cc.name)){
			code = cc.code;
			fCheckCodeSize = false;
			break;
		}
	}
	
	if(fCheckCodeSize && currency_code.length() != sizeof(ISO4217CurrencyCodes[0].code))
		throw std::invalid_argument("invalid currency code");
}

ResponseCommand* FinanceRequestCommand::CreateResponse()const{
	ResponseCommand* result = 0;
	switch(state++){
	case eWaitingCard:
		result = new EventInfoResponseCommand(EFT_PP_STATUS_WAITING_CARD);
		break;
	case eCardInserted:
		result = new EventInfoResponseCommand(EFT_PP_STATUS_CARD_INSERTED);
		break;
	case eAppSelect:
		result = new EventInfoResponseCommand(EFT_PP_STATUS_APPLICATION_SELECTION);
		break;
	case ePinInput:
		result = amount == ciSignRequestAmount ? reinterpret_cast<ResponseCommand*>(new SignatureRequestCommand(amount, GetType())) : new EventInfoResponseCommand(EFT_PP_STATUS_PIN_INPUT);
		break;
	case eConnect:
		result = amount == ciUserCancelAmount ? CreateResponseOnCancel() : reinterpret_cast<ResponseCommand*>(new ConnectRequestCommand(amount, GetType()));
		break;
	}
	return result;
}

SaleRequestCommand::SaleRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present) 
	: FinanceRequestCommand(CMD_FIN_SALE_REQ, currency_code, trans_amount, card_present)
{}

RefundRequestCommand::RefundRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present)
	: FinanceRequestCommand(CMD_FIN_REFUND_REQ, currency_code, trans_amount, card_present)
{}

ResponseCommand* RefundRequestCommand::CreateResponse()const{
	if(state == ePinInput)
		++state;
	return FinanceRequestCommand::CreateResponse();
}

FinanceVRequestCommand::FinanceVRequestCommand(UINT32 type, const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id)
	: FinanceRequestCommand(type, currency_code, trans_amount, card_present)
{
	state = eConnect;
}

SaleVRequestCommand::SaleVRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id) 
	: FinanceVRequestCommand(CMD_FIN_SALEV_REQ, currency_code, trans_amount, card_present, trans_id)

{}

RefundVRequestCommand::RefundVRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id)
	: FinanceVRequestCommand(CMD_FIN_REFUNDV_REQ, currency_code, trans_amount, card_present, trans_id)

{}

StartOfDayRequestCommand::StartOfDayRequestCommand()
	: RequestCommand(CMD_FIN_STARTDAY_REQ)
{}

EndOfDayRequestCommand::EndOfDayRequestCommand()
	: RequestCommand(CMD_FIN_ENDDAY_REQ)
{}

FinanceInitRequestCommand::FinanceInitRequestCommand()
	: RequestCommand(CMD_FIN_INIT_REQ)
{}

HostResponseCommand::HostResponseCommand(UINT32 command, UINT32 aFin_cmd, UINT32 aAmount, int aStatus) 
	: RequestCommand(command)
	, fin_cmd(aFin_cmd), amount(aAmount), status(aStatus)
{
}

ResponseCommand* HostResponseCommand::CreateResponse()const{
	RequestCommand* result = 0;
	switch(m_cmd){
	case CMD_HOST_CONN_RSP:
		result = new SendRequestCommand(amount, fin_cmd);
		break;
	case CMD_HOST_SEND_RSP:
		result = new ReceiveRequestCommand(amount, fin_cmd);
		break;
	case CMD_HOST_RECV_RSP:
		result = new DisconnectRequestCommand(amount, fin_cmd);
		break;
	case CMD_HOST_DISC_RSP:
		return new FinanceResponseCommand(fin_cmd, amount, amount == ciTransactionDeclinedAmount ? eTransactionDeclined : eTransactionApproved);
	case CMD_STAT_SIGN_RSP:
		if(status == EFT_PP_STATUS_SUCCESS)
			result = new ConnectRequestCommand(amount, fin_cmd);
		else
			return new FinanceResponseCommand(fin_cmd, amount, eTransactionNotProcessed);
	}
	return reinterpret_cast<ResponseCommand*>(result);
}

ConnectRequestCommand::ConnectRequestCommand(UINT32 aAmount, UINT32 aFin_cmd)
	: HostRequestCommand(CMD_HOST_CONN_REQ, aAmount, aFin_cmd)
{
}

SendRequestCommand::SendRequestCommand(UINT32 aAmount, UINT32 aFin_cmd)
	: HostRequestCommand(CMD_HOST_SEND_REQ, aAmount, aFin_cmd)
{
}

ReceiveRequestCommand::ReceiveRequestCommand(UINT32 aAmount, UINT32 aFin_cmd)
	: HostRequestCommand(CMD_HOST_RECV_REQ, aAmount, aFin_cmd)
{
}

DisconnectRequestCommand::DisconnectRequestCommand(UINT32 aAmount, UINT32 aFin_cmd)
	: HostRequestCommand(CMD_HOST_DISC_REQ, aAmount, aFin_cmd)
{
}

SignatureRequestCommand::SignatureRequestCommand(UINT32 aAmount, UINT32 aType) 
	: RequestCommand(CMD_STAT_SIGN_REQ), amount(aAmount), type(aType)
{
	NSString* trans_id = [NSString stringWithFormat:@"transactID%d", trans_id_seed];

	NSString* buf = [NSString stringWithFormat:@"<p>Financial transaction #<b>%@</b></p>"
					 "<p>Type: <b>%@</b></p>"
					 "<p>Time: <b>%@</b></p>"
					 "<p>Amount: <b>%.2f</b></p>"
					 "<p>Card number: <b>**** **** **** ****</b></p>"
					 "<p>Please sign: ___________________</p>"
					 , trans_id
					 , fin_type[(type >> 8) & 0xf]
					 , [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]
					 , double(amount / 100)];
	receipt = [buf cStringUsingEncoding:NSUTF8StringEncoding];
}

DebugEnableRequestCommand::DebugEnableRequestCommand()
	: RequestCommand(CMD_DBG_ENABLE_REQ)
{}

DebugDisableRequestCommand::DebugDisableRequestCommand()
	: RequestCommand(CMD_DBG_DISABLE_REQ)
{}

DebugResetRequestCommand::DebugResetRequestCommand()
	: RequestCommand(CMD_DBG_RESET_REQ)
{}

DebugInfoRequestCommand::DebugInfoRequestCommand()
	: RequestCommand(CMD_DBG_INFO_REQ)
{}

ResponseCommand* DebugInfoRequestCommand::CreateResponse()const{return new DebugInfoResponseCommand;}

SetLogLevelRequestCommand::SetLogLevelRequestCommand(UINT8 log_level) 
	: RequestCommand(CMD_LOG_SET_LEV_REQ)
{
}

ResetLogInfoRequestCommand::ResetLogInfoRequestCommand()
	: RequestCommand(CMD_LOG_RST_INF_REQ)
{}

GetLogInfoRequestCommand::GetLogInfoRequestCommand()
	: RequestCommand(CMD_LOG_GET_INF_REQ)
{}

ResponseCommand* GetLogInfoRequestCommand::CreateResponse()const{return new GetLogInfoResponseCommand;}
