
#ifdef HEFT_SIMULATOR

#include "RequestCommand.h"
#include "ResponseCommand.h"

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
       "AED", "0784" //United Arab Emirates dirham
        ,"AFN", "0971" //Afghani
        ,"ALL", "0008" //Lek
        ,"AMD", "0051" //Armenian dram
        ,"ANG", "0532" //Netherlands Antillean guilder
        ,"AOA", "0973" //Kwanza
        ,"ARS", "0032" //Argentine peso
        ,"AUD", "0036" //Australian dollar
        ,"AWG", "0533" //Aruban guilder
        ,"AZN", "0944" //Azerbaijanian manat
        ,"BAM", "0977" //Convertible marks
        ,"BBD", "0052" //Barbados dollar
        ,"BDT", "0050" //Bangladeshi taka
        ,"BGN", "0975" //Bulgarian lev
        ,"BHD", "0048" //Bahraini dinar
        ,"BIF", "0108" //Burundian franc
        ,"BMD", "0060" //Bermudian dollar
        ,"BND", "0096" //Brunei dollar
        ,"BOB", "0068" //Boliviano
        ,"BOV", "0984" //Bolivian Mvdol (funds code)
        ,"BRL", "0986" //Brazilian real
        ,"BSD", "0044" //Bahamian dollar
        ,"BTN", "0064" //Ngultrum
        ,"BWP", "0072" //Pula
        ,"BYR", "0974" //Belarusian ruble
        ,"BZD", "0084" //Belize dollar
        ,"CAD", "0124" //Canadian dollar
        ,"CDF", "0976" //Franc Congolais
        ,"CHF", "0756" //Swiss franc
        ,"CLP", "0152" //Chilean peso
        ,"CNY", "0156" //Chinese Yuan
        ,"COP", "0170" //Colombian peso
        ,"COU", "0970" //Unidad de Valor Real
        ,"CRC", "0188" //Costa Rican colon
        ,"CUC", "0931" //Cuban convertible peso
        ,"CUP", "0192" //Cuban peso
        ,"CVE", "0132" //Cape Verde escudo
        ,"CZK", "0203" //Czech Koruna
        ,"DJF", "0262" //Djibouti franc
        ,"DKK", "0208" //Danish krone
        ,"DOP", "0214" //Dominican peso
        ,"DZD", "0012" //Algerian dinar
        ,"EGP", "0818" //Egyptian pound
        ,"ERN", "0232" //Nakfa
        ,"ETB", "0230" //Ethiopian birr
        ,"EUR", "0978" //euro
        ,"FJD", "0242" //Fiji dollar
        ,"FKP", "0238" //Falkland Islands pound
        ,"GBP", "0826" //Pound sterling
        ,"GEL", "0981" //Lari
        ,"GHS", "0936" //Cedi
        ,"GIP", "0292" //Gibraltar pound
        ,"GMD", "0270" //Dalasi
        ,"GNF", "0324" //Guinea franc
        ,"GTQ", "0320" //Quetzal
        ,"GYD", "0328" //Guyana dollar
        ,"HKD", "0344" //Hong Kong dollar
        ,"HNL", "0340" //Lempira
        ,"HRK", "0191" //Croatian kuna
        ,"HTG", "0332" //Haiti gourde
        ,"HUF", "0348" //Forint
        ,"IDR", "0360" //Rupiah
        ,"ILS", "0376" //Israeli new sheqel
        ,"INR", "0356" //Indian rupee
        ,"IQD", "0368" //Iraqi dinar
        ,"IRR", "0364" //Iranian rial
        ,"ISK", "0352" //Iceland krona
        ,"JMD", "0388" //Jamaican dollar
        ,"JOD", "0400" //Jordanian dinar
        ,"JPY", "0392" //Japanese yen
        ,"KES", "0404" //Kenyan shilling
        ,"KGS", "0417" //Som
        ,"KHR", "0116" //Riel
        ,"KMF", "0174" //Comoro franc
        ,"KPW", "0408" //North Korean won
        ,"KRW", "0410" //South Korean won
        ,"KWD", "0414" //Kuwaiti dinar
        ,"KYD", "0136" //Cayman Islands dollar
        ,"KZT", "0398" //Tenge
        ,"LAK", "0418" //Kip
        ,"LBP", "0422" //Lebanese pound
        ,"LKR", "0144" //Sri Lanka rupee
        ,"LRD", "0430" //Liberian dollar
        ,"LSL", "0426" //Lesotho loti
        ,"LTL", "0440" //Lithuanian litas
        ,"LYD", "0434" //Libyan dinar
        ,"MAD", "0504" //Moroccan dirham
        ,"MDL", "0498" //Moldovan leu
        ,"MGA", "0969" //Malagasy ariary
        ,"MKD", "0807" //Denar
        ,"MMK", "0104" //Kyat
        ,"MNT", "0496" //Tughrik
        ,"MOP", "0446" //Pataca
        ,"MRO", "0478" //Mauritanian ouguiya
        ,"MUR", "0480" //Mauritius rupee
        ,"MVR", "0462" //Rufiyaa
        ,"MWK", "0454" //Kwacha
        ,"MXN", "0484" //Mexican peso
        ,"MXV", "0979" //Mexican Unidad de Inversion
        ,"MYR", "0458" //Malaysian ringgit
        ,"MZN", "0943" //Metical
        ,"NAD", "0516" //Namibian dollar
        ,"NGN", "0566" //Naira
        ,"NIO", "0558" //Cordoba oro
        ,"NOK", "0578" //Norwegian krone
        ,"NPR", "0524" //Nepalese rupee
        ,"NZD", "0554" //New Zealand dollar
        ,"OMR", "0512" //Rial Omani
        ,"PAB", "0590" //Balboa
        ,"PEN", "0604" //Nuevo sol
        ,"PGK", "0598" //Kina
        ,"PHP", "0608" //Philippine peso
        ,"PKR", "0586" //Pakistan rupee
        ,"PLN", "0985" //Z?oty
        ,"PYG", "0600" //Guarani
        ,"QAR", "0634" //Qatari rial
        ,"RON", "0946" //Romanian new leu
        ,"RSD", "0941" //Serbian dinar
        ,"RUB", "0643" //Russian rouble
        ,"RWF", "0646" //Rwanda franc
        ,"SAR", "0682" //Saudi riyal
        ,"SBD", "0090" //Solomon Islands dollar
        ,"SCR", "0690" //Seychelles rupee
        ,"SDG", "0938" //Sudanese pound
        ,"SEK", "0752" //Swedish krona/kronor
        ,"SGD", "0702" //Singapore dollar
        ,"SHP", "0654" //Saint Helena pound
        ,"SLL", "0694" //Leone
        ,"SOS", "0706" //Somali shilling
        ,"SRD", "0968" //Surinam dollar
        ,"SSP", "0728" //South Sudanese pound
        ,"STD", "0678" //Dobra
        ,"SYP", "0760" //Syrian pound
        ,"SZL", "0748" //Lilangeni
        ,"THB", "0764" //Baht
        ,"TJS", "0972" //Somoni
        ,"TMT", "0934" //Manat
        ,"TND", "0788" //Tunisian dinar
        ,"TOP", "0776" //Pa'anga
        ,"TRY", "0949" //Turkish lira
        ,"TTD", "0780" //Trinidad and Tobago dollar
        ,"TWD", "0901" //New Taiwan dollar
        ,"TZS", "0834" //Tanzanian shilling
        ,"UAH", "0980" //Hryvnia
        ,"UGX", "0800" //Uganda shilling
        ,"USD", "0840" //US dollar
        ,"UZS", "0860" //Uzbekistan som
        ,"VEF", "0937" //Venezuelan bolivar fuerte
        ,"VND", "0704" //Vietnamese Dong
        ,"VUV", "0548" //Vatu
        ,"WST", "0882" //Samoan tala
        ,"XAF", "0950" //CFA franc BEAC
        ,"XCD", "0951" //East Caribbean dollar
        ,"XOF", "0952" //CFA Franc BCEAO
        ,"XPF", "0953" //CFP franc
        ,"YER", "0886" //Yemeni rial
        ,"ZAR", "0710" //South African rand
        ,"ZMW", "0967" //Kwacha
        ,"ZWL", "0932" //Zimbabwe dollar
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
    
    if(GetType() != EFT_PACKET_RECOVERED_TXN_RESULT)
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
            case EFT_PACKET_SALE:
            case EFT_PACKET_REFUND:
                simulatorState.inc_trans_id();
                result = new EventInfoResponseCommand(EFT_PP_STATUS_WAITING_CARD);
                break;
            case EFT_PACKET_SALE_VOID:
            case EFT_PACKET_REFUND_VOID:
                simulatorState.inc_trans_id();
                // result = new FinanceResponseCommand(GetType(), currency, amount, !(amount % 2) ? EFT_FINANC_STATUS_TRANS_APPROVED : EFT_FINANC_STATUS_TRANS_DECLINED, NO);
                result = reinterpret_cast<ResponseCommand*>(new ConnectRequestCommand(currency, amount, GetType()));
                break;
            case EFT_PACKET_START_DAY:
            case EFT_PACKET_END_DAY:
            case EFT_PACKET_HOST_INIT:
                result = new FinanceResponseCommand(GetType(), "0", 0, EFT_FINANC_STATUS_TRANS_PROCESSED, NO);
                break;
            case EFT_PACKET_RECOVERED_TXN_RESULT:
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

