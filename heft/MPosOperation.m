//
//  FinanceTransactionOperation.m
//  headstart
//

#import "StdAfx.h"

#if !HEFT_SIMULATOR

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
    enum eConnectionState {
        eConnectionClosed,
        eConnectionConnecting,
        eConnectionConnected,
        eConnectionSending,
        eConnectionSendingComplete,
        eConnectionReceiving,
        eConnectionReceivingComplete,
    } connectionState;
    vector<UINT8> connectionSendData;
    vector<UINT8> connectionReceiveData;
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
        connectionState = eConnectionClosed;
        connectionSendData.clear();
        connectionReceiveData.clear();
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
                BOOL retry;
                BOOL already_cancelled = NO;
				while(true){
                    do{
                        retry = NO;
                        try {
                            pResponse.reset(fm.ReadResponse<ResponseCommand>(connection, true));
                        } catch (timeout4_exception& to4) {
                            // to be nice we will try to send a cancel to the card reader
                            retry = !already_cancelled ? [processor cancelIfPossible] : NO;
                            already_cancelled = retry;
                            if(!retry){
                                throw to4;
                            }
                        }
                    } while (retry);                    
					
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

- (void)cleanUpConnection{
    if(recvStream) {
        [recvStream close];
        [recvStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [recvStream setDelegate:nil];
        recvStream = nil;
    }
    if(sendStream) {
        [sendStream close];
        [sendStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [sendStream setDelegate:nil];
        sendStream = nil;
    }
    connectionState = eConnectionClosed;
}

#pragma mark IHostProcessor

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    LOG(@"stream:aStream handleEvent:%lu", (unsigned long)eventCode);

    if(eventCode & NSStreamEventErrorOccurred){
        // first remove us as the streams event handler so that we don't accidentally get more events
        [recvStream setDelegate:nil];
        [sendStream setDelegate:nil];
        
        [connectLock lock];
        connectionState = eConnectionClosed;
        [connectLock unlockWithCondition:eReadyStateCondition];
        return;
    }
    
    if(eventCode & NSStreamEventOpenCompleted){
        if(connectionState == eConnectionConnecting){
            [connectLock lock];
            connectionState = eConnectionConnected;
            [connectLock unlockWithCondition:eReadyStateCondition];
        }
    }
    
    if(eventCode & NSStreamEventHasBytesAvailable){
        if(aStream == recvStream){
            // note: this event will not be generated again until the server sends us more data
            NSInteger nrecv;
            vector<UINT8>::size_type old_size = connectionReceiveData.size();
            NSUInteger stepSize = 65536; // during testing we used a really small value here (i.e. 1)

            do {
                connectionReceiveData.resize(old_size + stepSize);
                nrecv = [recvStream read:&connectionReceiveData[old_size] maxLength:stepSize];
                // it is possible that we didn't read all available data due to our buffer being too small
                if(nrecv >= 0){
                    old_size += nrecv;
                }else{
                    // first remove us as the streams event handler so that we don't accidentally get more events
                    [recvStream setDelegate:nil];
                    [sendStream setDelegate:nil];
                    
                    [connectLock lock];
                    connectionState = eConnectionClosed;
                    [connectLock unlockWithCondition:eReadyStateCondition];
                    return;
                }
            } while ([recvStream hasBytesAvailable]);
            
            // we now have all the data that was pending
            connectionReceiveData.resize(old_size);
            
            // note: for this event we don't touch the connectionState state variable, or the lock, as it will be handled in the NSSteamEventEndEncountered condition below.
            
        } // else there are bytes on the sendStream? ... which makes no sense! ... but if so ... then we just ignore this event
    }
    
    if(eventCode & NSStreamEventHasSpaceAvailable){
        if(aStream == sendStream){
            // note: this event will not be generated again until we write something to the stream
            [connectLock lock];
            if(connectionState == eConnectionSending){
                NSInteger written;

                if(connectionSendData.size()){
                    written = [sendStream write:connectionSendData.data() maxLength:connectionSendData.size()];
                    if(written < connectionSendData.size()){
                        connectionSendData.erase(connectionSendData.begin(), connectionSendData.begin() + written);
                        [connectLock unlock];
                    } else {
                        if(written == connectionSendData.size()){
                            connectionSendData.clear();
                            connectionState = eConnectionSendingComplete;
                        }else{
                            // error:
                            // first remove us as the streams event handler so that we don't accidentally get more events
                            [recvStream setDelegate:nil];
                            [sendStream setDelegate:nil];
                            
                            connectionState = eConnectionClosed;
                            return;
                        }
                    
                        // only free the lock when all data is sent or if there is an error
                        [connectLock unlockWithCondition:eReadyStateCondition];
                    }
                } else {
                    [connectLock unlock];
                }
            } else if(connectionState == eConnectionConnected){
                // we got this event too soon (as in before we have received a send command from the card reader)
                connectionState = eConnectionSending; // we will inspect for this when we receive the command from the card reader
                [connectLock unlock];
            } else {
                [connectLock unlock];
            }
        } // else there is space available on the recvStream ... which we just ignore
    }
    
    if(eventCode & NSStreamEventEndEncountered){
        // note: it is entirely possible for the server to close the connection prematurely, before it has received anything from us (e.g.  due to some error server site).
        [connectLock lock];
        connectionState = eConnectionReceivingComplete;
        [connectLock unlockWithCondition:eReadyStateCondition];
    }
}

- (RequestCommand*)processConnect:(ConnectRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: connecting to bureau %s:%d timeout:%d"), pRequest->GetAddr().c_str(), pRequest->GetPort(), pRequest->GetTimeout());
    
    int status = EFT_PP_STATUS_CONNECT_ERROR;
    
    [connectLock lock];
    if(connectionState == eConnectionClosed){
        connectionState = eConnectionConnecting;
        connectionSendData.clear();
        connectionReceiveData.clear();
        [connectLock unlockWithCondition:eNoConnectStateCondition];
        
        NSString* host = @(pRequest->GetAddr().c_str());
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (__bridge CFStringRef)host, pRequest->GetPort(), &readStream, &writeStream);
        recvStream = (NSInputStream*)CFBridgingRelease(readStream);
        sendStream = (NSOutputStream*)CFBridgingRelease(writeStream);

        if(sendStream && recvStream){
            [recvStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
            //[sendStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
            [recvStream setDelegate:self];
            [sendStream setDelegate:self];
            [recvStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [sendStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

            [recvStream open];
            [sendStream open];
            
            if([connectLock lockWhenCondition:eReadyStateCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:pRequest->GetTimeout()]]){
                [connectLock unlockWithCondition:eNoConnectStateCondition];
                if(recvStream.streamStatus == NSStreamStatusOpen){
                    LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: connected to bureau"));
                    return new HostResponseCommand(CMD_HOST_CONN_RSP, EFT_PP_STATUS_SUCCESS);
                }else{
                    LOG_RELEASE(Logger::eWarning, _T("Error connecting bureau."));
                    status = EFT_PP_STATUS_CONNECT_ERROR;
                }
            }else{
                LOG_RELEASE(Logger::eWarning, _T("Error connecting bureau (timeout)."));
                status = EFT_PP_STATUS_CONNECT_TIMEOUT;
            }
        }else{
            LOG_RELEASE(Logger::eWarning, _T("Error connecting bureau."));
            status = EFT_PP_STATUS_CONNECT_ERROR;
        }
        
        // if we get to here then we encountered an error
        [self cleanUpConnection];
    }else{
        [connectLock unlock];
        // not sure how or what happened on the card reader side ...
        // ... but we are apparently already serving a server connection from the card reader ?!!!
        // (not to even mention the question of how this request got here while we are blocked somewhere else)
        // ... so, instead of trying to be graceful about it we will simply behave like our panties are in a rutt.
        status = EFT_PP_STATUS_CONNECT_ERROR;
        
        // also, note that we won't touch the "current" connection
    }
    
    return new HostResponseCommand(CMD_HOST_CONN_RSP, status);
}

- (RequestCommand*)processSend:(SendRequestCommand*)pRequest{
	LOG_RELEASE(Logger::eFine, _T("Request to bureau (length:%d): %@"), pRequest->GetLength(), [[NSString alloc] initWithBytes:pRequest->GetData() length:pRequest->GetLength() encoding:NSUTF8StringEncoding]);
    
    if(sendStream) {
        //connectionState = eConnectionSending;
        connectionSendData.assign(pRequest->GetData(), pRequest->GetData() + pRequest->GetLength());
        
        [connectLock lock];
        if(connectionState == eConnectionSending){
            // the stream is already waiting for data from us
            NSInteger written;

            written = [sendStream write:connectionSendData.data() maxLength:connectionSendData.size()];
            if(written < connectionSendData.size()){
                connectionSendData.erase(connectionSendData.begin(), connectionSendData.begin() + written);
                [connectLock unlockWithCondition:eNoConnectStateCondition];

                if([connectLock lockWhenCondition:eReadyStateCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:pRequest->GetTimeout()]]){
                    if(connectionState == eConnectionSendingComplete){
                        [connectLock unlockWithCondition:eNoConnectStateCondition];
                        return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SUCCESS);
                    } // else send error
                } // else send timeout
            }else{
                if(written == connectionSendData.size()){
                    connectionSendData.clear();
                    connectionState = eConnectionSendingComplete;
                    [connectLock unlock];
                    return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SUCCESS);
                }
            }
        }
        [connectLock unlock];
        
    } // else this was a connection error
    
    // if we get to here then we encountered an error
    [self cleanUpConnection];
    
    return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SENDING_ERROR);
}

- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest{
	LOG(_T("Recv :%d bytes, %ds timeout"), pRequest->GetDataLen(), pRequest->GetTimeout());
    
    if(recvStream) {
        if([connectLock lockWhenCondition:eReadyStateCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:pRequest->GetTimeout()]]){
            if(connectionState == eConnectionReceivingComplete)
            {
                [connectLock unlockWithCondition:eNoConnectStateCondition];
                LOG_RELEASE(Logger::eFine, _T("Response from bureau (length:%d): "), connectionReceiveData.size());
                return new ReceiveResponseCommand(connectionReceiveData);
            } // else receive error
            
            [connectLock unlockWithCondition:eNoConnectStateCondition];
        } // else receive timeout
    } // else there was a connect or send error

    // if we get to here then we encountered an error
    [self cleanUpConnection];
    
    return new HostResponseCommand(CMD_HOST_RECV_RSP, EFT_PP_STATUS_RECEIVING_ERROR);
}

- (RequestCommand*)processDisconnect:(DisconnectRequestCommand*)pRequest{
    [self cleanUpConnection];
	LOG_RELEASE(Logger::eFine, _T("State of financial transaction changed: disconnected"));
	return new HostResponseCommand(CMD_HOST_DISC_RSP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand*)processSignature:(SignatureRequestCommand*)pRequest{
	LOG(_T("Signature required request"));
	int status = [processor processSign:pRequest];
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

#endif
