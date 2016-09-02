//
//  FinanceTransactionOperation.m
//  headstart
//

// #import "StdAfx.h"

#ifndef HEFT_SIMULATOR

#import "FrameManager.h"
#import "Frame.h"

#import "Shared/RequestCommand.h"
#import "Shared/ResponseCommand.h"

#import "MPosOperation.h"
#import "HeftConnection.h"

#import <CommonCrypto/CommonHMAC.h>

#include "Exception.h"
#include "Logger.h"
#import "debug.h"

#include <vector>
#include <memory>
#include <map>

@class RunLoopThread;

namespace
{
    BOOL runLoopRunning = NO;
    NSRunLoop* currentRunLoop = nil;
    RunLoopThread* currentRunLoopThread;
}

@interface RunLoopThread:NSThread
{
}
-(void)Run;
@end

@implementation RunLoopThread
-(void)Run
{
    LOG(@"mPos Operation run loop starting.");
    currentRunLoop = [NSRunLoop currentRunLoop];

    // TODO: add a timer - see other runloop
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
    runLoopRunning = YES;
    while (runLoopRunning)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil];
        loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
    }
    
    LOG(@"mPos Operation run loop stopping.");
}
@end



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
    std::vector<std::uint8_t> connectionSendData;
    std::vector<std::uint8_t> connectionReceiveData;
}



+ (void)startRunLoop
{
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // start a thread with the runloop
        LOG(@"Inside dispatch once.");
        currentRunLoopThread = [RunLoopThread new];
        [currentRunLoopThread start];
    });
}

- (id)initWithRequest:(RequestCommand*)aRequest
           connection:(HeftConnection*)aConnection
     resultsProcessor:(id<IResponseProcessor>)aProcessor
         sharedSecret:(NSData*)aSharedSecret
{
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
    if (pRequestCommand)
        delete pRequestCommand;
}

- (void)main{
	@autoreleasepool {
        // [MPosOperation startRunLoop];
        // wait for currentRunLoopThread to be anything else than nil?

		try
        {
			RequestCommand* currentRequest = pRequestCommand;
			[connection resetData];
			
			while(true)
            {
				//LOG_RELEASE(Logger:eFiner, currentRequest->dump(@"Outgoing message")));
                
                
                // sending the command to the device
				FrameManager fm(*currentRequest, connection.maxFrameSize);
				fm.Write(connection);
				
                // when/why does this happen?
				if(pRequestCommand != currentRequest)
                {
					delete currentRequest;
					currentRequest = 0;
				}
				
                std::unique_ptr<ResponseCommand> pResponse;
                BOOL retry;
                BOOL already_cancelled = NO;
				while(true)
                {
                    do
                    {
                        retry = NO;
                        try
                        {
                            // read the response from the cardreader
                            pResponse.reset(fm.ReadResponse<ResponseCommand>(connection, true));
                        }
                        catch (timeout4_exception& to4)
                        {
                            // to be nice we will try to send a cancel to the card reader
                            retry = !already_cancelled ? [processor cancelIfPossible] : NO;
                            already_cancelled = retry;
                            if(!retry)
                            {
                                throw to4;
                            }
                        }
                    } while (retry);                    
					
					if(pResponse->isResponse())
                    {
						pResponse->ProcessResult(processor);
						if(pResponse->isResponseTo(*pRequestCommand))
                        {
							LOG_RELEASE(Logger::eInfo, @"Current mPos operation completed.");
							return;
						}
						continue;
					}
					
					break;
				}
				
				IRequestProcess* pHostRequest = dynamic_cast<IRequestProcess*>(reinterpret_cast<RequestCommand*>(pResponse.get()));
				currentRequest = pHostRequest->Process(self);
			}
		}
		catch(heft_exception& exception)
        {
            LOG(@"MPosOpoeration::main got an exception");
			[processor sendResponseError:exception.stringId()];
		}
	}
}

