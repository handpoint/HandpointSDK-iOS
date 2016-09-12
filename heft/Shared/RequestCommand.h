#pragma once
#include "Command.h"

#include <vector>
#include <string>
#include <cstdint>

#include "atl.h"

class RequestCommand : public Command
{
	static const int ciMinSize = Command::ciMinSize + 6;

protected:
    std::vector<std::uint8_t> data;

	struct RequestPayload : CommandPayload
    {
		std::uint8_t length[6];
	} __attribute__((packed));

	RequestCommand(int iCommandSize, uint32_t type);
	RequestCommand(const void* payload, uint32_t payloadSize);
	RequestCommand(){}

    template<class T> T* GetPayload()
    {
        return reinterpret_cast<T*>(&data[0]);
    }
    
    template<class T> void FormatLength(int length)
    {
		int32_t len_msb = htonl(length);
		T* pRequest = GetPayload<T>();
		int dest_len = sizeof(pRequest->length) + 1;
		AtlHexEncode(reinterpret_cast<const std::uint8_t*>(&len_msb) + 1,
                     static_cast<int>(sizeof(len_msb) - 1),
                     reinterpret_cast<char*>(pRequest->length),
                     &dest_len);
	}
    
	int ReadLength(const RequestPayload* pRequest);

public:
	//Command
	bool isResponse()
    {
        return false;
    }

	int GetLength() const
    {
        return (int)data.size();
    }
	
    const std::uint8_t* GetData() const
    {
        return &data[0];
    }
#ifdef HEFT_EXPORTS
	CString dump(const CString& prefix)const{return ::dump(prefix, &data[0], data.size());}
#endif
};

class InitRequestCommand : public RequestCommand
{
	static const int ciMinSize = 7;
protected:
	struct InitPayload : RequestPayload {
		std::uint8_t data[InitRequestCommand::ciMinSize];
        std::uint32_t xml_size;
        std::uint8_t xml[];
	} __attribute__((packed));

public:
    InitRequestCommand(int bufferSize = 0, NSString* version = nil);
};

class IdleRequestCommand : public RequestCommand
{
	static const int ciMinSize = 0;
public:
	IdleRequestCommand();
};

class XMLCommandRequestCommand : public RequestCommand
{
protected:
	struct XMLCommandPayload : RequestPayload{
		char xml_parameters[];
	} __attribute__((packed));

public:
	XMLCommandRequestCommand(const std::string& xml);
};

class FinanceRequestCommand : public RequestCommand{
	static const int ciMinSize = 7; // customer reference field not included for it will not appear if it is empty ( support older EFT versions)
protected:
	struct FinancePayload : RequestPayload{
		std::uint8_t currency_code[2];
        std::uint32_t trans_amount;
		std::uint8_t card_present;
		std::uint8_t trans_id_length; // must be set to zero if xml exists and there is no trans_id
		std::uint8_t trans_id[];
		// uint32_t_t xml_length;
		// std::uint8_t xml[];
	} __attribute__((packed));

public:
    FinanceRequestCommand(std::uint32_t type, const std::string& currency_code, std::uint32_t trans_amount, std::uint8_t card_present, const std::string& trans_id, const std::string& xml);
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
    HostRequestCommand(const void* payload, std::uint32_t payloadSize);
    static HostRequestCommand* Create(const void* payload, std::uint32_t payloadSize);
};

class HostResponseCommand : public RequestCommand{
	static const int ciMinSize = 4;

protected:
	struct HostResponsePayload : CommandPayload{
        std::uint32_t status;
		std::uint8_t length[6];
	} __attribute__((packed));

	void WriteStatus(std::uint16_t status);

public:
    HostResponseCommand(std::uint32_t command, int status, int cmd_size = 0);

	//Command
	bool isResponse()
    {
        return true;
    }
};

class ConnectRequestCommand : public HostRequestCommand{
	std::string remote_address;
	std::uint16_t port;
	std::uint16_t timeout;

protected:
	struct ConnectPayload : RequestPayload{
		std::uint8_t remote_add_length;
		std::uint8_t remote_add[];
	} __attribute__((packed));

public:
    ConnectRequestCommand(const void* payload, std::uint32_t payloadSize);
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processConnect:this];
    }
	
    const std::string& GetAddr()
    {
        return remote_address;
    }
	
    int GetPort()
    {
        return port;
    }
	int GetTimeout()
    {
        return timeout;
    }
};

