#pragma once
#include "CmdIds.h"
#include "Command.h"
#include "IResponseProcessor.h"

#include <string>
#include <cstdint>

using std::string;
using std::uint32_t;
using std::uint8_t;

class RequestCommand;

class ResponseCommand : public Command{
	uint32_t command_hsb;
	int iStatus;

public:
	ResponseCommand(uint32_t type, int status = EFT_PP_STATUS_SUCCESS) : command_hsb(type), iStatus(status){}

	//Command
	bool isResponse(){return true;}
	bool isResponseTo(const RequestCommand& request);

	virtual void ProcessResult(id<IResponseProcessor> processor){[processor processResponse:this];}

	int GetStatus(){return iStatus;}
};

class EventInfoResponseCommand : public ResponseCommand{
	string xml_details;

public:
	EventInfoResponseCommand(int status, bool cancel_allowed = true);
	const string& GetXmlDetails()
    {
        return xml_details;
    }

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor)
    {
        [processor processEventInfoResponse:this];
    }
};

class XMLCommandResponseCommand : public ResponseCommand{
	string xml_details;
    
public:
	XMLCommandResponseCommand(int status, string xml);
    const string& GetXmlReturn(){return xml_details;}
    
	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processXMLCommandResponseCommand:this];}
};

class FinanceResponseCommand : public ResponseCommand{
	uint8_t financial_status;
	uint32_t authorised_amount;
	string trans_id;
	string merchant_receipt;
	string customer_receipt;
	string xml_details;
    BOOL recovered_transaction;

public:
	FinanceResponseCommand(uint32_t cmd, const string& aCurrency, uint32_t amount, uint8_t status = EFT_FINANC_STATUS_TRANS_APPROVED, BOOL recoveredTransaction = NO);
    uint8_t GetFinancialStatus()
    {
        return financial_status & ~EFT_FINANC_STATUS_TRANS_DEVICE_RESET_MASK;
    }
    BOOL isRestarting()
    {
        return financial_status & EFT_FINANC_STATUS_TRANS_DEVICE_RESET_MASK ? YES : NO;
    }
	
    void SetFinancialStatus(uint8_t status)
    {
        financial_status = status;
    }
	
    uint32_t GetAmount()
    {
        return authorised_amount;
    }
    
    const string& GetCustomerReceipt()
    {
        return customer_receipt;
    }
	
    const string& GetMerchantReceipt()
    {
        return merchant_receipt;
    }
    
	const string& GetTransID()
    {
        return trans_id;
    }
	
    const string& GetXmlDetails()
    {
        return xml_details;
    }
    
    BOOL isRecoveredTransaction()
    {
        return recovered_transaction;
    }

	//ResponseCommand
    void ProcessResult(id<IResponseProcessor> processor)
    {
        [processor processFinanceResponse:this];
    }
};

class GetLogInfoResponseCommand : public ResponseCommand{
	string data;

public:
	GetLogInfoResponseCommand();
	const string& GetData(){return data;}

	//ResponseCommand
	void ProcessResult(id<IResponseProcessor> processor){[processor processLogInfoResponse:this];}
};

extern NSString* fin_type[];

string ConvertDictionaryToXML(NSDictionary* dict, NSString* root);

class SimulatorState {
public:    
    SimulatorState() {}
    ~SimulatorState() {}
    
    void clearException() { _in_exception = NO; }
    void flagException() { _in_exception = YES; }
    
    void resetState();
    void startFunction();
    
    BOOL isInException() const { return _in_exception; }
    
    void setAmount(uint32_t amount) { _amount = amount; }
    uint32_t getAmount() const { return _amount; }
    
    void setType(uint32_t type) { _type = type; }
    uint32_t getType() const { return _type; }
    
    void setCurrency(const string& currency) { _currency = currency; }
    string getCurrency() const { return _currency; }
    
    void setCurrencyAbbreviation(const string& abbreviation) { _abbreviation = abbreviation; }
    string getCurrencyAbbreviation() const { return _abbreviation; }
    
    void setAsAuthorized();
    void setAsDeclined();
    BOOL isAuthorized() const { return _authorized; }
    NSInteger getAuthCode() const { return _auth_code; }
    
    void inc_trans_id();
    NSInteger trans_id() const;
    
    void setTransUID(const string& uid) { _trans_uid = uid; }
    string getTransUID() const { return _trans_uid; }
    
    void setOrgTransUID(const string& uid) { _original_trans_uid = uid; }
    string getOrgTransUID() const { return _original_trans_uid; }
    
    void setUsingMsr() { _icc = NO; }
    void setUsingIcc() { _icc = YES; }
    BOOL isIcc() { return _icc; }
    
    string generateReceipt(bool merchant_copy) const;
    
private:
    BOOL _in_exception;
    uint32_t _amount;
    uint32_t _type;
    string _currency;
    BOOL _authorized;
    NSInteger _auth_code;
    string _trans_uid;
    string _original_trans_uid;
    string _abbreviation;
    BOOL _icc;
};

extern SimulatorState simulatorState;

