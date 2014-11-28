#include "StdAfx.h"
#include "ResponseCommand.h"
#include "RequestCommand.h"
#include "BCDCoder.h"
#include "HeftCmdIds.h"
#include "api/CmdIds.h"

ResponseCommand* ResponseCommand::Create(const vector<UINT8>& buf){
	const ResponsePayload* pResponse = reinterpret_cast<const ResponsePayload*>(&buf[0]);
	//LOG_RELEASE(Logger::eFiner, dump(_T("Incoming message"), &buf[0], buf.size()));
	if(buf.size() < sizeof pResponse->command){
		LOG(_T("Response less than command"));
		throw communication_exception();
	}
	switch(ntohl(pResponse->command)){
	case CMD_INIT_RSP:
		ATLASSERT(buf.size() >= sizeof(ResponsePayload));
		return new InitResponseCommand(pResponse, (UINT32)buf.size());
	case CMD_FIN_SALE_RSP:
	case CMD_FIN_REFUND_RSP:
	case CMD_FIN_SALEV_RSP:
	case CMD_FIN_REFUNDV_RSP:
	case CMD_FIN_STARTDAY_RSP:
	case CMD_FIN_ENDDAY_RSP:
	case CMD_FIN_INIT_RSP:
		ATLASSERT(buf.size() >= sizeof(ResponsePayload));
		return new FinanceResponseCommand(pResponse, (UINT32)buf.size(), NO);
    case CMD_FIN_RCVRD_TXN_RSLT_RSP:
        ATLASSERT(buf.size() >= sizeof(ResponsePayload));
        return new FinanceResponseCommand(pResponse, (UINT32)buf.size(), YES);
	case CMD_HOST_CONN_REQ:
	case CMD_HOST_SEND_REQ:
	case CMD_HOST_RECV_REQ:
	case CMD_HOST_DISC_REQ:
		return reinterpret_cast<ResponseCommand*>(HostRequestCommand::Create(pResponse, (UINT32)buf.size()));
	case CMD_STAT_SIGN_REQ:
		return reinterpret_cast<ResponseCommand*>(new SignatureRequestCommand(pResponse, (UINT32)buf.size()));
	case CMD_STAT_CHALENGE_REQ:
		return reinterpret_cast<ResponseCommand*>(new ChallengeRequestCommand(pResponse, (UINT32)buf.size()));
	/*case CMD_DBG_INFO_RSP:
		return new DebugInfoResponseCommand(pResponse);*/
	case CMD_LOG_GET_INF_RSP:
		return new GetLogInfoResponseCommand(pResponse, (UINT32)buf.size());
	case CMD_STAT_INFO_RSP:
		return new EventInfoResponseCommand(pResponse, (UINT32)buf.size());
	case CMD_IDLE_RSP:
		return new IdleResponseCommand(pResponse, (UINT32)buf.size());
	case CMD_DBG_ENABLE_RSP:
	case CMD_DBG_DISABLE_RSP:
	case CMD_DBG_RESET_RSP:
	case CMD_LOG_SET_LEV_RSP:
	case CMD_LOG_RST_INF_RSP:
		ATLASSERT(buf.size() >= sizeof(ResponsePayload));
		return new ResponseCommand(pResponse, (UINT32)buf.size());
	case CMD_XCMD_RSP:
		return new XMLCommandResponseCommand(pResponse, buf.size());
	default:
		LOG(_T("Unknown command"));
		throw communication_exception();
	}
	return 0;
}

ResponseCommand::ResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize) : command_hsb(pPayload->command), iStatus(ReadStatus(pPayload)), length(ReadLength(pPayload)){
    if ((payloadSize - 4 - 4 - 6) != length) {
        LOG(_T("Invalid response command buffer detected"));
        throw communication_exception();
    }
}

int ResponseCommand::ReadLength(const ResponsePayload* pResponse){
	UINT32 len_msb = 0;
	int dest_len = sizeof(len_msb) - 1;
	AtlHexDecode(reinterpret_cast<LPCSTR>(pResponse->length), sizeof(pResponse->length), reinterpret_cast<UINT8*>(&len_msb) + 1, &dest_len);
	return ntohl(len_msb);
}

int ResponseCommand::ReadStatus(const ResponsePayload* pResponse){
	UINT16 status_msb = 0;
	int dest_len = sizeof(status_msb);
	AtlHexDecode(reinterpret_cast<LPCSTR>(&pResponse->status), sizeof(pResponse->status), reinterpret_cast<UINT8*>(&status_msb), &dest_len);
	return ntohs(status_msb);
}

bool ResponseCommand::isResponseTo(const RequestCommand& request){
	ATLASSERT(request.GetLength() > sizeof command_hsb);
	return !memcmp(&command_hsb, request.GetData(), sizeof(command_hsb) - 1);
}

