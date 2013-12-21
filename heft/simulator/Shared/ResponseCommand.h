#pragma once
#include "CmdIds.h"
#include "Command.h"
#include "IResponseProcessor.h"

class RequestCommand;

enum eTransactionStatus;

class ResponseCommand : public Command{
	UINT32 command_hsb;
	int iStatus;

public:
	ResponseCommand(UINT32 type, int status = EFT_PP_STATUS_SUCCESS) : command_hsb(type), iStatus(status){}

	//Command
	bool isResponse(){return true;}
	bool isResponseTo(const RequestCommand& request);

	virtual void ProcessResult(id<IResponseProcessor> processor){[processor processResponse:this];}

	int GetStatus(){return iStatus;}
};


class EventInfoResponseCommand : public ResponseCommand{
	string xml_details;

public:
	EventInfoResponseCommand(int status);
	const string& GetXmlDetails(){return xml_details;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processEventInfoResponse:this];}
};

class XMLCommandResponseCommand : public ResponseCommand{
	string xml_details;
    
public:
	XMLCommandResponseCommand(int status);
    const string& GetXmlReturn(){return xml_details;}
    
	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processXMLCommandResponseCommand:this];}
};

class FinanceResponseCommand : public ResponseCommand{
	eTransactionStatus financial_status;
	UINT32 authorised_amount;
	string trans_id;
	string merchant_receipt;
	string customer_receipt;
	string xml_details;

public:
	FinanceResponseCommand(UINT32 cmd, const string& aCurrency, UINT32 amount, eTransactionStatus status = eTransactionApproved);
	FinanceResponseCommand(UINT32 cmd, UINT32 amount, int status);
	FinanceResponseCommand(UINT32 cmd, const string& aCurrency, UINT32 amount, const string& transaction_id);
	FinanceResponseCommand(UINT32 cmd) : ResponseCommand(cmd){};
	eTransactionStatus GetFinancialStatus(){return eTransactionStatus(financial_status);}
	void SetFinancialStatus(eTransactionStatus status){financial_status = status;}
	UINT32 GetAmount(){return authorised_amount;}
	const string& GetCustomerReceipt(){return customer_receipt;}
	const string& GetMerchantReceipt(){return merchant_receipt;}
	const string& GetTransID(){return trans_id;}
	const string& GetXmlDetails(){return xml_details;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processFinanceResponse:this];}
};

/*class DebugInfoResponseCommand : public ResponseCommand{
	string data;

public:
	DebugInfoResponseCommand();
	const string& GetData(){return data;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processDebugInfoResponse:this];}
};*/

class GetLogInfoResponseCommand : public ResponseCommand{
	string data;

public:
	GetLogInfoResponseCommand();
	const string& GetData(){return data;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processLogInfoResponse:this];}
};

extern int trans_id_seed;
extern NSString* fin_type[];
