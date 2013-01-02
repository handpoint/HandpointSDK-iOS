//
//  FinanceTransactionOperation.m
//  headstart
//

#import "FinanceTransactionOperation.h"
#import "HeftConnection.h"

#import <CommonCrypto/CommonHMAC.h>

#import "StdAfx.h"
#import "FrameManager.h"
#import "Frame.h"
#import "RequestCommand.h"
#import "ResponseCommand.h"

@implementation FinanceTransactionOperation

- (id)initWithRequest:(RequestCommand*)aRequest connection:(HeftConnection*)aConnection resultsProcessor:(id<IResponseProcessor>)aProcessor sharedSecret:(NSData*)aSharedSecret{
	if(self = [super init]){
		NSLog(@"FinanceTransactionOperation started");
		pRequestCommand = aRequest;
		connection = aConnection;
		//maxFrameSize = frameSize;
		processor = aProcessor;
		sharedSecret = aSharedSecret;
	}
	return self;
}

- (void)dealloc{
	NSLog(@"FinanceTransactionOperation ended");
	delete pRequestCommand;
}

- (void)main{
	@autoreleasepool {
		try{
			RequestCommand* currentRequest = pRequestCommand;
			connection.currentPosition = 0;
			
			while(true){
				//LOG_RELEASE(Logger:eFiner, currentRequest->dump(@"Outgoing message")));
				FrameManager fm(*currentRequest, connection.maxBufferSize);
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
							LOG_RELEASE(Logger::eInfo, _T("Current financial transaction completed."));
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
			[processor sendResponseInfo:exception.stringId() xml:nil];
		}
	}
}

#pragma mark IHostProcessor

- (RequestCommand*)processConnect:(ConnectRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: connecting to bureau %s:%d timeout:%d"), pRequest->GetAddr().c_str(), pRequest->GetPort(), pRequest->GetTimeout());
	NSString* host = [NSString stringWithUTF8String:pRequest->GetAddr().c_str()];
	CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)host, pRequest->GetPort(), &readStream, &writeStream);
	recvStream = (NSInputStream*)CFBridgingRelease(readStream);
	sendStream = (NSOutputStream*)CFBridgingRelease(writeStream);
	[recvStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
	[sendStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
	NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];
	[recvStream scheduleInRunLoop:currentRunLoop forMode:NSDefaultRunLoopMode];
	[sendStream scheduleInRunLoop:currentRunLoop forMode:NSDefaultRunLoopMode];
	[recvStream open];
	[sendStream open];
	return new HostResponseCommand(CMD_HOST_CONN_RSP, EFT_PP_STATUS_SUCCESS);//kCFStreamPropertySSLSettings
}

- (RequestCommand*)processSend:(SendRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, _T("Request to bureau (length:%d): %@"), pRequest->GetLength(), [[NSString alloc] initWithBytes:pRequest->GetData() length:pRequest->GetLength() encoding:NSUTF8StringEncoding]);
	while(![sendStream hasSpaceAvailable]);
	NSInteger nwrite = [sendStream write:pRequest->GetData() maxLength:pRequest->GetLength()];
	LOG(@"sent to server %d bytes", nwrite);
	Assert(nwrite);
	return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest{
	LOG(_T("Recv :%d bytes, %ds timeout"), pRequest->GetDataLen(), pRequest->GetTimeout());
	vector<UINT8> data;
	int stepSize = connection.maxBufferSize;
	int nrecv = 0;
	//while([recvStream hasBytesAvailable]){
	do{
		int old_size = data.size();
		data.resize(old_size + stepSize);
		nrecv = [recvStream read:&data[old_size] maxLength:stepSize];
		data.resize(old_size + nrecv);
	//}
	}while(nrecv);
	LOG_RELEASE(Logger::eFine, _T("Response from bureau (length:%d): "), data.size());
	return data.size() ? new ReceiveResponseCommand(data) : new HostResponseCommand(CMD_HOST_RECV_RSP, EFT_PP_STATUS_RECEIVEING_ERROR);
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
	int status = [processor processSign:[NSString stringWithUTF8String:pRequest->GetReceipt().c_str()]];
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