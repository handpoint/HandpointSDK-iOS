#pragma once
#include "CmdIds.h"
#include "Command.h"
#include "IResponseProcessor.h"

#include <vector>
#include <string>

class RequestCommand;

class ResponseCommand : public Command{
	std::uint32_t command_hsb;
	int iStatus;
	int length;

protected:
#pragma pack(push, 1)
	struct ResponsePayload : CommandPayload{
		std::uint32_t status;
        std::uint8_t length[6];
	};
#pragma pack(pop)

	ResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize);

	int ReadLength(const ResponsePayload* pResponse);
	int ReadStatus(const ResponsePayload* pResponse);

public:
	//Command
	bool isResponse() {
        return true;
    }
	
    bool isResponseTo(const RequestCommand& request);

	virtual void ProcessResult(id<IResponseProcessor> processor) {
        [processor processResponse:this];
    }

    int GetStatus() {
        return iStatus;
    }

    void SetStatus(int status) {
        iStatus = status;
    }
	
    int GetLength() {
        return length;
    }

    static ResponseCommand* Create(const std::vector<std::uint8_t>& buf);
};

class InitResponseCommand : public ResponseCommand{
	std::uint16_t com_buffer_size;
    std::string serial_number;
	std::uint16_t public_key_ver;
	std::uint16_t emv_param_ver;
	std::uint16_t general_param_ver;
	std::uint8_t manufacturer_code;
	std::uint8_t model_code;
    std::string app_name;
	std::uint16_t app_ver;
    std::string xml_details;

#pragma pack(push, 1)
	struct InitPayload : ResponsePayload{
		std::uint16_t com_buffer_size;
		std::uint8_t serial_number[6];
		std::uint16_t public_key_ver;
		std::uint16_t emv_param_ver;
		std::uint16_t general_param_ver;
		std::uint8_t manufacturer_code;
		std::uint8_t model_code;
		std::uint8_t app_name[8];
		std::uint16_t app_ver;
		std::uint32_t xml_details_length;
		char xml_details[];
	};
#pragma pack(pop)

public:
	InitResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize);
    
	int GetBufferSize() {
        return com_buffer_size;
    }
    
    std::string GetSerialNumber() {
        return serial_number;
    }
	
    int GetPublicKeyVer() {
        return public_key_ver;
    }
	
    int GetEmvParamVer() {
        return emv_param_ver;
    }
    
	int GetGeneralParamVer() {
        return general_param_ver;
    }
	
    int GetManufacturerCode() {
        return manufacturer_code;
    }
    
	int GetModelCode() {
        return model_code;
    }
    
    std::string GetAppName() {
        return app_name;
    }
	
    int GetAppVer() {
        return app_ver;
    }
    
    const std::string& GetXmlDetails() {
        return xml_details;
    }
};

class XMLCommandResponseCommand : public ResponseCommand{
    std::string xml_return;

#pragma pack(push, 1)
	struct XMLCommandPayload : ResponsePayload{
		char xml_return[];
	};
#pragma pack(pop)

public:
	XMLCommandResponseCommand(const ResponsePayload* pPayload, size_t payload_size);
    const std::string& GetXmlReturn(){return xml_return;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processXMLCommandResponseCommand:this];}
};


class IdleResponseCommand : public ResponseCommand{
    std::string xml_details;

#pragma pack(push, 1)
	struct IdlePayload : ResponsePayload{
		std::uint32_t xml_details_length;
		char xml_details[];
	};
#pragma pack(pop)

public:
	IdleResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize);
    const std::string& GetXmlDetails(){return xml_details;}
};

class EventInfoResponseCommand : public ResponseCommand{
    std::string xml_details;

#pragma pack(push, 1)
	struct EventInfoPayload : ResponsePayload{
		std::uint32_t xml_details_length;
		char xml_details[];
	};
#pragma pack(pop)

public:
	EventInfoResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize);
    const std::string& GetXmlDetails(){return xml_details;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processEventInfoResponse:this];}
};

class FinanceResponseCommand : public ResponseCommand{
	std::uint8_t financial_status;
	std::uint32_t authorised_amount;
	std::string trans_id;
	std::string merchant_receipt;
	std::string customer_receipt;
	std::string xml_details;
    BOOL recovered_transaction;

#pragma pack(push, 1)
	struct FinancePayload : ResponsePayload{
		std::uint8_t financial_status;
		std::uint32_t authorised_amount;
		std::uint8_t trans_id_length;
		char trans_id[];
	};
#pragma pack(pop)

public:
	FinanceResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize, BOOL recoveredTransaction);
    
    std::uint8_t GetFinancialStatus() {
        return financial_status & ~EFT_FINANC_STATUS_TRANS_DEVICE_RESET_MASK;
    }
    
    BOOL isRestarting() {
        return financial_status & EFT_FINANC_STATUS_TRANS_DEVICE_RESET_MASK ? YES : NO;
    }
    
	std::uint32_t GetAmount() {
        return authorised_amount;
    }
    
    const std::string& GetCustomerReceipt() {
        return customer_receipt;
    }
    
    const std::string& GetMerchantReceipt() {
        return merchant_receipt;
    }
    
    const std::string& GetTransID() {
        return trans_id;
    }
    
    const std::string& GetXmlDetails() {
        return xml_details;
    }
    
    BOOL isRecoveredTransaction() {
        return recovered_transaction;
    }

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor) {
        [processor processFinanceResponse:this];
    }
};

class GetLogInfoResponseCommand : public ResponseCommand {
    std::string data;

#pragma pack(push, 1)
	struct GetLogInfoPayload : ResponsePayload{
		std::uint32_t data_len;
		std::uint8_t data[];
	};
#pragma pack(pop)

public:
	GetLogInfoResponseCommand(const ResponsePayload* pPayload, std::uint32_t payloadSize);
    const std::string& GetData(){return data;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor) {
        [processor processLogInfoResponse:this];
    }
};
