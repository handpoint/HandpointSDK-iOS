// #include "StdAfx.h"

#ifndef HEFT_SIMULATOR

#include "RequestCommand.h"
#include "BCDCoder.h"
#include "HeftCmdIds.h"
#include "api/CmdIds.h"
#include "debug.h"

#include "Exception.h"

#include <cstdint>


namespace {
    const int currency_code_length = 4;
    
    struct CurrencyCode{
        char name[4];
        char code[currency_code_length + 1];
    };
    
    CurrencyCode ISO4217CurrencyCodes[] = {
            "AED", "784" //United Arab Emirates dirham
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
    
    NSString* init_xml = @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"
                                  "<InitRequest>"
                                    "<ComBufSize>%d</ComBufSize>"
                                    "<SDKName>iOS</SDKName>"
                                    "<SDKVersion>v%@</SDKVersion>"
                                  "</InitRequest>";
}

RequestCommand::RequestCommand(int iCommandSize, std::uint32_t type)
    : data(ciMinSize + iCommandSize)
{
    RequestPayload* pRequest = GetPayload<RequestPayload>();
    pRequest->command = htonl(type);
    FormatLength<RequestPayload>(iCommandSize);
}

RequestCommand::RequestCommand(const void* payload, std::uint32_t payloadSize)
{
    const RequestPayload* pRequest = reinterpret_cast<const RequestPayload*>(payload);
    int length = ReadLength(pRequest);
    if ((payloadSize - 4 - 6) != length) {
        LOG(@"Invalid request command buffer detected");
        throw communication_exception();
    }
}

int RequestCommand::ReadLength(const RequestPayload* pRequest)
{
    std::uint32_t len_msb = 0;
    int dest_len = sizeof(len_msb) - 1;
    AtlHexDecode(reinterpret_cast<const char*>(pRequest->length),
                 sizeof(pRequest->length),
                 reinterpret_cast<std::uint8_t*>(&len_msb) + 1,
                 &dest_len);
	return ntohl(len_msb);
}


InitRequestCommand::InitRequestCommand(int bufferSize, NSString* version)
: RequestCommand(ciMinSize, CMD_INIT_REQ)
{
    InitPayload* payload = GetPayload<InitPayload>();
    
    // always add the date
    NSDateFormatter* df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyyMMddHHmmss"];
    NSString* curDate = [df stringFromDate:[NSDate date]];
    BCDCoder::Encode([curDate UTF8String], payload->data, ciMinSize);
    
    if (bufferSize > 0)
    {
        if (version == nil)
        {
            version = @"0.0";
        }
        
        // format the xml and then resize the databuffer
        NSString* xml_string = [NSString stringWithFormat:init_xml, bufferSize, version];
        const char* init_xml_utf8 = [xml_string UTF8String];
        const auto xml_utf8_len = strlen(init_xml_utf8);
        auto new_buffer_size = xml_utf8_len + data.size() + 4; // 4 for the xml size
        data.resize(new_buffer_size);
        payload = GetPayload<InitPayload>(); // reset the payload pointer after resize
        
        // set the parameter length again, now with the size of the xml
        // plus the size of the header
        FormatLength<RequestPayload>(xml_utf8_len + 11);
        
        // insert the xml and the size
        payload->xml_size = htonl(xml_utf8_len);
        memcpy(&payload->xml[0], init_xml_utf8, xml_utf8_len);
    }
}


IdleRequestCommand::IdleRequestCommand() : RequestCommand(ciMinSize, CMD_IDLE_REQ)
{
}


XMLCommandRequestCommand::XMLCommandRequestCommand(const std::string& xml)
    : RequestCommand((int)xml.size(), CMD_XCMD_REQ)
{
    XMLCommandPayload* pRequest = GetPayload<XMLCommandPayload>();
    memcpy(pRequest->xml_parameters, xml.c_str(), xml.size());
}

static bool isNumber(const std::string str)
{
    std::string::const_iterator it = str.begin();
    while (it != str.end() && isdigit(*it)) ++it;
    return !str.empty() && it == str.end();
}

FinanceRequestCommand::FinanceRequestCommand(std::uint32_t type,
                                             const std::string& currency_code,
                                             std::uint32_t trans_amount,
                                             std::uint8_t card_present,
                                             const std::string& trans_id,
                                             const std::string& xml)
    : RequestCommand(
    ciMinSize
    + (int)(xml.length() // this conditional so the "if( trans_id_length || xml_length )" statement below won't corrupt the heap
        ? (1 + 4 + xml.length() + trans_id.length())
        : (trans_id.length()
            ? (1 + trans_id.length())
            : 0
        )
    )
    , type)
{
    FinancePayload* pRequest;
    std::uint8_t* pData;
    int xml_length;
    int trans_id_length;
    const char* code = currency_code.c_str();

    if(!isNumber(code))
    {
	    bool fCheckCodeSize = true;
        for (CurrencyCode& cc : ISO4217CurrencyCodes)
        {
		    if(currency_code == cc.name)
            {
			    code = cc.code;
			    fCheckCodeSize = false;
			    break;
		    }
	    }

	    if(fCheckCodeSize && currency_code.length() != currency_code_length)
		    throw std::invalid_argument("invalid currency code");

    }
    pRequest = GetPayload<FinancePayload>();
    BCDCoder::Encode(code, pRequest->currency_code, sizeof(pRequest->currency_code));
    pRequest->trans_amount = htonl(trans_amount);
    pRequest->card_present = card_present;

    // optional fields
    trans_id_length = (int)trans_id.length();
    xml_length = (int)xml.length();

    if( trans_id_length || xml_length )
    {
        // trans id length MUST be present if either of these is true:
        //   trans_id is not empty
        //   xml is not empty
	    pRequest->trans_id_length = trans_id_length;
	    memcpy(pRequest->trans_id, trans_id.c_str(), trans_id_length);

	    if(xml_length > 0)
	    {
	        pData = &pRequest->trans_id[0] + trans_id_length;
        	
		    pData[0] = (std::uint8_t)(xml_length >> 24);
		    pData[1] = (std::uint8_t)(xml_length >> 16);
		    pData[2] = (std::uint8_t)(xml_length >> 8);
		    pData[3] = (std::uint8_t)(xml_length >> 0);
		    pData += sizeof(std::uint32_t);
		    memcpy(pData, xml.c_str(), xml_length);
	    }	
    }
}

StartOfDayRequestCommand::StartOfDayRequestCommand()
    : RequestCommand(0, CMD_FIN_STARTDAY_REQ)
{}

EndOfDayRequestCommand::EndOfDayRequestCommand()
    : RequestCommand(0, CMD_FIN_ENDDAY_REQ)
{}

FinanceInitRequestCommand::FinanceInitRequestCommand()
    : RequestCommand(0, CMD_FIN_INIT_REQ)
{}

HostRequestCommand::HostRequestCommand(const void* payload, std::uint32_t payloadSize)
    : RequestCommand(payload, payloadSize)
{}

HostRequestCommand* HostRequestCommand::Create(const void* payload, std::uint32_t payloadSize)
{
    const RequestPayload* pRequestPayload = reinterpret_cast<const RequestPayload*>(payload);
    switch(ntohl(pRequestPayload->command))
    {
    case CMD_HOST_CONN_REQ:
        return new ConnectRequestCommand(payload, payloadSize);
    case CMD_HOST_SEND_REQ:
        return new SendRequestCommand(payload, payloadSize);
    case CMD_HOST_RECV_REQ:
        return new ReceiveRequestCommand(payload, payloadSize);
    case CMD_HOST_DISC_REQ:
        return new DisconnectRequestCommand(payload, payloadSize);
    default:
        break;
    }
    LOG(@"Unknown host packet");
    throw communication_exception();
}

HostResponseCommand::HostResponseCommand(std::uint32_t command, int status, int cmd_size)
    : RequestCommand(ciMinSize + cmd_size, command)
{
    HostResponsePayload* pPayload = GetPayload<HostResponsePayload>();
    WriteStatus(status);
    memset(pPayload->length, '0', sizeof pPayload->length);
    FormatLength<HostResponsePayload>(cmd_size);
}

void HostResponseCommand::WriteStatus(std::uint16_t status)
{
    std::uint16_t status_msb = htons(status);
    HostResponsePayload* pPayload = GetPayload<HostResponsePayload>();
    int dest_len = sizeof(pPayload->status) + 1;
    AtlHexEncode(reinterpret_cast<std::uint8_t*>(&status_msb),
                 sizeof(status_msb),
                 reinterpret_cast<char*>(&pPayload->status),
                 &dest_len);
}

namespace {
    std::uint16_t copy_short_from_bytearray_in_hostorder(const std::uint8_t* byte_array)
    {
        std::uint16_t tmp_port;
        memcpy(&tmp_port, byte_array, 2);
        return ntohs(tmp_port);
    }
}

ConnectRequestCommand::ConnectRequestCommand(const void* payload, std::uint32_t payloadSize)
    : HostRequestCommand(payload, payloadSize)
{
    const ConnectPayload* pRequest = reinterpret_cast<const ConnectPayload*>(payload);
    
    remote_address = std::string(reinterpret_cast<const char*>(pRequest->remote_add),
                                 pRequest->remote_add_length
                                );
    const std::uint8_t* pWord = &pRequest->remote_add[pRequest->remote_add_length];
    
    port = copy_short_from_bytearray_in_hostorder(pWord);
	pWord += sizeof port;
    timeout = copy_short_from_bytearray_in_hostorder(pWord);
}

SendRequestCommand::SendRequestCommand(const void* payload, std::uint32_t payloadSize)
    : HostRequestCommand(payload, payloadSize)
{
    const SendPayload* pRequest = reinterpret_cast<const SendPayload*>(payload);
    timeout = htons(pRequest->timeout);
    data.resize(htons(pRequest->data_len));
    memcpy(&data[0], pRequest->data, data.size());
}

ReceiveRequestCommand::ReceiveRequestCommand(const void* payload, std::uint32_t payloadSize)
    : HostRequestCommand(payload, payloadSize)
{
    const ReceivePayload* pRequest = reinterpret_cast<const ReceivePayload*>(payload);
    timeout = htons(pRequest->timeout);
    data_len = htons(pRequest->data_len);
}

ReceiveResponseCommand::ReceiveResponseCommand(const std::vector<std::uint8_t>& payload)
    : HostResponseCommand(CMD_HOST_RECV_RSP, EFT_PP_STATUS_SUCCESS, ciMinSize + (int)payload.size())
{
    ReceiveResponsePayload* pPayload = GetPayload<ReceiveResponsePayload>();
    pPayload->data_len = htonl(payload.size());
    memcpy(pPayload->data, &payload[0], payload.size());
}

DisconnectRequestCommand::DisconnectRequestCommand(const void* payload, std::uint32_t payloadSize)
    : HostRequestCommand(payload, payloadSize)
{
}

SignatureRequestCommand::SignatureRequestCommand(const void* payload, std::uint32_t payloadSize)
    : RequestCommand(payload, payloadSize)
{
    const SignatureRequestPayload* pRequest = reinterpret_cast<const SignatureRequestPayload*>(payload);
    std::uint16_t receipt_length = htons(pRequest->receipt_length);
    receipt.assign(pRequest->receipt, receipt_length);
    const char* pXml = pRequest->receipt + receipt_length;
    // this should probably be ntohl() but I'll not touch this for now
    std::uint32_t xml_len = *pXml << 24 | *((unsigned char*)pXml + 1) << 16 | *((unsigned char*)pXml + 2) << 8 | *((unsigned char*)pXml + 3);

    pXml += sizeof xml_len;
    xml_details.assign(pXml, xml_len);
}

ChallengeRequestCommand::ChallengeRequestCommand(const void* payload, std::uint32_t payloadSize)
    : RequestCommand(payload, payloadSize)
{
    const ChallengeRequestPayload* pRequest = reinterpret_cast<const ChallengeRequestPayload*>(payload);
    std::uint16_t random_num_length = ntohs(pRequest->random_num_length);
    random_num.reserve(random_num_length);
    random_num.assign(pRequest->random_num, &pRequest->random_num[random_num_length]);
    const char* pXml = reinterpret_cast<const char*>(pRequest->random_num + random_num_length);
    // this should probably be ntohl() but I'll not touch this for now
    std::uint32_t xml_len = *pXml << 24 | *((unsigned char*)pXml + 1) << 16 | *((unsigned char*)pXml + 2) << 8 | *((unsigned char*)pXml + 3);
    
    pXml += sizeof xml_len;
    xml_details.assign(pXml, xml_len);
}

ChallengeResponseCommand::ChallengeResponseCommand(const std::vector<std::uint8_t>& mx, const std::vector<std::uint8_t>& zx)
    : HostResponseCommand(CMD_STAT_CHALENGE_RSP, EFT_PP_STATUS_SUCCESS, ciMinSize + (int)mx.size() + (int)zx.size())
{
    ChallengeResponsePayload* pPayload = GetPayload<ChallengeResponsePayload>();
    pPayload->mx_len = ntohs(mx.size());
    memcpy(pPayload->mx, &mx[0], mx.size());
    std::uint16_t* pZx = reinterpret_cast<std::uint16_t*>(&pPayload->mx[mx.size()]);
    *pZx++ = ntohs(zx.size());
    memcpy(pZx, &zx[0], zx.size());
}

/*DebugEnableRequestCommand::DebugEnableRequestCommand()
	: RequestCommand(0, CMD_DBG_ENABLE_REQ)
{}

DebugDisableRequestCommand::DebugDisableRequestCommand()
	: RequestCommand(0, CMD_DBG_DISABLE_REQ)
{}

DebugResetRequestCommand::DebugResetRequestCommand()
	: RequestCommand(0, CMD_DBG_RESET_REQ)
{}

DebugInfoRequestCommand::DebugInfoRequestCommand()
	: RequestCommand(0, CMD_DBG_INFO_REQ)
{}*/

SetLogLevelRequestCommand::SetLogLevelRequestCommand(std::uint8_t log_level)
    : RequestCommand(ciMinSize, CMD_LOG_SET_LEV_REQ)
{
    SetLogLevelPayload* pRequest = GetPayload<SetLogLevelPayload>();
    pRequest->log_level = log_level;
}

ResetLogInfoRequestCommand::ResetLogInfoRequestCommand()
    : RequestCommand(0, CMD_LOG_RST_INF_REQ)
{}

GetLogInfoRequestCommand::GetLogInfoRequestCommand()
    : RequestCommand(0, CMD_LOG_GET_INF_REQ)
{}

#endif
