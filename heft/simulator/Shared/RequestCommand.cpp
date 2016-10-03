
#ifdef HEFT_SIMULATOR

#include "RequestCommand.h"
#include "ResponseCommand.h"
#include "HeftCmdIds.h"

#include "ResponseParser.h"
#include "Exception.h"

#include <cstdint>

using std::uint32_t;
using std::uint8_t;

const int ciTransactionDeclinedAmount = 1000;
const int ciUserCancelAmount          = 2000;
const int ciSignRequestAmount         = 3000;

const int ciExceptionLimitLower       = 8000;

const int ciExceptionTimeoutLowerLim  = 8000;
const int ciExceptionTimeoutUpperLim  = 8099;

const int ciExceptionTimeout1         = 9001;
const int ciExceptionTimeout2         = 9002;
const int ciExceptionTimeout4         = 9003;
const int ciExceptionCommunication    = 9004;
const int ciExceptionConnectionBroken = 9005;

const int ciExceptionLimitUpper       = 9999;

SimulatorState simulatorState;

ResponseCommand* RequestCommand::CreateResponse() const
{
    return new ResponseCommand(m_cmd);
}

ResponseCommand* RequestCommand::CreateResponseOnCancel() const
{
    return new ResponseCommand(m_cmd, EFT_PP_STATUS_USER_CANCELLED);
}

static bool isNumber(const string& str)
{
    string::const_iterator it = str.begin();
    while (it != str.end() && isdigit(*it)) ++it;
    return !str.empty() && it == str.end();
}


namespace {
    const int currency_code_length = 4;
    
    struct CurrencyCode{
        char name[4];
        char code[currency_code_length + 1];
    };
    
    
    CurrencyCode ISO4217CurrencyCodes[] = {
        "USD", "840"
        , "EUR", "978"
        , "GBP", "826"
        , "ISK", "352"
        , "ZAR", "710"
    };
}


FinanceRequestCommand::FinanceRequestCommand(uint32_t type, const string& currency_code, uint32_t trans_amount, uint8_t card_present, const string& trans_id, const string& xml)
	: RequestCommand(type), state(eWaitingCard), amount(trans_amount)
{

    
    const char* code = currency_code.c_str();
    string abbr;
    
    if(!isNumber(code))
    {
        bool fCheckCodeSize = true;
        for (CurrencyCode& cc : ISO4217CurrencyCodes)
        {
            if(!currency_code.compare(cc.name))
            {
                code = cc.code;
                fCheckCodeSize = false;
                break;
            }
        }
        
        if(fCheckCodeSize && currency_code.length() != currency_code_length)
            throw std::invalid_argument("invalid currency code");
        
        

    }
    else
    {
        abbr = currency_code;

        for (CurrencyCode& cc : ISO4217CurrencyCodes)
        {
            if(!currency_code.compare(cc.name))
            {
                abbr = cc.code;
                break;
            }
        }
        
        if(!abbr.length()){
            abbr = "???";
        }
    }

    currency = code;
    
    if(GetType() != CMD_FIN_RCVRD_TXN_RSLT)
    {
        simulatorState.clearException();
        
        simulatorState.setAmount(amount);
        simulatorState.setType(type);
        simulatorState.setCurrency(currency);
        simulatorState.setCurrencyAbbreviation(abbr);
        simulatorState.setAsDeclined();
        simulatorState.setTransUID(trans_id);
        simulatorState.setUsingIcc();
    }
}

ResponseCommand* FinanceRequestCommand::CreateResponse() const
{
	ResponseCommand* result = 0;
	switch(state++){
	case eWaitingCard:
        switch (GetType()) {
            default:
            case CMD_FIN_SALE_REQ:
            case CMD_FIN_REFUND_REQ:
                simulatorState.inc_trans_id();
                result = new EventInfoResponseCommand(EFT_PP_STATUS_WAITING_CARD);
                break;
            case CMD_FIN_SALEV_REQ:
            case CMD_FIN_REFUNDV_REQ:
                simulatorState.inc_trans_id();
                // result = new FinanceResponseCommand(GetType(), currency, amount, !(amount % 2) ? EFT_FINANC_STATUS_TRANS_APPROVED : EFT_FINANC_STATUS_TRANS_DECLINED, NO);
                result = reinterpret_cast<ResponseCommand*>(new ConnectRequestCommand(currency, amount, GetType()));
                break;
            case CMD_FIN_STARTDAY_REQ:
            case CMD_FIN_ENDDAY_REQ:
            case CMD_FIN_INIT_REQ:
                result = new FinanceResponseCommand(GetType(), "0", 0, EFT_FINANC_STATUS_TRANS_PROCESSED, NO);
                break;
            case CMD_FIN_RCVRD_TXN_RSLT:
                if(simulatorState.isInException()) {
                    result = new FinanceResponseCommand(GetType(), simulatorState.getCurrency(), simulatorState.getAmount(), simulatorState.isAuthorized() ? EFT_FINANC_STATUS_TRANS_APPROVED : EFT_FINANC_STATUS_TRANS_DECLINED, YES);
                } else {
                    result = new FinanceResponseCommand(GetType(), "0", 0, EFT_FINANC_STATUS_TRANS_NOT_PROCESSED, YES);
                }
                break;
        }
		break;
	case eCardInserted:
		result = new EventInfoResponseCommand(EFT_PP_STATUS_CARD_INSERTED);
		break;
	case eAppSelect:
		result = new EventInfoResponseCommand(EFT_PP_STATUS_APPLICATION_SELECTION);
		break;
	case ePinInput:
        if(amount != ciSignRequestAmount)
        {
            result = new EventInfoResponseCommand(EFT_PP_STATUS_PIN_INPUT, false);
            break;
        } // else skip to next state
        state = eConnect;
        // fall through
	case eConnect:
		result = amount == ciUserCancelAmount ? CreateResponseOnCancel() : reinterpret_cast<ResponseCommand*>(new ConnectRequestCommand(currency, amount, GetType()));
		break;
	}
	return result;
}

