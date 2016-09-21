
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
        "AED", "784" //United Arab Emirates dirham
        ,"AFN", "971" //Afghani
        ,"ALL", "8" //Lek
        ,"AMD", "51" //Armenian dram
        ,"ANG", "532" //Netherlands Antillean guilder
        ,"AOA", "973" //Kwanza
        ,"ARS", "32" //Argentine peso
        ,"AUD", "36" //Australian dollar
        ,"AWG", "533" //Aruban guilder
        ,"AZN", "944" //Azerbaijanian manat
        ,"BAM", "977" //Convertible marks
        ,"BBD", "52" //Barbados dollar
        ,"BDT", "50" //Bangladeshi taka
        ,"BGN", "975" //Bulgarian lev
        ,"BHD", "48" //Bahraini dinar
        ,"BIF", "108" //Burundian franc
        ,"BMD", "60" //Bermudian dollar
        ,"BND", "96" //Brunei dollar
        ,"BOB", "68" //Boliviano
        ,"BOV", "984" //Bolivian Mvdol (funds code)
        ,"BRL", "986" //Brazilian real
        ,"BSD", "44" //Bahamian dollar
        ,"BTN", "64" //Ngultrum
        ,"BWP", "72" //Pula
        ,"BYR", "974" //Belarusian ruble
        ,"BZD", "84" //Belize dollar
        ,"CAD", "124" //Canadian dollar
        ,"CDF", "976" //Franc Congolais
        ,"CHF", "756" //Swiss franc
        ,"CLP", "152" //Chilean peso
        ,"CNY", "156" //Chinese Yuan
        ,"COP", "170" //Colombian peso
        ,"COU", "970" //Unidad de Valor Real
        ,"CRC", "188" //Costa Rican colon
        ,"CUC", "931" //Cuban convertible peso
        ,"CUP", "192" //Cuban peso
        ,"CVE", "132" //Cape Verde escudo
        ,"CZK", "203" //Czech Koruna
        ,"DJF", "262" //Djibouti franc
        ,"DKK", "208" //Danish krone
        ,"DOP", "214" //Dominican peso
        ,"DZD", "12" //Algerian dinar
        ,"EGP", "818" //Egyptian pound
        ,"ERN", "232" //Nakfa
        ,"ETB", "230" //Ethiopian birr
        ,"EUR", "978" //euro
        ,"FJD", "242" //Fiji dollar
        ,"FKP", "238" //Falkland Islands pound
        ,"GBP", "826" //Pound sterling
        ,"GEL", "981" //Lari
        ,"GHS", "936" //Cedi
        ,"GIP", "292" //Gibraltar pound
        ,"GMD", "270" //Dalasi
        ,"GNF", "324" //Guinea franc
        ,"GTQ", "320" //Quetzal
        ,"GYD", "328" //Guyana dollar
        ,"HKD", "344" //Hong Kong dollar
        ,"HNL", "340" //Lempira
        ,"HRK", "191" //Croatian kuna
        ,"HTG", "332" //Haiti gourde
        ,"HUF", "348" //Forint
        ,"IDR", "360" //Rupiah
        ,"ILS", "376" //Israeli new sheqel
        ,"INR", "356" //Indian rupee
        ,"IQD", "368" //Iraqi dinar
        ,"IRR", "364" //Iranian rial
        ,"ISK", "352" //Iceland krona
        ,"JMD", "388" //Jamaican dollar
        ,"JOD", "400" //Jordanian dinar
        ,"JPY", "392" //Japanese yen
        ,"KES", "404" //Kenyan shilling
        ,"KGS", "417" //Som
        ,"KHR", "116" //Riel
        ,"KMF", "174" //Comoro franc
        ,"KPW", "408" //North Korean won
        ,"KRW", "410" //South Korean won
        ,"KWD", "414" //Kuwaiti dinar
        ,"KYD", "136" //Cayman Islands dollar
        ,"KZT", "398" //Tenge
        ,"LAK", "418" //Kip
        ,"LBP", "422" //Lebanese pound
        ,"LKR", "144" //Sri Lanka rupee
        ,"LRD", "430" //Liberian dollar
        ,"LSL", "426" //Lesotho loti
        ,"LTL", "440" //Lithuanian litas
        ,"LYD", "434" //Libyan dinar
        ,"MAD", "504" //Moroccan dirham
        ,"MDL", "498" //Moldovan leu
        ,"MGA", "969" //Malagasy ariary
        ,"MKD", "807" //Denar
        ,"MMK", "104" //Kyat
        ,"MNT", "496" //Tughrik
        ,"MOP", "446" //Pataca
        ,"MRO", "478" //Mauritanian ouguiya
        ,"MUR", "480" //Mauritius rupee
        ,"MVR", "462" //Rufiyaa
        ,"MWK", "454" //Kwacha
        ,"MXN", "484" //Mexican peso
        ,"MXV", "979" //Mexican Unidad de Inversion
        ,"MYR", "458" //Malaysian ringgit
        ,"MZN", "943" //Metical
        ,"NAD", "516" //Namibian dollar
        ,"NGN", "566" //Naira
        ,"NIO", "558" //Cordoba oro
        ,"NOK", "578" //Norwegian krone
        ,"NPR", "524" //Nepalese rupee
        ,"NZD", "554" //New Zealand dollar
        ,"OMR", "512" //Rial Omani
        ,"PAB", "590" //Balboa
        ,"PEN", "604" //Nuevo sol
        ,"PGK", "598" //Kina
        ,"PHP", "608" //Philippine peso
        ,"PKR", "586" //Pakistan rupee
        ,"PLN", "985" //Z?oty
        ,"PYG", "600" //Guarani
        ,"QAR", "634" //Qatari rial
        ,"RON", "946" //Romanian new leu
        ,"RSD", "941" //Serbian dinar
        ,"RUB", "643" //Russian rouble
        ,"RWF", "646" //Rwanda franc
        ,"SAR", "682" //Saudi riyal
        ,"SBD", "90" //Solomon Islands dollar
        ,"SCR", "690" //Seychelles rupee
        ,"SDG", "938" //Sudanese pound
        ,"SEK", "752" //Swedish krona/kronor
        ,"SGD", "702" //Singapore dollar
        ,"SHP", "654" //Saint Helena pound
        ,"SLL", "694" //Leone
        ,"SOS", "706" //Somali shilling
        ,"SRD", "968" //Surinam dollar
        ,"SSP", "728" //South Sudanese pound
        ,"STD", "678" //Dobra
        ,"SYP", "760" //Syrian pound
        ,"SZL", "748" //Lilangeni
        ,"THB", "764" //Baht
        ,"TJS", "972" //Somoni
        ,"TMT", "934" //Manat
        ,"TND", "788" //Tunisian dinar
        ,"TOP", "776" //Pa'anga
        ,"TRY", "949" //Turkish lira
        ,"TTD", "780" //Trinidad and Tobago dollar
        ,"TWD", "901" //New Taiwan dollar
        ,"TZS", "834" //Tanzanian shilling
        ,"UAH", "980" //Hryvnia
        ,"UGX", "800" //Uganda shilling
        ,"USD", "840" //US dollar
        ,"UZS", "860" //Uzbekistan som
        ,"VEF", "937" //Venezuelan bolivar fuerte
        ,"VND", "704" //Vietnamese Dong
        ,"VUV", "548" //Vatu
        ,"WST", "882" //Samoan tala
        ,"XAF", "950" //CFA franc BEAC
        ,"XCD", "951" //East Caribbean dollar
        ,"XOF", "952" //CFA Franc BCEAO
        ,"XPF", "953" //CFP franc
        ,"YER", "886" //Yemeni rial
        ,"ZAR", "710" //South African rand
        ,"ZMW", "967" //Kwacha
        ,"ZWL", "932" //Zimbabwe dollar
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