// #include "StdAfx.h"

#ifndef HEFT_SIMULATOR

#include "ResponseCommand.h"
#include "RequestCommand.h"
#include "BCDCoder.h"
#include "HeftCmdIds.h"
#include "api/CmdIds.h"
#include "debug.h"

#include "Exception.h"

#include <string>
#include <vector>
#include <cstdint>


ResponseCommand* ResponseCommand::Create(const std::vector<std::uint8_t>& buf)
// std::shared_ptr<ResponseCommand> ResponseCommand::Create(const vector<std::uint8_t>& buf)
{
	const ResponsePayload* pResponse = reinterpret_cast<const ResponsePayload*>(&buf[0]);
	//LOG_RELEASE(Logger::eFiner, dump(_T("Incoming message"), &buf[0], buf.size()));
	if(buf.size() < sizeof pResponse->command)
    {
		LOG(@"Response less than command");
		throw communication_exception();
	}
	switch(ntohl(pResponse->command))
    {
	case CMD_INIT_RSP:
		// ATLASSERT(buf.size() >= sizeof(ResponsePayload));
		return new InitResponseCommand(pResponse, (std::uint32_t)buf.size());
        // return std::make_shared<InitResponseCommand>(pResponse, (std::uint32_t)buf.size());
	case CMD_FIN_SALE_RSP:
	case CMD_FIN_REFUND_RSP:
	case CMD_FIN_SALEV_RSP:
	case CMD_FIN_REFUNDV_RSP:
	case CMD_FIN_STARTDAY_RSP:
	case CMD_FIN_ENDDAY_RSP:
	case CMD_FIN_INIT_RSP:
		NSCAssert(buf.size() >= sizeof(ResponsePayload), @"CMD_FIN_INIT_RSP, buf size too small");
		return new FinanceResponseCommand(pResponse, (std::uint32_t)buf.size(), NO);
    case CMD_FIN_RCVRD_TXN_RSLT_RSP:
        NSCAssert(buf.size() >= sizeof(ResponsePayload), @"CMD_FIN_RCVRD_TXN_RSLT_RSP, buf size too small");
        return new FinanceResponseCommand(pResponse, (std::uint32_t)buf.size(), YES);
	case CMD_HOST_CONN_REQ:
	case CMD_HOST_SEND_REQ:
	case CMD_HOST_RECV_REQ:
	case CMD_HOST_DISC_REQ:
		return reinterpret_cast<ResponseCommand*>(HostRequestCommand::Create(pResponse, (std::uint32_t)buf.size()));
	case CMD_STAT_SIGN_REQ:
		return reinterpret_cast<ResponseCommand*>(new SignatureRequestCommand(pResponse, (std::uint32_t)buf.size()));
	case CMD_STAT_CHALENGE_REQ:
		return reinterpret_cast<ResponseCommand*>(new ChallengeRequestCommand(pResponse, (std::uint32_t)buf.size()));
	case CMD_LOG_GET_INF_RSP:
		return new GetLogInfoResponseCommand(pResponse, (std::uint32_t)buf.size());
	case CMD_STAT_INFO_RSP:
		return new EventInfoResponseCommand(pResponse, (std::uint32_t)buf.size());
	case CMD_IDLE_RSP:
		return new IdleResponseCommand(pResponse, (std::uint32_t)buf.size());
	case CMD_DBG_ENABLE_RSP:
	case CMD_DBG_DISABLE_RSP:
	case CMD_DBG_RESET_RSP:
	case CMD_LOG_SET_LEV_RSP:
	case CMD_LOG_RST_INF_RSP:
		NSCAssert(buf.size() >= sizeof(ResponsePayload), @"CMD_LOG_RST_INF_RSP");
		return new ResponseCommand(pResponse, (std::uint32_t)buf.size());
	case CMD_XCMD_RSP:
		return new XMLCommandResponseCommand(pResponse, buf.size());
	default:
		LOG(@"Unknown command");
		throw communication_exception();
	}
	return 0;
}

ResponseCommand::ResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize)
    : command_hsb(pPayload->command), iStatus(ReadStatus(pPayload)), length(ReadLength(pPayload))
{
    if ((payloadSize - 4 - 4 - 6) != length)
    {
        LOG(@"Invalid response command buffer detected");
        throw communication_exception();
    }
}

int ResponseCommand::ReadLength(const ResponsePayload* pResponse)
{
	std::uint32_t len_msb = 0;
	int dest_len = sizeof(len_msb) - 1;
	AtlHexDecode(reinterpret_cast<const char*>(pResponse->length),
                 sizeof(pResponse->length),
                 reinterpret_cast<std::uint8_t*>(&len_msb) + 1,
                 &dest_len);
	return ntohl(len_msb);
}