ResponseCommand* FinanceRequestCommand::CreateResponseOnCancel()const
{
    return new FinanceResponseCommand(m_cmd, currency, amount, EFT_PP_STATUS_USER_CANCELLED, NO);
}


StartOfDayRequestCommand::StartOfDayRequestCommand()
	: FinanceRequestCommand(CMD_FIN_STARTDAY_REQ, "0", 0, 0, "", "")
{
}

EndOfDayRequestCommand::EndOfDayRequestCommand()
    : FinanceRequestCommand(CMD_FIN_ENDDAY_REQ, "0", 0, 0, "", "")
{
}

FinanceInitRequestCommand::FinanceInitRequestCommand()
    : FinanceRequestCommand(CMD_FIN_INIT_REQ, "0", 0, 0, "", "")
{
}

HostResponseCommand::HostResponseCommand(uint32_t command, uint32_t aFin_cmd, const string& aCurrency, uint32_t aAmount, int aStatus) 
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
            simulatorState.setAsAuthorized();
            simulatorState.setOrgTransUID(simulatorState.getTransUID());
            simulatorState.setTransUID([[[[NSUUID UUID] UUIDString] lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
            
            if((fin_cmd != CMD_FIN_SALEV_REQ) && (fin_cmd != CMD_FIN_REFUNDV_REQ)) {
                if(amount == ciSignRequestAmount) {
                    simulatorState.setUsingMsr();
                    result = new SignatureRequestCommand(currency, amount, fin_cmd);
                }
                else if(amount == ciTransactionDeclinedAmount){
                    simulatorState.setAsDeclined();
                    FinanceResponseCommand* pResponse = new FinanceResponseCommand(fin_cmd, currency, amount, EFT_PP_STATUS_RECEIVING_ERROR, NO);
                    pResponse->SetFinancialStatus(EFT_FINANC_STATUS_TRANS_DECLINED);
                    return pResponse;
                }
                else if((amount >= ciExceptionLimitLower) && (amount <= ciExceptionLimitUpper)) {
                    simulatorState.flagException();
                    if((amount >= ciExceptionTimeoutLowerLim) && (amount <= ciExceptionTimeoutUpperLim)) {
                        NSTimeInterval timeoutDelay = amount - ciExceptionTimeoutLowerLim;
                        [NSThread sleepForTimeInterval:timeoutDelay];
                        throw timeout2_exception();
                    }
                    else if(amount == ciExceptionTimeout1) {
                        [NSThread sleepForTimeInterval:20];
                        throw timeout1_exception();
                    }
                    else if(amount == ciExceptionTimeout2) {
                        [NSThread sleepForTimeInterval:15];
                        throw timeout2_exception();
                    }
                    else if(amount == ciExceptionTimeout4) {
                        [NSThread sleepForTimeInterval:45];
                        throw timeout4_exception();
                    }
                    else if(amount == ciExceptionCommunication) {
                        [NSThread sleepForTimeInterval:1];
                        throw communication_exception();
                    }
                    else if(amount == ciExceptionConnectionBroken) {
                        [NSThread sleepForTimeInterval:1];
                        throw connection_broken_exception();
                    }
                    
                    // if we get here the user used an amount that has not yet been defined for exceptions, but is in our range, in that case we will just handle it as a communication exception
                    
                    simulatorState.setAsDeclined(); // we will also make it into a declined transaction
                    
                    [NSThread sleepForTimeInterval:1];
                    throw communication_exception();
                }
            }
            return new FinanceResponseCommand(fin_cmd, currency, amount, EFT_FINANC_STATUS_TRANS_APPROVED);
            break;
	case CMD_STAT_SIGN_RSP:
        if(status == EFT_PP_STATUS_SUCCESS){
            simulatorState.setAsAuthorized();
        } else {
            simulatorState.setAsDeclined();
        }
        return new FinanceResponseCommand(fin_cmd, currency, amount, status, NO);
	}
	return reinterpret_cast<ResponseCommand*>(result);
}

ConnectRequestCommand::ConnectRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd)
	: HostRequestCommand(CMD_HOST_CONN_REQ, aCurrency, aAmount, aFin_cmd)
{
}

