#include "StdAfx.h"

#if !HEFT_SIMULATOR

#include "RequestCommand.h"
#include "BCDCoder.h"
#include "HeftCmdIds.h"
#include "api/CmdIds.h"

RequestCommand::RequestCommand(int iCommandSize, UINT32 type) : data(ciMinSize + iCommandSize){
	RequestPayload* pRequest = GetPayload<RequestPayload>();
	pRequest->command = htonl(type);
	FormatLength<RequestPayload>(iCommandSize);
}

RequestCommand::RequestCommand(const void* payload, UINT32 payloadSize){
    const RequestPayload* pRequest = reinterpret_cast<const RequestPayload*>(payload);
    int length = ReadLength(pRequest);
    if ((payloadSize - 4 - 6) != length) {
        LOG(_T("Invalid request command buffer detected"));
        throw communication_exception();
    }
}

int RequestCommand::ReadLength(const RequestPayload* pRequest){
	UINT32 len_msb = 0;
	int dest_len = sizeof(len_msb) - 1;
	AtlHexDecode(reinterpret_cast<LPCSTR>(pRequest->length), sizeof(pRequest->length), reinterpret_cast<UINT8*>(&len_msb) + 1, &dest_len);
	return ntohl(len_msb);
}

InitRequestCommand::InitRequestCommand() : RequestCommand(ciMinSize, CMD_INIT_REQ){
	/*USES_CONVERSION;
	string date;
	char buf[ciMinSize * 2 + 1];
	__time64_t aclock;
	_time64(&aclock);
	tm time;
	_localtime64_s(&time, &aclock);*/
	//strftime(buf, sizeof buf, "%Y%m%d%H%M%S", &time);
	NSDateFormatter* df = [NSDateFormatter new];
	[df setDateFormat:@"yyyyMMddHHmmss"];
	NSString* curDate = [df stringFromDate:[NSDate new]];
	ATLASSERT([curDate length] == ciMinSize * 2);
	BCDCoder::Encode([curDate UTF8String], GetPayload<InitPayload>()->data, ciMinSize);
}

IdleRequestCommand::IdleRequestCommand() : RequestCommand(ciMinSize, CMD_IDLE_REQ)
{}

/*StartParamRequestCommand::StartParamRequestCommand(UINT16 total_blocks, UINT8 update_type) : RequestCommand(ciMinSize, CMD_START_PARAM_REQ){
	StartParamPayload* pRequest = GetPayload<StartParamPayload>();
	pRequest->total_blocks = htons(total_blocks);
	pRequest->update_type = update_type;
	AddCRC();
}*/

XMLCommandRequestCommand::XMLCommandRequestCommand(const string& xml) 
	: RequestCommand((int)xml.size(), CMD_XCMD_REQ)
{
	XMLCommandPayload* pRequest = GetPayload<XMLCommandPayload>();
	memcpy(pRequest->xml_parameters, xml.c_str(), xml.size());
}

static bool isNumber(const string& str)
{
    string::const_iterator it = str.begin();
    while (it != str.end() && isdigit(*it)) ++it;
    return !str.empty() && it == str.end();
}