- (void)cleanUpConnection{
    LOG(@"MPosOpoeration::cleanUpConnection");
    if(recvStream) {
        [recvStream close];
        [recvStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        // [recvStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [recvStream setDelegate:nil];
        recvStream = nil;
    }
    if(sendStream) {
        [sendStream close];
        [sendStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        // [sendStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [sendStream setDelegate:nil];
        sendStream = nil;
    }
    connectionState = eConnectionClosed;
    runLoopRunning = NO;
}

#pragma mark IHostProcessor

namespace {
    std::map<unsigned long, NSString*> eventCodes = {
        {0, @"NSStreamEventNone"},
        {1, @"NSStreamEventOpenCompleted"},
        {2, @"NSStreamEventHasBytesAvailable"},
        {4, @"NSStreamEventHasSpaceAvailable"},
        {8, @"NSStreamEventErrorOccurred"},
        {16, @"NSStreamEventEndEncountered"}
    };
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    LOG(@"stream:aStream handleEvent:%@", eventCodes[(unsigned long)eventCode]);

    if(eventCode & NSStreamEventErrorOccurred)
    {
        // first remove us as the streams event handler so that we don't accidentally get more events
        [recvStream setDelegate:nil];
        [sendStream setDelegate:nil];
        
        [connectLock lock];
        connectionState = eConnectionClosed;
        [connectLock unlockWithCondition:eReadyStateCondition];
        return;
    }
    
    if(eventCode & NSStreamEventOpenCompleted)
    {
        if(connectionState == eConnectionConnecting)
        {
            [connectLock lock];
            connectionState = eConnectionConnected;
            [connectLock unlockWithCondition:eReadyStateCondition];
        }
    }
    
    if(eventCode & NSStreamEventHasBytesAvailable)
    {
        if(aStream == recvStream)
        {
            // note: this event will not be generated again until the server sends us more data
            // NSInteger nrecv = 0;
            // auto old_size = connectionReceiveData.size();
            // NSUInteger stepSize = 16384; // during testing we used a really small value here (i.e. 1)
            
            std::uint8_t read_buffer[16384];

            do
            {
                // nrecv = [recvStream read:&connectionReceiveData[old_size] maxLength:stepSize];
                NSInteger nrecv = [recvStream read:read_buffer maxLength:16384];
                // it is possible that we didn't read all available data due to our buffer being too small
                LOG(@"read %ld bytes from tcp stream.", (long)nrecv);
                if(nrecv > 0)
                {
                    // old_size += nrecv;
                    connectionReceiveData.insert(end(connectionReceiveData), read_buffer, read_buffer+(int)nrecv);
                }
                else if (nrecv == 0)
                {
                    // end of stream, do nothing, we will received an NSStreamEventEndEncountered event next
                    return;
                }
                else
                {
                    // -1, an error occurred. But what error?
                    NSError* error = [recvStream streamError];
                    LOG(@"Got an error on the stream: \n %@", [error userInfo]);
                    
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
            // connectionReceiveData.resize(old_size);
            
            // note: for this event we don't touch the connectionState state variable, or the lock, as it will be handled in the NSSteamEventEndEncountered condition below.
            
        }
        else
        {
            // else there are bytes on the sendStream? ... which makes no sense! ... but if so ... then we just ignore this event
            LOG(@"NSStreamEventHasBytesAvailable, aStream != recvStream");
        }
    }
    
    if(eventCode & NSStreamEventHasSpaceAvailable)
    {
        LOG(@"NSStreamEventHasBytesAvailable");

        if(aStream == sendStream){
            // note: this event will not be generated again until we write something to the stream
            [connectLock lock];
            if(connectionState == eConnectionSending) {
                NSInteger written;

                if(connectionSendData.size())
                {
                    written = [sendStream write:connectionSendData.data() maxLength:connectionSendData.size()];
                    if(written < connectionSendData.size())
                    {
                        connectionSendData.erase(connectionSendData.begin(), connectionSendData.begin() + written);
                        [connectLock unlock];
                        
                        LOG_RELEASE(Logger::eFine, @"wrote %lu bytes, %lu still left to write", written, connectionSendData.size());
                        
                        // return, we will get another event when we can write more
                        return;
                    }
                    else
                    {
                        if(written == connectionSendData.size())
                        {
                            connectionSendData.clear();
                            connectionState = eConnectionSendingComplete;
                        }
                        else
                        {
                            // error:
                            // first remove us as the streams event handler so that we don't accidentally get more events
                            [recvStream setDelegate:nil];
                            [sendStream setDelegate:nil];
                            
                            connectionState = eConnectionClosed;
                            
                            LOG_RELEASE(Logger::eFine, @"Error writing data, closing connection.");
                            [connectLock unlock];
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
                // MÁ: This comment makes no sense, the state is not changed when a command is received from the card
                //     reader. The state should be changed as soon as a connection has been made
                connectionState = eConnectionSending; // we will inspect for this when we receive the command from the card reader
                [connectLock unlock];
            } else {
                [connectLock unlock];
            }
        } // else there is space available on the recvStream ... which we just ignore
    }
    
    if(eventCode & NSStreamEventEndEncountered)
    {
        LOG_RELEASE(Logger::eFine, @"NSStreamEventEndEncountered - server closed connection.");
        
        // note: it is entirely possible for the server to close the connection prematurely, before it has received anything from us (e.g.  due to some error server site).
        [connectLock lock];
        connectionState = eConnectionReceivingComplete;
        [connectLock unlockWithCondition:eReadyStateCondition];
    }
}

- (RequestCommand*)processConnect:(ConnectRequestCommand*)pRequest
{
	LOG_RELEASE(Logger::eFine,
                @"State of financial transaction changed: connecting to bureau %s:%d timeout:%d",
                pRequest->GetAddr().c_str(),
                pRequest->GetPort(),
                pRequest->GetTimeout()
    );
    
    int status = EFT_PP_STATUS_CONNECT_ERROR;
    
    [connectLock lock];
    if(connectionState == eConnectionClosed)
    {
        connectionState = eConnectionConnecting;
        connectionSendData.clear();
        connectionReceiveData.clear();
        [connectLock unlockWithCondition:eNoConnectStateCondition];
        
        NSString* host = @(pRequest->GetAddr().c_str());
        CFReadStreamRef readStream;
        CFWriteStreamRef writeStream;
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           (__bridge CFStringRef)host,
                                           pRequest->GetPort(),
                                           &readStream,
                                           &writeStream
        );
        
        recvStream = (NSInputStream*)CFBridgingRelease(readStream);
        sendStream = (NSOutputStream*)CFBridgingRelease(writeStream);

        if(sendStream && recvStream)
        {
            [recvStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
            // [sendStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
            [recvStream setDelegate:self];
            [sendStream setDelegate:self];
            
            // TODO: runloop testing going on - change back or remove old
            // TODO: use the thread runloop - store it in a static value
            
            [recvStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [sendStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            /*
             NSAssert(currentRunLoop != nil, @"currentRunLoop not set when calling schedlueInRunLoop...");
            [recvStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [sendStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
             */

            [recvStream open];
            [sendStream open];
            
            if([connectLock lockWhenCondition:eReadyStateCondition
                                   beforeDate:[NSDate dateWithTimeIntervalSinceNow:pRequest->GetTimeout()]])
            {
                [connectLock unlockWithCondition:eNoConnectStateCondition];
                if(recvStream.streamStatus == NSStreamStatusOpen)
                {
                    LOG_RELEASE(Logger::eFine, @"State of financial transaction changed: connected to bureau");
                    return new HostResponseCommand(CMD_HOST_CONN_RSP, EFT_PP_STATUS_SUCCESS);
                }
                else
                {
                    LOG_RELEASE(Logger::eWarning, @"Error connecting bureau.");
                    status = EFT_PP_STATUS_CONNECT_ERROR;
                }
            }
            else
            {
                LOG_RELEASE(Logger::eWarning, @"Error connecting bureau (timeout).");
                status = EFT_PP_STATUS_CONNECT_TIMEOUT;
            }
        }
        else
        {
            LOG_RELEASE(Logger::eWarning, @"Error connecting bureau.");
            status = EFT_PP_STATUS_CONNECT_ERROR;
        }
        
        // if we get to here then we encountered an error
        [self cleanUpConnection];
    }
    else
    {
        [connectLock unlock];
        // not sure how or what happened on the card reader side ...
        // ... but we are apparently already serving a server connection from the card reader ?!!!
        // (not to even mention the question of how this request got here while we are blocked somewhere else)
        // ... so, instead of trying to be graceful about it we will simply behave like our panties are in a rutt.
        LOG_RELEASE(Logger::eWarning, @"Invalid state, status=EFT_PP_STATUS_CONNECT_ERROR");
        status = EFT_PP_STATUS_CONNECT_ERROR;
        
        // also, note that we won't touch the "current" connection
    }
    
    return new HostResponseCommand(CMD_HOST_CONN_RSP, status);
}


- (RequestCommand*)processSend:(SendRequestCommand*)pRequest
{
    LOG_RELEASE(Logger::eFine, @"Sending request to bureau (length:%d).", pRequest->GetLength());
    
    if(sendStream)
    {
        if (connectionState == eConnectionConnected)
        {
            LOG(@"connectionState == eConnectionConnected");
            connectionState = eConnectionSending;  //TODO: skoða þetta betur, sjá hvað er að gerast.
        }
        
        // TODO: do we have to copy the data, can't we just store a pointer to the request
        //       , an index into the data and the bytes written?
        connectionSendData.assign(pRequest->GetData(), pRequest->GetData() + pRequest->GetLength());
        
        [connectLock lock];
        if(connectionState == eConnectionSending)
        {
            // the stream is already waiting for data from us
            NSInteger written = [sendStream write:connectionSendData.data()
                                        maxLength:connectionSendData.size()];
            
            if(written < connectionSendData.size())
            {
                LOG_RELEASE(Logger::eFine,
                            @"%d bytes sent to bureau, %d bytes left.",
                            written, pRequest->GetLength()-written);
                
                connectionSendData.erase(connectionSendData.begin(), connectionSendData.begin() + written);
                [connectLock unlockWithCondition:eNoConnectStateCondition];

                if([connectLock lockWhenCondition:eReadyStateCondition
                                       beforeDate:[NSDate dateWithTimeIntervalSinceNow:pRequest->GetTimeout()]])
                {
                    if(connectionState == eConnectionSendingComplete)
                    {
                        [connectLock unlockWithCondition:eNoConnectStateCondition];
                        return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SUCCESS);
                    }
                    else
                    {
                        LOG(@"ConnectionState != eConnectionSendingComplete");
                        // else send error
                        // what/why?
                    }
                } // else send timeout
                else
                {
                    LOG(@"Timout waiting for connectLock.");
                }
            }
            else
            {
                if(written == connectionSendData.size())
                {
                    LOG(@"written == sendData size.");
                    connectionSendData.clear();
                    connectionState = eConnectionSendingComplete;
                    [connectLock unlock];
                    return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SUCCESS);
                }
                else
                {
                    LOG(@"written > sendData size.");
                }
            }
        }
        else
        {
            LOG(@"(connectionState != eConnectionSending)");
        }
        [connectLock unlock];
        
    } // else this was a connection error
    else
    {
        LOG(@"Trying to send to bureau but sendStream is nil.");
    }
    
    // if we get to here then we encountered an error
    // TODO: this is too general, we must make sure we know what happened - and handle
    //       that wich we can handle. Everything else must be logged.
    LOG(@"processSend, sending error.");
    
    [self cleanUpConnection];
    
    return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SENDING_ERROR);
}

- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest
{
	LOG(@"Recv :%d bytes, %ds timeout", pRequest->GetDataLen(), pRequest->GetTimeout());
    
    if(recvStream)
    {
        if([connectLock lockWhenCondition:eReadyStateCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:pRequest->GetTimeout()]])
        {
            if(connectionState == eConnectionReceivingComplete)
            {
                [connectLock unlockWithCondition:eNoConnectStateCondition];
                LOG_RELEASE(Logger::eFine, @"Response from bureau (length:%d): ", connectionReceiveData.size());
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
	LOG_RELEASE(Logger::eFine, @"State of financial transaction changed: disconnected");
	return new HostResponseCommand(CMD_HOST_DISC_RSP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand*)processSignature:(SignatureRequestCommand*)pRequest{
	LOG(@"Signature required request");
	int status = [processor processSign:pRequest];
	return new HostResponseCommand(CMD_STAT_SIGN_RSP, status);
}

- (RequestCommand*)processChallenge:(ChallengeRequestCommand*)pRequest{
	LOG(@"Challenge required request");

	CCHmacContext hmacContext;
	std::vector<std::uint8_t> mx([sharedSecret length]);
    std::vector<std::uint8_t> zx(mx.size());
    std::vector<std::uint8_t> msg(pRequest->GetRandomNum());

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