class SendRequestCommand : public HostRequestCommand{
	std::uint16_t timeout;

protected:
	struct SendPayload : RequestPayload{
		std::uint16_t timeout;
		std::uint16_t data_len;
		std::uint8_t data[];
	} __attribute__((packed));

public:
    SendRequestCommand(const void* payload, std::uint32_t payloadSize);
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processSend:this];
    }
	
    int GetTimeout(){
        return timeout;
    }
};

class PostRequestCommand : public HostRequestCommand
{
    std::uint16_t port;
    std::uint16_t timeout;
    NSString*     host;
//    NSString*     path;
    NSData*       post_data;
    
protected:
    struct PostPayload : RequestPayload{
        std::uint16_t port;
        std::uint16_t timeout;
        std::uint8_t  host_address_length;
//        std::uint8_t  path_length;
        std::uint16_t data_len;
        std::uint8_t  data[];  // [host[n]path[m]data[r]
    } __attribute__((packed));
    
public:
    PostRequestCommand(const void* payload, std::uint32_t payloadSize);
    RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processPost:this];
    }
    
    NSNumber* get_port()
    {
        return [NSNumber numberWithShort:port];
    }
    
    int GetTimeout()
    {
        return timeout;
    }
    
    NSString* get_host()
    {
        return host;
    }
  
    /*
    NSString* get_path()
    {
        return path;
    }
    */
    
    NSData* get_data()
    {
        return post_data;
    }
};


class ReceiveRequestCommand : public HostRequestCommand{
	std::uint16_t data_len;
	std::uint16_t timeout;

protected:
	struct ReceivePayload : RequestPayload{
		std::uint16_t data_len;
		std::uint16_t timeout;
	} __attribute__((packed));

public:
    ReceiveRequestCommand(const void* payload, std::uint32_t payloadSize);
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processReceive:this];
    }
    
	int GetTimeout()
    {
        return timeout;
    }
    
	std::uint16_t GetDataLen()
    {
        return data_len;
    }
};

class ReceiveResponseCommand : public HostResponseCommand{
	static const int ciMinSize = 4;
	struct ReceiveResponsePayload : HostResponsePayload{
        std::uint32_t data_len;
		std::uint8_t data[];
	} __attribute__((packed));

public:
    ReceiveResponseCommand(const std::vector<std::uint8_t>& payload);
	ReceiveResponseCommand(NSData* payload);
};

class DisconnectRequestCommand : public HostRequestCommand{
public:
    DisconnectRequestCommand(const void* payload, std::uint32_t payloadSize);
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processDisconnect:this];
    }
};

class SignatureRequestCommand : public RequestCommand, public IRequestProcess{
	std::string receipt;
	std::string xml_details;

protected:
	struct SignatureRequestPayload : RequestPayload{
		std::uint16_t receipt_length;
		char receipt[];
	} __attribute__((packed));

public:
    SignatureRequestCommand(const void* payload, std::uint32_t payloadSize);
    const std::string& GetReceipt()
    {
        return receipt;
    }
    
    const std::string& GetXmlDetails()
    {
        return xml_details;
    }

	//IRequestProcess
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processSignature:this];
    }
};

class ChallengeRequestCommand : public RequestCommand, public IRequestProcess{
    std::vector<std::uint8_t> random_num;
	std::string xml_details;

protected:
	struct ChallengeRequestPayload : RequestPayload{
		std::uint16_t random_num_length;
		std::uint8_t random_num[];
	} __attribute__((packed));

public:
    ChallengeRequestCommand(const void* payload, std::uint32_t payloadSize);
	const std::vector<std::uint8_t>& GetRandomNum()
    {
        return random_num;
    }
	
    const std::string& GetXmlDetails()
    {
        return xml_details;
    }

	//IRequestProcess
	RequestCommand* Process(id<IHostProcessor> handler)
    {
        return [handler processChallenge:this];
    }
};

class ChallengeResponseCommand : public HostResponseCommand{
	static const int ciMinSize = 4;
	struct ChallengeResponsePayload : HostResponsePayload{
		std::uint16_t mx_len;
		std::uint8_t mx[];
	} __attribute__((packed));

public:
	ChallengeResponseCommand(const std::vector<std::uint8_t>& mx, const std::vector<std::uint8_t>& zx);
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
};*/

class SetLogLevelRequestCommand : public RequestCommand{
	static const int ciMinSize = 1;
protected:
	struct SetLogLevelPayload : RequestPayload{
		std::uint8_t log_level;
	} __attribute__((packed));

public:
	SetLogLevelRequestCommand(std::uint8_t log_level);
};

class ResetLogInfoRequestCommand : public RequestCommand{
public:
	ResetLogInfoRequestCommand();
};

class GetLogInfoRequestCommand : public RequestCommand{
public:
	GetLogInfoRequestCommand();
};
