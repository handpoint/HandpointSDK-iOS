#pragma once
#include "Command.h"
#include "CmdIds.h"

#include <cstdint>
#include <string>

using std::uint32_t;
using std::uint8_t;
using std::string;

class ResponseCommand;

class RequestCommand : public Command{
protected:
	uint32_t m_cmd;

	RequestCommand(uint32_t cmd) : m_cmd(cmd){}

public:
	//Command
	bool isResponse(){return false;}
	virtual ResponseCommand* CreateResponse()const;
    virtual ResponseCommand* CreateResponseOnCancel()const;

	uint32_t GetType()const{return m_cmd;}
};

class FinanceRequestCommand : public RequestCommand{
	string currency;
	uint32_t amount;

protected:
	enum eState{eWaitingCard, eCardInserted, eAppSelect, ePinInput, eConnect};
	mutable int state;

public:
	FinanceRequestCommand(uint32_t type, const string& currency_code, uint32_t trans_amount, uint8_t card_present, const string& trans_id, const string& xml);
	uint32_t GetAmount() const
    {
        return amount;
    }
	
    const string& GetCurrency() const
    {
        return currency;
    }
    
	ResponseCommand* CreateResponse() const;
	ResponseCommand* CreateResponseOnCancel() const;
};

class TokenizeCardRequestCommand : public FinanceRequestCommand{
public:
    TokenizeCardRequestCommand(const std::string &xml);
};

class XMLCommandRequestCommand : public RequestCommand{
    string xml_data;

public:
	XMLCommandRequestCommand(const string& xml);
    
    ResponseCommand* CreateResponse()const;
    ResponseCommand* CreateResponseOnCancel()const;
};

class StartOfDayRequestCommand : public FinanceRequestCommand{
public:
	StartOfDayRequestCommand();
};

class EndOfDayRequestCommand : public FinanceRequestCommand{
public:
	EndOfDayRequestCommand();
};

class FinanceInitRequestCommand : public FinanceRequestCommand{
public:
	FinanceInitRequestCommand();
};

class FinanceRecoverTransactionRequestCommand : public FinanceRequestCommand{
public:
    FinanceRecoverTransactionRequestCommand();
};

#include "../../Shared/IHostProcessor.h"

class HostRequestCommand : public RequestCommand, public IRequestProcess{
protected:
	string currency;
	uint32_t amount;
	uint32_t fin_cmd;

public:
	HostRequestCommand(uint32_t cmd, const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd)
        : RequestCommand(cmd), currency(aCurrency), amount(aAmount), fin_cmd(aFin_cmd){}
	ResponseCommand* CreateResponse()const
    {
        // ATLASSERT(false);
        return 0;
    }
	const string& GetCurrency(){return currency;}
	uint32_t GetAmount(){return amount;}
	uint32_t GetFinCommand(){return fin_cmd;}
};

class HostResponseCommand : public RequestCommand{
protected:
	string currency;
	uint32_t amount;
	int status;
	uint32_t fin_cmd;

public:
	HostResponseCommand(uint32_t command, uint32_t aFin_cmd, const string& aCurrency, uint32_t aAmount, int aStatus = EFT_PP_STATUS_SUCCESS);

	//Command
	bool isResponse()
    {
        return true;
    }
    
	ResponseCommand* CreateResponse()const;
};

class ConnectRequestCommand : public HostRequestCommand{
public:
	ConnectRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd);
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processConnect:this];
    }
};

class SendRequestCommand : public HostRequestCommand{
public:
	SendRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd);
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processSend:this];
    }
};

class ReceiveRequestCommand : public HostRequestCommand{
public:
	ReceiveRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd);
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processReceive:this];
    }
};

class DisconnectRequestCommand : public HostRequestCommand{
public:
	DisconnectRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aFin_cmd);
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processDisconnect:this];
    }
};

class SignatureRequestCommand : public RequestCommand, public IRequestProcess{
	string receipt;
    string xml_details;
	string currency;
	uint32_t amount;
	uint32_t type;

public:
	SignatureRequestCommand(const string& aCurrency, uint32_t aAmount, uint32_t aType);
	const string& GetReceipt(){return receipt;}
    const string& GetXmlDetails(){return xml_details;}
	const string& GetCurrency(){return currency;}
	uint32_t GetAmount(){return amount;}
	uint32_t GetFinCommand(){return type;}

	//IRequestProcess
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processSignature:this];
    }
    
	ResponseCommand* CreateResponse() const
    {
        // ATLASSERT(false);
        
        return 0;
    }
};

class SetLogLevelRequestCommand : public RequestCommand{
public:
	SetLogLevelRequestCommand(uint8_t log_level);
};

class ResetLogInfoRequestCommand : public RequestCommand{
public:
	ResetLogInfoRequestCommand();
};

class GetLogInfoRequestCommand : public RequestCommand{
public:
	GetLogInfoRequestCommand();
	ResponseCommand* CreateResponse()const;
};