int ResponseCommand::ReadStatus(const ResponsePayload* pResponse)
{
	std::uint16_t status_msb = 0;
	int dest_len = sizeof(status_msb);
	AtlHexDecode(reinterpret_cast<const char*>(&pResponse->status),
                 sizeof(pResponse->status),
                 reinterpret_cast<std::uint8_t*>(&status_msb),
                 &dest_len);
	return ntohs(status_msb);
}

bool ResponseCommand::isResponseTo(const RequestCommand& request){
	// ATLASSERT(request.GetLength() > sizeof command_hsb);
	return !memcmp(&command_hsb, request.GetData(), sizeof(command_hsb) - 1);
}

InitResponseCommand::InitResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize)
    : ResponseCommand(pPayload, payloadSize)
{
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
		std::uint32_t xml_len = ntohl(pResponse->xml_details_length);
        if(xml_len > GetLength())
        {
            LOG(@"Invalid xml data length in command detected");
            throw communication_exception();
        }
		xml_details.assign(pResponse->xml_details, xml_len);
	}
}

XMLCommandResponseCommand::XMLCommandResponseCommand(const ResponsePayload* pPayload, size_t payload_size)
    : ResponseCommand(pPayload, (std::uint32_t)payload_size)
{
		const XMLCommandPayload* pResponse = static_cast<const XMLCommandPayload*>(pPayload);
		xml_return.assign(pResponse->xml_return, payload_size - sizeof(ResponsePayload));
}

IdleResponseCommand::IdleResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize)
    : ResponseCommand(pPayload, payloadSize)
{
	if(GetStatus() == EFT_PP_STATUS_SUCCESS)
    {
		const IdlePayload* pResponse = static_cast<const IdlePayload*>(pPayload);
		//ATLASSERT(ReadLength(pResponse) == sizeof(IdlePayload) - sizeof(ResponsePayload));
		std::uint32_t xml_len = ntohl(pResponse->xml_details_length);
		xml_details.assign(pResponse->xml_details, xml_len);
	}
}

EventInfoResponseCommand::EventInfoResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize)
    : ResponseCommand(pPayload, payloadSize)
{
	const EventInfoPayload* pResponse = static_cast<const EventInfoPayload*>(pPayload);
	//ATLASSERT(ReadLength(pResponse) == sizeof(EventInfoPayload) - sizeof(ResponsePayload));
	std::uint32_t xml_len = ntohl(pResponse->xml_details_length);
	xml_details.assign(pResponse->xml_details, xml_len);
}

FinanceResponseCommand::FinanceResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize, BOOL recoveredTransaction)
	: ResponseCommand(pPayload, payloadSize)
	, financial_status(0)
    , authorised_amount(0)
    , recovered_transaction(recoveredTransaction)
{
	if(GetLength() > sizeof(FinancePayload) - sizeof(ResponsePayload))
    {
		const FinancePayload* pResponse = static_cast<const FinancePayload*>(pPayload);
		financial_status = pResponse->financial_status;
		authorised_amount = ntohl(pResponse->authorised_amount);
		trans_id.assign(pResponse->trans_id, pResponse->trans_id_length);
		const char* pReceiptLen = &pResponse->trans_id[pResponse->trans_id_length];
		std::uint16_t len = *pReceiptLen << 8 | *((unsigned char*)pReceiptLen + 1);
		pReceiptLen += sizeof len;
		merchant_receipt.assign(pReceiptLen, len);
		pReceiptLen += len;
		len = *pReceiptLen << 8 | *((unsigned char*)pReceiptLen + 1);
		pReceiptLen += sizeof len;
		customer_receipt.assign(pReceiptLen, len);
		pReceiptLen += len;
		std::uint32_t xml_len = *pReceiptLen << 24 | *((unsigned char*)pReceiptLen + 1) << 16 | *((unsigned char*)pReceiptLen + 2) << 8 | *((unsigned char*)pReceiptLen + 3);
		pReceiptLen += sizeof xml_len;
		xml_details.assign(pReceiptLen, xml_len);
	}
}

GetLogInfoResponseCommand::GetLogInfoResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize)
    : ResponseCommand(pPayload, payloadSize)
{
	if(GetStatus() == EFT_PP_STATUS_SUCCESS)
    {
		const GetLogInfoPayload* pResponse = static_cast<const GetLogInfoPayload*>(pPayload);
		data.assign(pResponse->data, &pResponse->data[ntohl(pResponse->data_len)]);
	}
}

#endif