InitResponseCommand::InitResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize) : ResponseCommand(pPayload, payloadSize){
	if(GetStatus() == EFT_PP_STATUS_SUCCESS){
		const InitPayload* pResponse = static_cast<const InitPayload*>(pPayload);
		//ATLASSERT(ReadLength(pResponse) == sizeof(InitPayload) - sizeof(ResponsePayload));
		com_buffer_size = ntohs(pResponse->com_buffer_size);
		serial_number = BCDCoder::Decode(pResponse->serial_number, sizeof(pResponse->serial_number));
		public_key_ver = ntohs(pResponse->public_key_ver);
		emv_param_ver = ntohs(pResponse->emv_param_ver);
		general_param_ver = ntohs(pResponse->general_param_ver);
		manufacturer_code = pResponse->manufacturer_code;
		model_code = pResponse->model_code;
		app_name.assign(reinterpret_cast<const char*>(pResponse->app_name), sizeof(pResponse->app_name));
		app_ver = ntohs(pResponse->app_ver);
		UINT32 xml_len = ntohl(pResponse->xml_details_length);
        if(xml_len > GetLength())
        {
            LOG(_T("Invalid xml data length in command detected"));
            throw communication_exception();
        }
		xml_details.assign(pResponse->xml_details, xml_len);
	}
}

XMLCommandResponseCommand::XMLCommandResponseCommand(const ResponsePayload* pPayload, size_t payload_size) : ResponseCommand(pPayload, (UINT32)payload_size){
		const XMLCommandPayload* pResponse = static_cast<const XMLCommandPayload*>(pPayload);
		xml_return.assign(pResponse->xml_return, payload_size - sizeof(ResponsePayload));
}

IdleResponseCommand::IdleResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize) : ResponseCommand(pPayload, payloadSize){
	if(GetStatus() == EFT_PP_STATUS_SUCCESS){
		const IdlePayload* pResponse = static_cast<const IdlePayload*>(pPayload);
		//ATLASSERT(ReadLength(pResponse) == sizeof(IdlePayload) - sizeof(ResponsePayload));
		UINT32 xml_len = ntohl(pResponse->xml_details_length);
		xml_details.assign(pResponse->xml_details, xml_len);
	}
}

EventInfoResponseCommand::EventInfoResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize) : ResponseCommand(pPayload, payloadSize){
	const EventInfoPayload* pResponse = static_cast<const EventInfoPayload*>(pPayload);
	//ATLASSERT(ReadLength(pResponse) == sizeof(EventInfoPayload) - sizeof(ResponsePayload));
	UINT32 xml_len = ntohl(pResponse->xml_details_length);
	xml_details.assign(pResponse->xml_details, xml_len);
}

FinanceResponseCommand::FinanceResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize, BOOL recoveredTransaction)
	: ResponseCommand(pPayload, payloadSize)
	, financial_status(0)
    , authorised_amount(0)
    , recovered_transaction(recoveredTransaction)
{
	if(GetLength() > sizeof(FinancePayload) - sizeof(ResponsePayload)){
		const FinancePayload* pResponse = static_cast<const FinancePayload*>(pPayload);
		financial_status = pResponse->financial_status;
		authorised_amount = ntohl(pResponse->authorised_amount);
		trans_id.assign(pResponse->trans_id, pResponse->trans_id_length);
		const char* pReceiptLen = &pResponse->trans_id[pResponse->trans_id_length];
		UINT16 len = *pReceiptLen << 8 | *((unsigned char*)pReceiptLen + 1);
		pReceiptLen += sizeof len;
		merchant_receipt.assign(pReceiptLen, len);
		pReceiptLen += len;
		len = *pReceiptLen << 8 | *((unsigned char*)pReceiptLen + 1);
		pReceiptLen += sizeof len;
		customer_receipt.assign(pReceiptLen, len);
		pReceiptLen += len;
		UINT32 xml_len = *pReceiptLen << 24 | *((unsigned char*)pReceiptLen + 1) << 16 | *((unsigned char*)pReceiptLen + 2) << 8 | *((unsigned char*)pReceiptLen + 3);
		pReceiptLen += sizeof xml_len;
		xml_details.assign(pReceiptLen, xml_len);
	}
}

/*DebugInfoResponseCommand::DebugInfoResponseCommand(const ResponsePayload* pPayload) : ResponseCommand(pPayload){
	if(GetStatus() == EFT_PP_STATUS_SUCCESS){
		const DebugInfoPayload* pResponse = static_cast<const DebugInfoPayload*>(pPayload);
		data.assign(pResponse->data, &pResponse->data[ntohs(pResponse->data_len)]);
	}
}*/

GetLogInfoResponseCommand::GetLogInfoResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize) : ResponseCommand(pPayload, payloadSize){
	if(GetStatus() == EFT_PP_STATUS_SUCCESS){
		const GetLogInfoPayload* pResponse = static_cast<const GetLogInfoPayload*>(pPayload);
		data.assign(pResponse->data, &pResponse->data[ntohl(pResponse->data_len)]);
	}
}
