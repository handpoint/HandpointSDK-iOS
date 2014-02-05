#pragma once
#include "Command.h"
#include "CmdIds.h"

class ResponseCommand;

class RequestCommand : public Command{
protected:
	UINT32 m_cmd;

	RequestCommand(UINT32 cmd) : m_cmd(cmd){}

public:
	//Command
	bool isResponse(){return false;}
	virtual ResponseCommand* CreateResponse()const;

	UINT32 GetType()const{return m_cmd;}
};

class FinanceRequestCommand : public RequestCommand{
	string currency;
	UINT32 amount;

protected:
	enum eState{eWaitingCard, eCardInserted, eAppSelect, ePinInput, eConnect};
	mutable int state;

public:
	FinanceRequestCommand(UINT32 type, const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id, const string& xml);
	UINT32 GetAmount()const{return amount;}
	const string& GetCurrency()const{return currency;}
	ResponseCommand* CreateResponse()const;
	ResponseCommand* CreateResponseOnCancel()const;
};

class XMLCommandRequestCommand : public RequestCommand{
protected:
    /**/
public:
	XMLCommandRequestCommand(const string& xml);
};
/*class SaleRequestCommand : public FinanceRequestCommand{
public:
	SaleRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present);
};

class RefundRequestCommand : public FinanceRequestCommand{
public:
	RefundRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present);
	ResponseCommand* CreateResponse()const;
};

class FinanceVRequestCommand : public FinanceRequestCommand{
	string transaction_id;
public:
	FinanceVRequestCommand(UINT32 type, const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id);
	ResponseCommand* CreateResponse()const;
};

class SaleVRequestCommand : public FinanceVRequestCommand{
public:
	SaleVRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id);
};

class RefundVRequestCommand : public FinanceVRequestCommand{
public:
	RefundVRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id);
};*/

class StartOfDayRequestCommand : public RequestCommand{
public:
	StartOfDayRequestCommand();
};

class EndOfDayRequestCommand : public RequestCommand{
public:
	EndOfDayRequestCommand();
};

class FinanceInitRequestCommand : public RequestCommand{
public:
	FinanceInitRequestCommand();
};

#include "../../Shared/IHostProcessor.h"

class HostRequestCommand : public RequestCommand, public IRequestProcess{
protected:
	string currency;
	UINT32 amount;
	UINT32 fin_cmd;

public:
	HostRequestCommand(UINT32 cmd, const string& aCurrency, UINT32 aAmount, UINT32 aFin_cmd) : RequestCommand(cmd), currency(aCurrency), amount(aAmount), fin_cmd(aFin_cmd){}
	ResponseCommand* CreateResponse()const{ATLASSERT(false);return 0;}
	const string& GetCurrency(){return currency;}
	UINT32 GetAmount(){return amount;}
	UINT32 GetFinCommand(){return fin_cmd;}
};

class HostResponseCommand : public RequestCommand{
protected:
	string currency;
	UINT32 amount;
	int status;
	UINT32 fin_cmd;

public:
	HostResponseCommand(UINT32 command, UINT32 aFin_cmd, const string& aCurrency, UINT32 aAmount, int aStatus = EFT_PP_STATUS_SUCCESS);

	//Command
	bool isResponse(){return true;}
	ResponseCommand* CreateResponse()const;
};

class ConnectRequestCommand : public HostRequestCommand{
public:
	ConnectRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aFin_cmd);
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processConnect:this];}
};

class SendRequestCommand : public HostRequestCommand{
public:
	SendRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aFin_cmd);
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processSend:this];}
};

class ReceiveRequestCommand : public HostRequestCommand{
public:
	ReceiveRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aFin_cmd);
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processReceive:this];}
};

class DisconnectRequestCommand : public HostRequestCommand{
public:
	DisconnectRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aFin_cmd);
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processDisconnect:this];}
};

class SignatureRequestCommand : public RequestCommand, public IRequestProcess{
	string receipt;
	string currency;
	UINT32 amount;
	UINT32 type;

public:
	SignatureRequestCommand(const string& aCurrency, UINT32 aAmount, UINT32 aType);
	const string& GetReceipt(){return receipt;}
	const string& GetCurrency(){return currency;}
	UINT32 GetAmount(){return amount;}
	UINT32 GetFinCommand(){return type;}

	//IRequestProcess
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processSignature:this];}
	ResponseCommand* CreateResponse()const{ATLASSERT(false);return 0;}
};

/*class DebugEnableRequestCommand : public RequestCommand{
public:
	DebugEnableRequestCommand();
};

class DebugDisableRequestCommand : public RequestCommand{
public:
	DebugDisableRequestCommand();
};

class DebugResetRequestCommand : public RequestCommand{
public:
	DebugResetRequestCommand();
};

class DebugInfoRequestCommand : public RequestCommand{
public:
	DebugInfoRequestCommand();
	ResponseCommand* CreateResponse()const;
};*/

class SetLogLevelRequestCommand : public RequestCommand{
public:
	SetLogLevelRequestCommand(UINT8 log_level);
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
