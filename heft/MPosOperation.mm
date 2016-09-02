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

    // we get the host and the port from the ConnectToHost request command.
    NSURLComponents *components;
    int timeout;
    NSData* host_response_data;
    
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


- (RequestCommand*)processConnect:(ConnectRequestCommand*)pRequest
{
	LOG_RELEASE(Logger::eFine,
                @"State of financial transaction changed: connecting to bureau %s:%d timeout:%d",
                pRequest->GetAddr().c_str(),
                pRequest->GetPort(),
                pRequest->GetTimeout()
    );
    

    

    components = [[NSURLComponents alloc] init];
    components.scheme = @"https";
    components.host = [NSString stringWithUTF8String:pRequest->GetAddr().c_str()];
    components.port = [NSNumber numberWithInt:pRequest->GetPort()];
    
   
    timeout = pRequest->GetTimeout();
    
    return new HostResponseCommand(CMD_HOST_CONN_RSP, EFT_PP_STATUS_SUCCESS);
    

    
#if 0
    
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
    
#endif
}


- (RequestCommand*)processSend:(SendRequestCommand*)pRequest
{
    LOG_RELEASE(Logger::eFine, @"Sending request to bureau (length:%d).", pRequest->GetLength());

    // LOG_RELEASE(Logger::eFiner, ::dump(@"Outgoing message"));
    LOG(@"%@",::dump(@"Message to bureau:", pRequest->GetData(), pRequest->GetLength()));

    // parse the http header from the request
    //
    // POST /viscus/cr/v1/authorization HTTP/1.1\r\n
    // Accept-Language: en\r\n
    // Accept: */*\r\n
    // Host: gw2.handpoint.com\r\n
    // Content-Type: application/octet-stream\r\n
    // Connection: close\r\n
    // Content-Length: 1340\r\n\r\n          <--- double linefeed before data
    // 025\xb0\x02\x0b
    //


    NSString* http_request = [[NSString alloc] initWithBytes:pRequest->GetData() length:pRequest->GetLength() encoding:NSISOLatin1StringEncoding];
    
    LOG_RELEASE(Logger::eFiner, @"start of request data: %@", [http_request substringToIndex:50]);
    
    
    NSArray* parts = [http_request componentsSeparatedByString:@"\r\n\r\n"];
    // should have two parts, the header and the data
    NSString* http_header = [parts objectAtIndex:0];
    NSArray* header_values = [http_header componentsSeparatedByString:@"\r\n"];

    // the post data should be NSData, not NSString - copy straight from the buffer
    NSUInteger size_of_http_header = [http_header length];

    NSData* data = [NSData dataWithBytes:pRequest->GetData() + (int) size_of_http_header+4
                                  length: pRequest->GetLength() - (size_of_http_header+4)];


    // get the first line of the http header
    // POST /viscus/cr/v1/authorization HTTP/1.1
    // split it on spaces
    // get the middle part of that
    NSString* first_line = [header_values objectAtIndex:0];
    NSString* path = [[first_line componentsSeparatedByString:@" "] objectAtIndex:1];
    LOG_RELEASE(Logger::eFiner, @"first line: %@, path: %@", first_line, path);

    components.path = path;

    NSURL* url = components.URL;
    LOG_RELEASE(Logger::eFiner, [url absoluteString]);

    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Accept"];

    // [request setValue:[NSString stringWithFormat:@"%tu", [data length]] forHTTPHeaderField:@"Content-Length"];

    NSCondition* wait_until_done = [[NSCondition alloc] init];

    [wait_until_done lock];

    LOG(@"Sending a http request to host");

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *response_data, NSURLResponse *response, NSError *error)
    {
        LOG_RELEASE(Logger::eFiner, @"Response received from host: %@", [error localizedDescription])
        host_response_data = response_data;
        LOG([[NSString alloc] initWithData:response_data encoding:NSUTF8StringEncoding]);
        [wait_until_done signal];
    }];

    LOG([[request allHTTPHeaderFields] descriptionInStringsFileFormat]);

    //Don't forget this line ever
    [uploadTask resume];

    // wait until upload done... then return - or just assume it worked to hurry things up!
    LOG(@"Waiting for lock");
    [wait_until_done wait];
    LOG(@"Got lock, done");
    [wait_until_done unlock];

    return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest
{
    LOG(@"Recv :%d bytes", [host_response_data length]);

    return new ReceiveResponseCommand(host_response_data);
    host_response_data = nil;
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