SendRequestCommand::SendRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd)
	: HostRequestCommand(CMD_HOST_SEND_REQ, aCurrency, aAmount, aFin_cmd)
{
}

ReceiveRequestCommand::ReceiveRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd)
	: HostRequestCommand(CMD_HOST_RECV_REQ, aCurrency, aAmount, aFin_cmd)
{
}

DisconnectRequestCommand::DisconnectRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd)
	: HostRequestCommand(CMD_HOST_DISC_REQ, aCurrency, aAmount, aFin_cmd)
{
}

SignatureRequestCommand::SignatureRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aType)
	: RequestCommand(CMD_STAT_SIGN_REQ), currency(aCurrency), amount(aAmount), type(aType)
{
    NSMutableDictionary* xmlDict = [[NSMutableDictionary alloc] init];
    
    // Basic (always) tags
    xmlDict[@"timeout"]     = @"90";
    
    xml_details = ConvertDictionaryToXML(xmlDict, @"SignatureRequiredRequest");
    
    simulatorState.setAsAuthorized();
    
    receipt = simulatorState.generateReceipt(true);
}

SetLogLevelRequestCommand::SetLogLevelRequestCommand(uint8_t log_level) 
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

NSDictionary* getValuesFromXml(NSString* xml, NSString* path){
    NSXMLParser* xmlParser = [[NSXMLParser alloc] initWithData:[[NSData alloc] initWithBytesNoCopy:(void*)[xml UTF8String] length:[xml length] freeWhenDone:NO]];
    ResponseParser* parser = [[ResponseParser alloc] initWithPath:path];
    xmlParser.delegate = parser;

    [xmlParser parse];

    return parser.result;
}

XMLCommandRequestCommand::XMLCommandRequestCommand(const string& xml)
    : RequestCommand(CMD_XCMD_REQ)
    , xml_data(xml)
{
}

ResponseCommand* XMLCommandRequestCommand::CreateResponse()const{
    NSString* xmlArg = [NSString stringWithCString:xml_data.c_str()
                                          encoding:[NSString defaultCStringEncoding]];
    NSDictionary* xmlDict = getValuesFromXml(xmlArg, @"enableScanner");
    if (xmlDict) {
        NSString* buf = [NSString stringWithFormat:@"<enableScannerResponse>"
                         "<StatusMessage>Success</StatusMessage>"
                         "<SerialNumber>000123400123</SerialNumber>"
                         "<BatteryStatus>57%%</BatteryStatus>"
                         "<BatterymV>4300</BatterymV>"
                         "<BatteryCharging>true</BatteryCharging>"
                         "<ExternalPower>true</ExternalPower>"
                         "</enableScannerResponse>"
                         ];
        string xml = [buf cStringUsingEncoding:NSUTF8StringEncoding];
        
        return new XMLCommandResponseCommand(EFT_PP_STATUS_SUCCESS, xml);
    }
    
    return new XMLCommandResponseCommand(EFT_PP_STATUS_SUCCESS, nil);
}

ResponseCommand* XMLCommandRequestCommand::CreateResponseOnCancel()const{
    NSString* xmlArg = [NSString stringWithCString:xml_data.c_str()
                                          encoding:[NSString defaultCStringEncoding]];
    NSDictionary* xmlDict = getValuesFromXml(xmlArg, @"enableScanner");
    if (xmlDict) {
        NSString* buf = [NSString stringWithFormat:@"<enableScannerResponse>"
                         "<StatusMessage>Success</StatusMessage>"
                         "<SerialNumber>000123400123</SerialNumber>"
                         "<BatteryStatus>57%%</BatteryStatus>"
                         "<BatterymV>4300</BatterymV>"
                         "<BatteryCharging>true</BatteryCharging>"
                         "<ExternalPower>true</ExternalPower>"
                         "</enableScannerResponse>"
                         ];
        string xml = [buf cStringUsingEncoding:NSUTF8StringEncoding];
        
        return new XMLCommandResponseCommand(EFT_PP_STATUS_POS_CANCELLED, xml);
    }
    
    return new XMLCommandResponseCommand(EFT_PP_STATUS_POS_CANCELLED, nil);
}

#endif