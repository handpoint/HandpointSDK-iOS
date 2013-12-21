//
//  MPosOperation.m
//  headstart
//

#import "MPosOperation.h"

#import "StdAfx.h"
#import "Shared/RequestCommand.h"
#import "Shared/ResponseCommand.h"
#include "HeftCmdIds.h"

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
				
				auto_ptr<ResponseCommand> pResponse;
				while(true){
					pResponse.reset([self isCancelled] ? static_cast<FinanceRequestCommand*>(pRequestCommand)->CreateResponseOnCancel() : currentRequest->CreateResponse());
					
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
				
				IRequestProcess* pHostRequest = dynamic_cast<IRequestProcess*>(reinterpret_cast<RequestCommand*>(pResponse.get()));
				ATLASSERT(pHostRequest);
				currentRequest = pHostRequest->Process(self);
			}
		}
		catch(heft_exception& exception){
			[processor sendResponseError:exception.stringId()];
		}
	}
}

#pragma mark IHostProcessor

- (RequestCommand*)processConnect:(ConnectRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: connecting to bureau"));

	auto_ptr<EventInfoResponseCommand> spStatus(new EventInfoResponseCommand(EFT_PP_STATUS_CONNECTING));
	spStatus->ProcessResult(processor);
	
	return new HostResponseCommand(CMD_HOST_CONN_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processSend:(SendRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, _T("Request to bureau (length:?):"));
	
	auto_ptr<EventInfoResponseCommand> spStatus(new EventInfoResponseCommand(EFT_PP_STATUS_SENDING));
	spStatus->ProcessResult(processor);

	return new HostResponseCommand(CMD_HOST_SEND_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest{
	LOG(_T("Recv :? bytes, ?s timeout"));
	
	auto_ptr<EventInfoResponseCommand> spStatus(new EventInfoResponseCommand(EFT_PP_STATUS_RECEIVEING));
	spStatus->ProcessResult(processor);
	
	return new HostResponseCommand(CMD_HOST_RECV_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processDisconnect:(DisconnectRequestCommand*)pRequest{
	auto_ptr<EventInfoResponseCommand> spStatus(new EventInfoResponseCommand(EFT_PP_STATUS_DISCONNECTING));
	spStatus->ProcessResult(processor);
	
	LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: disconnected"));
	return new HostResponseCommand(CMD_HOST_DISC_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount());
}

- (RequestCommand*)processSignature:(SignatureRequestCommand*)pRequest{
	LOG(_T("Signature required request"));
	int status = [processor processSign:@(pRequest->GetReceipt().c_str())];
	return new HostResponseCommand(CMD_STAT_SIGN_RSP, pRequest->GetFinCommand(), pRequest->GetCurrency(), pRequest->GetAmount(), status);
}

- (RequestCommand*)processChallenge:(ChallengeRequestCommand*)pRequest{
	ATLASSERT(0);
	return 0;
}

@end