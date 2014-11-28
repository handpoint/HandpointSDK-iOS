//
//  FinanceTransactionOperation.m
//  headstart
//

#import "StdAfx.h"
#import "FrameManager.h"
#import "Frame.h"
#import "Shared/RequestCommand.h"
#import "Shared/ResponseCommand.h"

#import "MPosOperation.h"
#import "HeftConnection.h"

#import <CommonCrypto/CommonHMAC.h>

enum eConnectCondition{
	eNoConnectStateCondition
	, eReadyStateCondition
};

@interface MPosOperation()<NSStreamDelegate>
@end

@implementation MPosOperation{
	RequestCommand*	pRequestCommand;
	HeftConnection* connection;
	//int maxFrameSize;
	__weak id<IResponseProcessor> processor;
	NSData* sharedSecret;
	NSOutputStream* sendStream;
	NSInputStream* recvStream;
	NSConditionLock* connectLock;
}

- (id)initWithRequest:(RequestCommand*)aRequest connection:(HeftConnection*)aConnection resultsProcessor:(id<IResponseProcessor>)aProcessor sharedSecret:(NSData*)aSharedSecret{
	if(self = [super init]){
		LOG(@"mPos Operation started.");
		pRequestCommand = aRequest;
		connection = aConnection;
		//maxFrameSize = frameSize;
		processor = aProcessor;
		sharedSecret = aSharedSecret;
		connectLock = [[NSConditionLock alloc] initWithCondition:eNoConnectStateCondition];
	}
	return self;
}

- (void)dealloc{
	LOG(@"mPos Operation ended.");
	delete pRequestCommand;
}

