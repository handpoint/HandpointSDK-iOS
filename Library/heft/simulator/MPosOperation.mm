//
//  MPosOperation.m
//  headstart
//

#ifdef HEFT_SIMULATOR

#import "MPosOperation.h"
#import "Shared/RequestCommand.h"
#import "Shared/ResponseCommand.h"
#include "debug.h"
#include "Logger.h"
#include "Exception.h"

void simulateDeviceDisconnect();

@implementation MPosOperation{
	RequestCommand*	pRequestCommand;
	__weak id<IResponseProcessor> processor;
}

- (id)initWithRequest:(RequestCommand *)aRequest
		   connection:(HeftConnection *)aConnection
	 resultsProcessor:(id <IResponseProcessor>)aProcessor
		 sharedSecret:(NSString *)aSharedSecret{
	if(self = [super init]){
		LOG(@"Operation started");
		pRequestCommand = aRequest;
		processor = aProcessor;
	}
	return self;
}

- (void)dealloc{
	LOG(@"Operation ended");
	delete pRequestCommand;
}

- (void)main{
	@autoreleasepool {
		try{
			RequestCommand* currentRequest = pRequestCommand;
			
			while(true){
				//LOG_RELEASE(Logger:eFiner, @"Outgoing message");
                std::unique_ptr<ResponseCommand> pResponse;
				while(true){
					pResponse.reset([self isCancelled] ? pRequestCommand->CreateResponseOnCancel() : currentRequest->CreateResponse());
					
					if(pRequestCommand != currentRequest){
						delete currentRequest;
						currentRequest = 0;
					}
					
					if(pResponse->isResponse()){
						pResponse->ProcessResult(processor);
						if(pResponse->isResponseTo(*pRequestCommand)){
							LOG_RELEASE(Logger::eInfo, @"Current operation completed.");
							return;
						}
						continue;
					}
					
					break;
				}
				
                // TODO: this has to be refactored - dynamic and reinterpret casts!
                // and why is it needed? Can't we call Process on pResponse?
                // oh the humanity!
                LOG_RELEASE(Logger::eInfo, @"HostRequest about to be processed.");
                
				IRequestProcess* pHostRequest = dynamic_cast<IRequestProcess*>(
                    reinterpret_cast<RequestCommand*>(pResponse.get())
                );
				// ATLASSERT(pHostRequest);
                assert(pHostRequest);
				currentRequest = pHostRequest->Process(self);
			}
		}
		catch(heft_exception& exception){
			[processor sendResponseError:exception.stringId()];
            simulateDeviceDisconnect();
		}
	}
}

#pragma mark IHostProcessor

- (RequestCommand*)processConnect:(ConnectRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, @"State of financial transaction changed: connecting to bureau");

    EventInfoResponseCommand responseCommand(EFT_PP_STATUS_CONNECTING, false);
    responseCommand.ProcessResult(processor);
	
	return new HostResponseCommand(EFT_PACKET_HOST_CONNECT_RESP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processSend:(SendRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, @"Request to bureau (length:?):");

    EventInfoResponseCommand spStatus(EFT_PP_STATUS_SENDING, false);
    spStatus.ProcessResult(processor);

	return new HostResponseCommand(EFT_PACKET_HOST_SEND_RESP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest{
	LOG(@"Recv :? bytes, ?s timeout");

    
    EventInfoResponseCommand spStatus(EFT_PP_STATUS_RECEIVEING, false);
    spStatus.ProcessResult(processor);
	
	return new HostResponseCommand(EFT_PACKET_HOST_RECEIVE_RESP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processDisconnect:(DisconnectRequestCommand*)pRequest{
    EventInfoResponseCommand spStatus(EFT_PP_STATUS_DISCONNECTING, false);
    spStatus.ProcessResult(processor);
	
	LOG_RELEASE(Logger::eFine, @"State of financial transaction changed: disconnected");
	return new HostResponseCommand(EFT_PACKET_HOST_DISCONNECT_RESP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processSignature:(SignatureRequestCommand*)pRequest{
	LOG(@"Signature required request");
	int status = [processor processSign:pRequest];
	return new HostResponseCommand(EFT_PACKET_SIGNATURE_REQ_RESP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount(), status);
}

- (RequestCommand*)processChallenge:(ChallengeRequestCommand*)pRequest{
	// ATLASSERT(0);
    assert(0);
	return 0;
}

@end

#endif