TokenizeCardRequestCommand::TokenizeCardRequestCommand (const std::string &xml)
: FinanceRequestCommand(EFT_PACKET_HOST_INIT, "0", 0, 0, "", "") //TODO fix this
{
}

ResponseCommand* FinanceRequestCommand::CreateResponseOnCancel()const
{
    return new FinanceResponseCommand(m_cmd, currency, amount, EFT_PP_STATUS_USER_CANCELLED, NO);
}

StartOfDayRequestCommand::StartOfDayRequestCommand()
	: FinanceRequestCommand(EFT_PACKET_START_DAY, "0", 0, 0, "", "")
{
}

EndOfDayRequestCommand::EndOfDayRequestCommand()
    : FinanceRequestCommand(EFT_PACKET_END_DAY, "0", 0, 0, "", "")
{
}

FinanceInitRequestCommand::FinanceInitRequestCommand()
    : FinanceRequestCommand(EFT_PACKET_HOST_INIT, "0", 0, 0, "", "")
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
	case EFT_PACKET_HOST_CONNECT_RESP:
		result = new SendRequestCommand(currency, amount, fin_cmd);
		break;
	case EFT_PACKET_HOST_SEND_RESP:
		result = new ReceiveRequestCommand(currency, amount, fin_cmd);
		break;
	case EFT_PACKET_HOST_RECEIVE_RESP:
		result = new DisconnectRequestCommand(currency, amount, fin_cmd);
		break;
	case EFT_PACKET_HOST_DISCONNECT_RESP:
            simulatorState.setAsAuthorized();
            simulatorState.setOrgTransUID(simulatorState.getTransUID());
            simulatorState.setTransUID([[[[NSUUID UUID] UUIDString] lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
            
            if((fin_cmd != EFT_PACKET_SALE_VOID) && (fin_cmd != EFT_PACKET_REFUND_VOID)) {
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
                        [NSThread sleepForTimeInterval:120];
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
	case EFT_PACKET_SIGNATURE_REQ_RESP:
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
	: HostRequestCommand(EFT_PACKET_HOST_CONNECT, aCurrency, aAmount, aFin_cmd)
{
}

SendRequestCommand::SendRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd)
	: HostRequestCommand(EFT_PACKET_HOST_SEND, aCurrency, aAmount, aFin_cmd)
{
}

ReceiveRequestCommand::ReceiveRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd)
	: HostRequestCommand(EFT_PACKET_HOST_RECEIVE, aCurrency, aAmount, aFin_cmd)
{
}

DisconnectRequestCommand::DisconnectRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd)
	: HostRequestCommand(EFT_PACKET_HOST_DISCONNECT, aCurrency, aAmount, aFin_cmd)
{
}

SignatureRequestCommand::SignatureRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aType)
	: RequestCommand(EFT_PACKET_SIGNATURE_REQ), currency(aCurrency), amount(aAmount), type(aType)
{
    NSMutableDictionary* xmlDict = [[NSMutableDictionary alloc] init];
    
    // Basic (always) tags
    xmlDict[@"timeout"]     = @"90";
    
    xml_details = ConvertDictionaryToXML(xmlDict, @"SignatureRequiredRequest");
    
    simulatorState.setAsAuthorized();
    
    receipt = simulatorState.generateReceipt(true);
}

SetLogLevelRequestCommand::SetLogLevelRequestCommand(uint8_t log_level) 
	: RequestCommand(EFT_PACKET_LOG_SET_LEVEL)
{
}

ResetLogInfoRequestCommand::ResetLogInfoRequestCommand()
	: RequestCommand(EFT_PACKET_LOG_RESET)
{}

GetLogInfoRequestCommand::GetLogInfoRequestCommand()
	: RequestCommand(EFT_PACKET_LOG_GETINFO)
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
    : RequestCommand(EFT_PACKET_COMMAND)
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
