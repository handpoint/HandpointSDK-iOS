#pragma once
#include "Command.h"

class RequestCommand : public Command{
	static const int ciMinSize = Command::ciMinSize + 6;

protected:
	vector<UINT8> data;

	struct RequestPayload : CommandPayload{
		UINT8 length[6];
	} __attribute__((packed));

	RequestCommand(int iCommandSize, UINT32 type);
	RequestCommand(){}
	template<class T>
	T* GetPayload(){return reinterpret_cast<T*>(&data[0]);}
	template<class T>
	void FormatLength(int length){
		INT32 len_msb = htonl(length);
		T* pRequest = GetPayload<T>();
		int dest_len = sizeof(pRequest->length) + 1;
		AtlHexEncode(reinterpret_cast<UINT8*>(&len_msb) + 1, sizeof(len_msb) - 1, reinterpret_cast<LPSTR>(pRequest->length), &dest_len);
	}

public:
	//Command
	bool isResponse(){return false;}

	int GetLength()const{return data.size();}
	const UINT8* GetData()const{return &data[0];}
#ifdef HEFT_EXPORTS
	CString dump(const CString& prefix)const{return ::dump(prefix, &data[0], data.size());}
#endif
};

class InitRequestCommand : public RequestCommand{
	static const int ciMinSize = 7;
protected:
	struct InitPayload : RequestPayload{
		UINT8 data[InitRequestCommand::ciMinSize];
	} __attribute__((packed));

public:
	InitRequestCommand();
};

class IdleRequestCommand : public RequestCommand{
	static const int ciMinSize = 0;
public:
	IdleRequestCommand();
};

class FinanceRequestCommand : public RequestCommand{
	static const int ciMinSize = 7;
protected:
	struct FinancePayload : RequestPayload{
		UINT8 currency_code[2];
		UINT32 trans_amount;
		UINT8 card_present;
	} __attribute__((packed));

public:
	FinanceRequestCommand(int iCommandSize, UINT32 type, const string& currency_code, UINT32 trans_amount, UINT8 card_present);
};

class SaleRequestCommand : public FinanceRequestCommand{
	static const int ciMinSize = 0;
public:
	SaleRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present);
};

class RefundRequestCommand : public FinanceRequestCommand{
	static const int ciMinSize = 0;
public:
	RefundRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present);
};

class FinanceVRequestCommand : public FinanceRequestCommand{
	static const int ciMinSize = 1;
protected:
	struct FinanceVPayload : FinancePayload{
		UINT8 trans_id_length;
		UINT8 trans_id[];
	} __attribute__((packed));

public:
	FinanceVRequestCommand(UINT32 type, const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id);
};

class SaleVRequestCommand : public FinanceVRequestCommand{
public:
	SaleVRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id);
};

class RefundVRequestCommand : public FinanceVRequestCommand{
public:
	RefundVRequestCommand(const string& currency_code, UINT32 trans_amount, UINT8 card_present, const string& trans_id);
};

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

#include "IHostProcessor.h"

class HostRequestCommand : public RequestCommand, public IRequestProcess{
public:
	static HostRequestCommand* Create(const void* payload);
};

class HostResponseCommand : public RequestCommand{
	static const int ciMinSize = 4;

protected:
	struct HostResponsePayload : CommandPayload{
		UINT32 status;
		UINT8 length[6];
	} __attribute__((packed));

	void WriteStatus(UINT16 status);

public:
	HostResponseCommand(UINT32 command, int status, int cmd_size = 0);

	//Command
	bool isResponse(){return true;}
};

class ConnectRequestCommand : public HostRequestCommand{
	string remote_add;
	UINT16 port;
	UINT16 timeout;

protected:
	struct ConnectPayload : RequestPayload{
		UINT8 remote_add_length;
		UINT8 remote_add[];
	} __attribute__((packed));

public:
	ConnectRequestCommand(const void* payload);
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processConnect:this];}
	const string& GetAddr(){return remote_add;}
	int GetPort(){return port;}
	int GetTimeout(){return timeout;}
};

class SendRequestCommand : public HostRequestCommand{
	UINT16 timeout;

protected:
	struct SendPayload : RequestPayload{
		UINT16 timeout;
		UINT16 data_len;
		UINT8 data[];
	} __attribute__((packed));

public:
	SendRequestCommand(const void* payload);
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processSend:this];}
	int GetTimeout(){return timeout;}
};

class ReceiveRequestCommand : public HostRequestCommand{
	UINT16 data_len;
	UINT16 timeout;

protected:
	struct ReceivePayload : RequestPayload{
		UINT16 data_len;
		UINT16 timeout;
	} __attribute__((packed));

public:
	ReceiveRequestCommand(const void* payload);
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processReceive:this];}
	int GetTimeout(){return timeout;}
	UINT16 GetDataLen(){return data_len;}
};

class ReceiveResponseCommand : public HostResponseCommand{
	static const int ciMinSize = 4;
	struct ReceiveResponsePayload : HostResponsePayload{
		UINT32 data_len;
		UINT8 data[];
	} __attribute__((packed));

public:
	ReceiveResponseCommand(const vector<UINT8>& payload);
};

class DisconnectRequestCommand : public HostRequestCommand{
public:
	DisconnectRequestCommand(const void* payload);
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processDisconnect:this];}
};

class SignatureRequestCommand : public RequestCommand, public IRequestProcess{
	string receipt;
	string xml_details;

protected:
	struct SignatureRequestPayload : RequestPayload{
		UINT16 receipt_length;
		char receipt[];
	} __attribute__((packed));

public:
	SignatureRequestCommand(const void* payload);
	const string& GetReceipt(){return receipt;}
	const string& GetXmlDetails(){return xml_details;}

	//IRequestProcess
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processSignature:this];}
};

class ChallengeRequestCommand : public RequestCommand, public IRequestProcess{
	vector<UINT8> random_num;
	string xml_details;

protected:
	struct ChallengeRequestPayload : RequestPayload{
		UINT16 random_num_length;
		UINT8 random_num[];
	} __attribute__((packed));

public:
	ChallengeRequestCommand(const void* payload);
	const vector<UINT8>& GetRandomNum(){return random_num;}
	const string& GetXmlDetails(){return xml_details;}

	//IRequestProcess
	RequestCommand* Process(id<IHostProcessor> handler){return [handler processChallenge:this];}
};

class ChallengeResponseCommand : public HostResponseCommand{
	static const int ciMinSize = 4;
	struct ChallengeResponsePayload : HostResponsePayload{
		UINT16 mx_len;
		UINT8 mx[];
	} __attribute__((packed));

public:
	ChallengeResponseCommand(const vector<UINT8>& mx, const vector<UINT8>& zx);
};

class DebugEnableRequestCommand : public RequestCommand{
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
};

class SetLogLevelRequestCommand : public RequestCommand{
	static const int ciMinSize = 1;
protected:
	struct SetLogLevelPayload : RequestPayload{
		UINT8 log_level;
	} __attribute__((packed));

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
};
