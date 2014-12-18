#pragma once
#include "CmdIds.h"
#include "Command.h"
#include "IResponseProcessor.h"

class RequestCommand;

class ResponseCommand : public Command{
	UINT32 command_hsb;
	int iStatus;
	int length;

protected:
#pragma pack(push, 1)
	struct ResponsePayload : CommandPayload{
		UINT32 status;
		UINT8 length[6];
	};
#pragma pack(pop)

	ResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize);

	int ReadLength(const ResponsePayload* pResponse);
	int ReadStatus(const ResponsePayload* pResponse);

public:
	//Command
	bool isResponse(){return true;}
	bool isResponseTo(const RequestCommand& request);

	virtual void ProcessResult(id<IResponseProcessor> processor){[processor processResponse:this];}

	int GetStatus(){return iStatus;}
	int GetLength(){return length;}

	static ResponseCommand* Create(const vector<UINT8>& buf);
};

class InitResponseCommand : public ResponseCommand{
	UINT16 com_buffer_size;
	string serial_number;
	UINT16 public_key_ver;
	UINT16 emv_param_ver;
	UINT16 general_param_ver;
	UINT8 manufacturer_code;
	UINT8 model_code;
	string app_name;
	UINT16 app_ver;
	string xml_details;

#pragma pack(push, 1)
	struct InitPayload : ResponsePayload{
		UINT16 com_buffer_size;
		UINT8 serial_number[6];
		UINT16 public_key_ver;
		UINT16 emv_param_ver;
		UINT16 general_param_ver;
		UINT8 manufacturer_code;
		UINT8 model_code;
		UINT8 app_name[8];
		UINT16 app_ver;
		UINT32 xml_details_length;
		char xml_details[];
	};
#pragma pack(pop)

public:
	InitResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize);
	int GetBufferSize(){return com_buffer_size;}
	string GetSerialNumber(){return serial_number;}
	int GetPublicKeyVer(){return public_key_ver;}
	int GetEmvParamVer(){return emv_param_ver;}
	int GetGeneralParamVer(){return general_param_ver;}
	int GetManufacturerCode(){return manufacturer_code;}
	int GetModelCode(){return model_code;}
	string GetAppName(){return app_name;}
	int GetAppVer(){return app_ver;}
	const string& GetXmlDetails(){return xml_details;}
};

class XMLCommandResponseCommand : public ResponseCommand{
	string xml_return;

#pragma pack(push, 1)
	struct XMLCommandPayload : ResponsePayload{
		char xml_return[];
	};
#pragma pack(pop)

public:
	XMLCommandResponseCommand(const ResponsePayload* pPayload, size_t payload_size);
	const string& GetXmlReturn(){return xml_return;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processXMLCommandResponseCommand:this];}
};


class IdleResponseCommand : public ResponseCommand{
	string xml_details;

#pragma pack(push, 1)
	struct IdlePayload : ResponsePayload{
		UINT32 xml_details_length;
		char xml_details[];
	};
#pragma pack(pop)

public:
	IdleResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize);
	const string& GetXmlDetails(){return xml_details;}
};

class EventInfoResponseCommand : public ResponseCommand{
	string xml_details;

#pragma pack(push, 1)
	struct EventInfoPayload : ResponsePayload{
		UINT32 xml_details_length;
		char xml_details[];
	};
#pragma pack(pop)

public:
	EventInfoResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize);
	const string& GetXmlDetails(){return xml_details;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processEventInfoResponse:this];}
};

class FinanceResponseCommand : public ResponseCommand{
	UINT8 financial_status;
	UINT32 authorised_amount;
	string trans_id;
	string merchant_receipt;
	string customer_receipt;
	string xml_details;
    BOOL recovered_transaction;

#pragma pack(push, 1)
	struct FinancePayload : ResponsePayload{
		UINT8 financial_status;
		UINT32 authorised_amount;
		UINT8 trans_id_length;
		char trans_id[];
	};
#pragma pack(pop)

public:
	FinanceResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize, BOOL recoveredTransaction);
    UINT8 GetFinancialStatus(){return financial_status & ~EFT_FINANC_STATUS_TRANS_DEVICE_RESET_MASK;}
    BOOL isRestarting(){return financial_status & EFT_FINANC_STATUS_TRANS_DEVICE_RESET_MASK ? YES : NO;}
	UINT32 GetAmount(){return authorised_amount;}
	const string& GetCustomerReceipt(){return customer_receipt;}
	const string& GetMerchantReceipt(){return merchant_receipt;}
	const string& GetTransID(){return trans_id;}
	const string& GetXmlDetails(){return xml_details;}
    BOOL isRecoveredTransaction(){return recovered_transaction;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processFinanceResponse:this];}
};

class GetLogInfoResponseCommand : public ResponseCommand{
	string data;

#pragma pack(push, 1)
	struct GetLogInfoPayload : ResponsePayload{
		UINT32 data_len;
		UINT8 data[];
	};
#pragma pack(pop)

public:
	GetLogInfoResponseCommand(const ResponsePayload* pPayload, UINT32 payloadSize);
	const string& GetData(){return data;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processLogInfoResponse:this];}
};
