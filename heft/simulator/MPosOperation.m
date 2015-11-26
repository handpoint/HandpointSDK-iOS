//
//  MPosOperation.m
//  headstart
//

#ifdef HEFT_SIMULATOR

#import "MPosOperation.h"
#import "Shared/RequestCommand.h"
#import "Shared/ResponseCommand.h"
#include "HeftCmdIds.h"

void simulateDeviceDisconnect();

@implementation MPosOperation{
	RequestCommand*	pRequestCommand;
	__weak id<IResponseProcessor> processor;
}

- (id)initWithRequest:(RequestCommand*)aRequest connection:(HeftConnection*)aConnection resultsProcessor:(id<IResponseProcessor>)aProcessor sharedSecret:(NSData*)aSharedSecret{
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
				
                // auto_ptr<ResponseCommand> pResponse;
                // TODO: refactor this code, use a shared_ptr everywere instead of raw pointers.
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
							LOG_RELEASE(Logger::eInfo, _T("Current operation completed."));
							return;
						}
						continue;
					}
					
					break;
				}
				
                // TODO: this has to be refactored - dynamic and reinterpret casts!
                // and why is it needed? Can't we call Process on pResponse?
                // oh the humanity!
				IRequestProcess* pHostRequest = dynamic_cast<IRequestProcess*>(reinterpret_cast<RequestCommand*>(pResponse.get()));
				ATLASSERT(pHostRequest);
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
	LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: connecting to bureau"));

    /*
	auto_ptr<EventInfoResponseCommand> spStatus(new EventInfoResponseCommand(EFT_PP_STATUS_CONNECTING, false));
	spStatus->ProcessResult(processor);
     */
    EventInfoResponseCommand responseCommand(EFT_PP_STATUS_CONNECTING, false);
    responseCommand.ProcessResult(processor);
	
	return new HostResponseCommand(CMD_HOST_CONN_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processSend:(SendRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, _T("Request to bureau (length:?):"));

    /*
	auto_ptr<EventInfoResponseCommand> spStatus(new EventInfoResponseCommand(EFT_PP_STATUS_SENDING, false));
	spStatus->ProcessResult(processor);
     */
    EventInfoResponseCommand spStatus(EFT_PP_STATUS_SENDING, false);
    spStatus.ProcessResult(processor);

	return new HostResponseCommand(CMD_HOST_SEND_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest{
	LOG(_T("Recv :? bytes, ?s timeout"));

    /*
	auto_ptr<EventInfoResponseCommand> spStatus(new EventInfoResponseCommand(EFT_PP_STATUS_RECEIVEING, false));
	spStatus->ProcessResult(processor);
     */
    
    EventInfoResponseCommand spStatus(EFT_PP_STATUS_RECEIVEING, false);
    spStatus.ProcessResult(processor);
	
	return new HostResponseCommand(CMD_HOST_RECV_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processDisconnect:(DisconnectRequestCommand*)pRequest{
    /*
	auto_ptr<EventInfoResponseCommand> spStatus(new EventInfoResponseCommand(EFT_PP_STATUS_DISCONNECTING, false));
	spStatus->ProcessResult(processor);
     */
    EventInfoResponseCommand spStatus(EFT_PP_STATUS_DISCONNECTING, false);
    spStatus.ProcessResult(processor);
	
	LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: disconnected"));
	return new HostResponseCommand(CMD_HOST_DISC_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processSignature:(SignatureRequestCommand*)pRequest{
	LOG(_T("Signature required request"));
	int status = [processor processSign:pRequest];
	return new HostResponseCommand(CMD_STAT_SIGN_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount(), status);
}

- (RequestCommand*)processChallenge:(ChallengeRequestCommand*)pRequest{
	ATLASSERT(0);
	return 0;
}

@end

#endif
