// #include "StdAfx.h"

#ifndef HEFT_SIMULATOR

#include "ResponseCommand.h"
#include "RequestCommand.h"
#include "BCDCoder.h"
#include "api/CmdIds.h"
#include "debug.h"

#include "Exception.h"
#include "XMLTags.h"

#include <string>
#include <vector>
#include <cstdint>


ResponseCommand* ResponseCommand::Create(const std::vector<std::uint8_t>& buf)
{
    const ResponsePayload* pResponse = reinterpret_cast<const ResponsePayload*>(&buf[0]);
    //LOG_RELEASE(Logger::eFiner, dump(_T("Incoming message"), &buf[0], buf.size()));
    if(buf.size() < sizeof pResponse->command)
    {
        LOG(@"Response less than command");
        throw communication_exception(@"Response less than command");
    }
    switch(ntohl(pResponse->command)) {
        case EFT_PACKET_INIT_RESP:
            return new InitResponseCommand(pResponse, (std::uint32_t) buf.size());
        case EFT_PACKET_SALE_RESP:
        case EFT_PACKET_REFUND_RESP:
        case EFT_PACKET_SALE_VOID_RESP:
        case EFT_PACKET_REFUND_VOID_RESP:
        case EFT_PACKET_START_DAY_RESP:
        case EFT_PACKET_END_DAY_RESP:
        case EFT_PACKET_HOST_INIT_RESP:
        case EFT_PACKET_RECOVERED_TXN_RESULT_RESP:
        {
            NSString *error = [NSString stringWithFormat:@"Response type: %@, buf size too small", @(pResponse->command)];
            NSCAssert(buf.size() >= sizeof(ResponsePayload), error);
            return new FinanceResponseCommand(pResponse, (std::uint32_t) buf.size());
        }
        case EFT_PACKET_TOKENIZE_CARD_RESP:
            return new TokenizeCardCommandResponseCommand(pResponse, (std::uint32_t) buf.size());
        case EFT_PACKET_HOST_CONNECT:
        case EFT_PACKET_HOST_SEND:
        case EFT_PACKET_HOST_RECEIVE:
        case EFT_PACKET_HOST_DISCONNECT:
        case EFT_PACKET_HOST_MSG_TO_HOST:
            return reinterpret_cast<ResponseCommand *>(HostRequestCommand::Create(pResponse, (std::uint32_t) buf.size()));
        case EFT_PACKET_SIGNATURE_REQ:
            return reinterpret_cast<ResponseCommand *>(new SignatureRequestCommand(pResponse, (std::uint32_t) buf.size()));
        case EFT_PACKET_SHARE_SECRET_REQ:
            return reinterpret_cast<ResponseCommand *>(new ChallengeRequestCommand(pResponse, (std::uint32_t) buf.size()));
        case EFT_PACKET_LOG_GETINFO_RESP:
            return new GetLogInfoResponseCommand(pResponse, (std::uint32_t) buf.size());
        case EFT_PACKET_EVENT_INFO_RESP:
            return new EventInfoResponseCommand(pResponse, (std::uint32_t) buf.size());
        case EFT_PACKET_IDLE_RESP:
            return new IdleResponseCommand(pResponse, (std::uint32_t) buf.size());
        case EFT_PACKET_DEBUG_ENABLE_RESP:
        case EFT_PACKET_DEBUG_DISABLE_RESP:
        case EFT_PACKET_DEBUG_RESET_RESP:
        case EFT_PACKET_LOG_SET_LEVEL_RESP:
        case EFT_PACKET_LOG_RESET_RESP:
            NSCAssert(buf.size() >= sizeof(ResponsePayload), @"EFT_PACKET_LOG_RESET_RESP");
            return new ResponseCommand(pResponse, (std::uint32_t) buf.size());
        case EFT_PACKET_COMMAND_RESP:
            return new XMLCommandResponseCommand(pResponse, buf.size());
        default:
            LOG(@"Unknown command");
            throw communication_exception(@"Unknown command");
    }
    return 0;
}

ResponseCommand::ResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize)
:
command_hsb(pPayload->command),
iStatus(ReadStatus(pPayload)),
length(ReadLength(pPayload))
{
    if ((payloadSize - 4 - 4 - 6) != length)
    {
        LOG(@"Invalid response command buffer detected");
        throw communication_exception(@"Invalid response command buffer detected");
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
    if(GetStatus() == EFT_PP_STATUS_SUCCESS) {
        const InitPayload* pResponse = static_cast<const InitPayload*>(pPayload);
        
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
            throw communication_exception(@"Invalid xml data length in command detected");
        }
        xml_details.assign(pResponse->xml_details, xml_len);
    }
    else
    {
        LOG(@"STATUS != EFT_PP_STATUS_SUCCESS");
    }
}

TokenizeCardCommandResponseCommand::TokenizeCardCommandResponseCommand(const ResponsePayload* pPayload, size_t payload_size)
: ResponseCommand(pPayload, (std::uint32_t)payload_size)
{
    const XMLCommandPayload* pResponse = static_cast<const XMLCommandPayload*>(pPayload);
    std::uint32_t xml_len = ntohl(pResponse->xml_details_length);
    if(xml_len > GetLength())
    {
        LOG(@"Invalid xml data length in command detected");
        throw communication_exception(@"Invalid xml data length in command detected");
    }
    xml_details.assign(pResponse->xml_details, xml_len);
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

FinanceResponseCommand::FinanceResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize)
: ResponseCommand(pPayload, payloadSize)
, financial_status(0)
, authorised_amount(0)
, recovered_transaction((pPayload->command == EFT_PACKET_RECOVERED_TXN_RESULT_RESP))
{
    if(GetLength() > sizeof(FinancePayload) - sizeof(ResponsePayload)) {
        const FinancePayload *pResponse = static_cast<const FinancePayload *>(pPayload);
        financial_status = pResponse->financial_status;
        authorised_amount = ntohl(pResponse->authorised_amount);
        trans_id.assign(pResponse->trans_id, pResponse->trans_id_length);
        const char *pReceiptLen = &pResponse->trans_id[pResponse->trans_id_length];
        std::uint16_t len = *pReceiptLen << 8 | *((unsigned char *) pReceiptLen + 1);
        pReceiptLen += sizeof len;
        merchant_receipt.assign(pReceiptLen, len);
        pReceiptLen += len;
        len = *pReceiptLen << 8 | *((unsigned char *) pReceiptLen + 1);
        pReceiptLen += sizeof len;
        customer_receipt.assign(pReceiptLen, len);
        pReceiptLen += len;
        std::uint32_t xml_len = *pReceiptLen << 24 |
        *((unsigned char *) pReceiptLen + 1) << 16 |
        *((unsigned char *) pReceiptLen + 2) << 8 | *((unsigned char *) pReceiptLen + 3);
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