FinanceRequestCommand::FinanceRequestCommand(UINT32 type, const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id, const string& xml) 
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
	UINT8* pData;
	int xml_length;
	int trans_id_length;
	const char* code = currency_code.c_str();

	if(!isNumber(code)){

	    const int currency_code_length = 4;

	    static const struct CurrencyCode{
		    char name[4];
		    char code[currency_code_length + 1];
	    } ISO4217CurrencyCodes[] = {
		      "USD", "0840"
		    , "EUR", "0978"
		    , "GBP", "0826"
		    , "ISK", "0352"
            , "ZAR", "0710"
	    };

	    bool fCheckCodeSize = true;
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
        	
		    pData[0] = (UINT8)(xml_length >> 24);
		    pData[1] = (UINT8)(xml_length >> 16);
		    pData[2] = (UINT8)(xml_length >> 8);
		    pData[3] = (UINT8)(xml_length >> 0);
		    pData += sizeof(UINT32);
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

HostRequestCommand::HostRequestCommand(const void* payload, UINT32 payloadSize) : RequestCommand(payload, payloadSize)
{}

HostRequestCommand* HostRequestCommand::Create(const void* payload, UINT32 payloadSize){
	const RequestPayload* pRequestPayload = reinterpret_cast<const RequestPayload*>(payload);
	switch(ntohl(pRequestPayload->command)){
	case CMD_HOST_CONN_REQ:
		return new ConnectRequestCommand(payload, payloadSize);
	case CMD_HOST_SEND_REQ:
		return new SendRequestCommand(payload, payloadSize);
	case CMD_HOST_RECV_REQ:
		return new ReceiveRequestCommand(payload, payloadSize);
	case CMD_HOST_DISC_REQ:
		return new DisconnectRequestCommand(payload, payloadSize);
	}
	LOG(_T("Unknown host packet"));
	throw communication_exception();
}

HostResponseCommand::HostResponseCommand(UINT32 command, int status, int cmd_size) : RequestCommand(ciMinSize + cmd_size, command){
	HostResponsePayload* pPayload = GetPayload<HostResponsePayload>();
	WriteStatus(status);
	memset(pPayload->length, '0', sizeof pPayload->length);
	FormatLength<HostResponsePayload>(cmd_size);
}

void HostResponseCommand::WriteStatus(UINT16 status){
	UINT16 status_msb = htons(status);
	HostResponsePayload* pPayload = GetPayload<HostResponsePayload>();
	int dest_len = sizeof(pPayload->status) + 1;
	AtlHexEncode(reinterpret_cast<UINT8*>(&status_msb), sizeof(status_msb), reinterpret_cast<LPSTR>(&pPayload->status), &dest_len);
}

ConnectRequestCommand::ConnectRequestCommand(const void* payload, UINT32 payloadSize) : HostRequestCommand(payload, payloadSize){
	const ConnectPayload* pRequest = reinterpret_cast<const ConnectPayload*>(payload);
	ATLASSERT(pRequest->remote_add_length);
	remote_add.assign(reinterpret_cast<const char*>(pRequest->remote_add), pRequest->remote_add_length);
	const UINT8* pWord = &pRequest->remote_add[pRequest->remote_add_length];
	port = *pWord << 8 | *(pWord + 1);
	pWord += sizeof port;
	timeout = *pWord << 8 | *(pWord + 1);
}

SendRequestCommand::SendRequestCommand(const void* payload, UINT32 payloadSize) : HostRequestCommand(payload, payloadSize){
	const SendPayload* pRequest = reinterpret_cast<const SendPayload*>(payload);
	timeout = htons(pRequest->timeout);
	data.resize(htons(pRequest->data_len));
	memcpy(&data[0], pRequest->data, data.size());
}

ReceiveRequestCommand::ReceiveRequestCommand(const void* payload, UINT32 payloadSize) : HostRequestCommand(payload, payloadSize){
	const ReceivePayload* pRequest = reinterpret_cast<const ReceivePayload*>(payload);
	timeout = htons(pRequest->timeout);
	data_len = htons(pRequest->data_len);
}

ReceiveResponseCommand::ReceiveResponseCommand(const vector<UINT8>& payload) : HostResponseCommand(CMD_HOST_RECV_RSP, EFT_PP_STATUS_SUCCESS, ciMinSize + (int)payload.size()){
	ReceiveResponsePayload* pPayload = GetPayload<ReceiveResponsePayload>();
	pPayload->data_len = htonl(payload.size());
	memcpy(pPayload->data, &payload[0], payload.size());
}

DisconnectRequestCommand::DisconnectRequestCommand(const void* payload, UINT32 payloadSize) : HostRequestCommand(payload, payloadSize){
}

SignatureRequestCommand::SignatureRequestCommand(const void* payload, UINT32 payloadSize) : RequestCommand(payload, payloadSize){
	const SignatureRequestPayload* pRequest = reinterpret_cast<const SignatureRequestPayload*>(payload);
	UINT16 receipt_length = htons(pRequest->receipt_length);
	receipt.assign(pRequest->receipt, receipt_length);
	const char* pXml = pRequest->receipt + receipt_length;
	UINT32 xml_len = *pXml << 24 | *((unsigned char*)pXml + 1) << 16 | *((unsigned char*)pXml + 2) << 8 | *((unsigned char*)pXml + 3);
	pXml += sizeof xml_len;
	xml_details.assign(pXml, xml_len);
}

ChallengeRequestCommand::ChallengeRequestCommand(const void* payload, UINT32 payloadSize) : RequestCommand(payload, payloadSize){
	const ChallengeRequestPayload* pRequest = reinterpret_cast<const ChallengeRequestPayload*>(payload);
	UINT16 random_num_length = ntohs(pRequest->random_num_length);
	random_num.reserve(random_num_length);
	random_num.assign(pRequest->random_num, &pRequest->random_num[random_num_length]);
	const char* pXml = reinterpret_cast<const char*>(pRequest->random_num + random_num_length);
	UINT32 xml_len = *pXml << 24 | *((unsigned char*)pXml + 1) << 16 | *((unsigned char*)pXml + 2) << 8 | *((unsigned char*)pXml + 3);
	pXml += sizeof xml_len;
	xml_details.assign(pXml, xml_len);
}

ChallengeResponseCommand::ChallengeResponseCommand(const vector<UINT8>& mx, const vector<UINT8>& zx) 
	: HostResponseCommand(CMD_STAT_CHALENGE_RSP, EFT_PP_STATUS_SUCCESS, ciMinSize + (int)mx.size() + (int)zx.size())
{
	ChallengeResponsePayload* pPayload = GetPayload<ChallengeResponsePayload>();
	pPayload->mx_len = ntohs(mx.size());
	memcpy(pPayload->mx, &mx[0], mx.size());
	UINT16* pZx = reinterpret_cast<UINT16*>(&pPayload->mx[mx.size()]);
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

SetLogLevelRequestCommand::SetLogLevelRequestCommand(UINT8 log_level) 
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