- (void)main{
	@autoreleasepool {
		try{
			RequestCommand* currentRequest = pRequestCommand;
			[connection resetData];
			
			while(true){
				//LOG_RELEASE(Logger:eFiner, currentRequest->dump(@"Outgoing message")));
				FrameManager fm(*currentRequest, connection.maxFrameSize);
				fm.Write(connection);
				
				if(pRequestCommand != currentRequest){
					delete currentRequest;
					currentRequest = 0;
				}
				
				auto_ptr<ResponseCommand> pResponse;
				while(true){
					pResponse.reset(fm.ReadResponse<ResponseCommand>(connection, true));
					
					if(pResponse->isResponse()){
						pResponse->ProcessResult(processor);
						if(pResponse->isResponseTo(*pRequestCommand)){
							LOG_RELEASE(Logger::eInfo, _T("Current mPos operation completed."));
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

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
	[aStream setDelegate:nil];
	Assert(eventCode == NSStreamEventOpenCompleted || eventCode == NSStreamEventErrorOccurred);
	[connectLock lock];
	[connectLock unlockWithCondition:eReadyStateCondition];
}

- (RequestCommand*)processConnect:(ConnectRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: connecting to bureau %s:%d timeout:%d"), pRequest->GetAddr().c_str(), pRequest->GetPort(), pRequest->GetTimeout());

	NSString* host = @(pRequest->GetAddr().c_str());
	CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)host, pRequest->GetPort(), &readStream, &writeStream);
	recvStream = (NSInputStream*)CFBridgingRelease(readStream);
	sendStream = (NSOutputStream*)CFBridgingRelease(writeStream);

	[recvStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
	//[sendStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
	[recvStream setDelegate:self];
	NSRunLoop* mainRunLoop = [NSRunLoop mainRunLoop];
	[recvStream scheduleInRunLoop:mainRunLoop forMode:NSDefaultRunLoopMode];
	//[sendStream scheduleInRunLoop:mainRunLoop forMode:NSDefaultRunLoopMode];
	[recvStream open];
	[sendStream open];

	int status = EFT_PP_STATUS_SUCCESS;
	if(sendStream && recvStream){
		if([connectLock lockWhenCondition:eReadyStateCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:pRequest->GetTimeout()]]){
			[connectLock unlockWithCondition:eNoConnectStateCondition];
			if(recvStream.streamStatus == NSStreamStatusOpen){
				LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: connected to bureau"));
			}
			else{
				LOG_RELEASE(Logger::eWarning, _T("Error connecting bureau."));
				status = EFT_PP_STATUS_CONNECT_ERROR;
			}
		}
		else{
			LOG_RELEASE(Logger::eWarning, _T("Error connecting bureau (timeout)."));
			status = EFT_PP_STATUS_CONNECT_TIMEOUT;
		}
	}
	else{
		LOG_RELEASE(Logger::eWarning, _T("Error connecting bureau."));
		status = EFT_PP_STATUS_CONNECT_ERROR;
	}

	return new HostResponseCommand(CMD_HOST_CONN_RSP, status);//kCFStreamPropertySSLSettings
}

- (RequestCommand*)processSend:(SendRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, _T("Request to bureau (length:%d): %@"), pRequest->GetLength(), [[NSString alloc] initWithBytes:pRequest->GetData() length:pRequest->GetLength() encoding:NSUTF8StringEncoding]);

	//while(![sendStream hasSpaceAvailable]);
	NSInteger nwrite = [sendStream write:pRequest->GetData() maxLength:pRequest->GetLength()];
	LOG(@"sent to server %d bytes", nwrite);

	if(nwrite != pRequest->GetLength()){
		LOG_RELEASE(Logger::eWarning, _T("Error sending bureau data"));
		return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SENDING_ERROR);
	}
	return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest{
	LOG(_T("Recv :%d bytes, %ds timeout"), pRequest->GetDataLen(), pRequest->GetTimeout());

	vector<UINT8> data;
	int stepSize = 4096;
	long nrecv = 0;
	//while([recvStream hasBytesAvailable]){
	do{
        vector<UINT8>::size_type old_size = data.size();
		data.resize(old_size + stepSize);
		nrecv = [recvStream read:&data[old_size] maxLength:stepSize];
		if(nrecv < 0)
			break;
		data.resize(old_size + nrecv);
	//}
	}while(nrecv);

	LOG_RELEASE(Logger::eFine, _T("Response from bureau (length:%d): "), data.size());
	return data.size() && nrecv >= 0 ? new ReceiveResponseCommand(data) : new HostResponseCommand(CMD_HOST_RECV_RSP, EFT_PP_STATUS_RECEIVING_ERROR);
}

- (RequestCommand*)processDisconnect:(DisconnectRequestCommand*)pRequest{
	[recvStream close];
	[sendStream close];
	recvStream = nil;
	sendStream = nil;
	LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: disconnected"));
	return new HostResponseCommand(CMD_HOST_DISC_RSP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand*)processSignature:(SignatureRequestCommand*)pRequest{
	LOG(_T("Signature required request"));
	int status = [processor processSign:@(pRequest->GetReceipt().c_str())];
	return new HostResponseCommand(CMD_STAT_SIGN_RSP, status);
}

- (RequestCommand*)processChallenge:(ChallengeRequestCommand*)pRequest{
	LOG(_T("Challenge required request"));

	CCHmacContext hmacContext;
	vector<uint8_t> mx([sharedSecret length]);
	vector<uint8_t> zx(mx.size());
	vector<uint8_t> msg(pRequest->GetRandomNum());

	SecRandomCopyBytes(kSecRandomDefault, mx.size(), &mx[0]);
	msg.resize(mx.size() * 2);
	memcpy(&msg[mx.size()], &mx[0], mx.size());

	CCHmacInit(&hmacContext, kCCHmacAlgSHA256, [sharedSecret bytes], [sharedSecret length]);
	CCHmacUpdate(&hmacContext, &msg[0], msg.size());
	CCHmacFinal(&hmacContext, &zx[0]);

	return new ChallengeResponseCommand(mx, zx);
}

@end
