#include "../../Shared/StdAfx.h"
#include "RequestCommand.h"
#include "ResponseCommand.h"
#include "HeftCmdIds.h"

const int ciTransactionDeclinedAmount = 1000;
const int ciUserCancelAmount = 2000;
const int ciSignRequestAmount = 3000;
const int ciRecoveredTransactionAmount = 9999;

ResponseCommand* RequestCommand::CreateResponse()const{return new FinanceResponseCommand(m_cmd);}

FinanceRequestCommand::FinanceRequestCommand(UINT32 type, const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id, const string& xml)
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
	
	if(fCheckCodeSize && currency_code.length() != currency_code_length)
		throw std::invalid_argument("invalid currency code");
	
	currency = code;
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
		result = amount == ciSignRequestAmount ? reinterpret_cast<ResponseCommand*>(new SignatureRequestCommand(currency, amount, GetType())) : new EventInfoResponseCommand(EFT_PP_STATUS_PIN_INPUT);
		break;
	case eConnect:
		result = amount == ciUserCancelAmount ? CreateResponseOnCancel() : reinterpret_cast<ResponseCommand*>(new ConnectRequestCommand(currency, amount, GetType()));
		break;
	}
	return result;
}

ResponseCommand* FinanceRequestCommand::CreateResponseOnCancel()const{return new FinanceResponseCommand(m_cmd, amount, EFT_PP_STATUS_USER_CANCELLED);}


StartOfDayRequestCommand::StartOfDayRequestCommand()
	: RequestCommand(CMD_FIN_STARTDAY_REQ)
{}

EndOfDayRequestCommand::EndOfDayRequestCommand()
	: RequestCommand(CMD_FIN_ENDDAY_REQ)
{}

FinanceInitRequestCommand::FinanceInitRequestCommand()
	: RequestCommand(CMD_FIN_INIT_REQ)
{}

HostResponseCommand::HostResponseCommand(UINT32 command, UINT32 aFin_cmd, const string& aCurrency, UINT32 aAmount, int aStatus) 
	: RequestCommand(command)
	, fin_cmd(aFin_cmd), currency(aCurrency), amount(aAmount), status(aStatus)
{
}

ResponseCommand* HostResponseCommand::CreateResponse()const{
	RequestCommand* result = 0;
	switch(m_cmd){
	case CMD_HOST_CONN_RSP:
		result = new SendRequestCommand(currency, amount, fin_cmd);
		break;
	case CMD_HOST_SEND_RSP:
		result = new ReceiveRequestCommand(currency, amount, fin_cmd);
		break;
	case CMD_HOST_RECV_RSP:
		result = new DisconnectRequestCommand(currency, amount, fin_cmd);
		break;
	case CMD_HOST_DISC_RSP:
			if(amount == ciTransactionDeclinedAmount){
				FinanceResponseCommand* pResponse = new FinanceResponseCommand(fin_cmd, amount, EFT_PP_STATUS_RECEIVING_ERROR);
				pResponse->SetFinancialStatus(EFT_FINANC_STATUS_TRANS_DECLINED);
				return pResponse;
			}
            else if(amount == ciRecoveredTransactionAmount) {
				return new FinanceResponseCommand(fin_cmd, currency, amount, EFT_FINANC_STATUS_TRANS_APPROVED, YES);
            } else {
                return new FinanceResponseCommand(fin_cmd, currency, amount, EFT_FINANC_STATUS_TRANS_APPROVED, NO);
            }
	case CMD_STAT_SIGN_RSP:
		if(status == EFT_PP_STATUS_SUCCESS)
			result = new ConnectRequestCommand(currency, amount, fin_cmd);
		else
			return new FinanceResponseCommand(fin_cmd, amount, EFT_PP_STATUS_INVALID_SIGNATURE);
	}
	return reinterpret_cast<ResponseCommand*>(result);
}

ConnectRequestCommand::ConnectRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aFin_cmd)
	: HostRequestCommand(CMD_HOST_CONN_REQ, aCurrency, aAmount, aFin_cmd)
{
}

SendRequestCommand::SendRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aFin_cmd)
	: HostRequestCommand(CMD_HOST_SEND_REQ, aCurrency, aAmount, aFin_cmd)
{
}

ReceiveRequestCommand::ReceiveRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aFin_cmd)
	: HostRequestCommand(CMD_HOST_RECV_REQ, aCurrency, aAmount, aFin_cmd)
{
}

DisconnectRequestCommand::DisconnectRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aFin_cmd)
	: HostRequestCommand(CMD_HOST_DISC_REQ, aCurrency, aAmount, aFin_cmd)
{
}

SignatureRequestCommand::SignatureRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aType) 
	: RequestCommand(CMD_STAT_SIGN_REQ), currency(aCurrency), amount(aAmount), type(aType)
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

/*DebugEnableRequestCommand::DebugEnableRequestCommand()
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

ResponseCommand* DebugInfoRequestCommand::CreateResponse()const{return new DebugInfoResponseCommand;}*/

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
