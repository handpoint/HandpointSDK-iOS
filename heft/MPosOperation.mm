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
    NSURLSessionConfiguration* session_configuration;
    NSURLComponents* components;
    int timeout;
    NSMutableData* host_response_data;
    NSError* host_communication_error;
    NSCondition* wait_until_done;
    
    /*
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
     */
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
	if(self = [super init])
    {
		LOG(@"mPos Operation started.");
		pRequestCommand = aRequest;
		connection = aConnection;
		processor = aProcessor;
		sharedSecret = aSharedSecret;
        host_response_data = nil;
        host_communication_error = nil;
        
        session_configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
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
    runLoopRunning = NO;
    wait_until_done = nil;
    host_response_data = nil;
    host_communication_error = nil;
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
    
    // TODO: add codes
    //       use Objective-C map?
    std::map<unsigned short, NSString*> httpCodes = {
        {200, @"OK"},
        {400, @"Bad Request"},
        {401, @"Unauthorized"},
        {403, @"Forbidden"},
        {404, @"Not Found"},
        {405, @"Method Not Allowed"},
        {500, @"Internal Server Error"}
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
    host_response_data = nil;
    host_communication_error = nil;
    wait_until_done = nil;
    
    session_configuration.timeoutIntervalForResource = timeout;
    
    return new HostResponseCommand(CMD_HOST_CONN_RSP, EFT_PP_STATUS_SUCCESS);
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
    // 025\xb0\x02\x0b...[1340 bytes total]
    //

    NSString* http_request = [[NSString alloc] initWithBytes:pRequest->GetData() length:pRequest->GetLength() encoding:NSISOLatin1StringEncoding];
    
#ifdef DEBUG
    int log_size = std::min(100, pRequest->GetLength());
    LOG_RELEASE(Logger::eFiner, @"start of request data: %@", [http_request substringToIndex:log_size]);
#endif
    
    // split on double linefeed
    NSArray* parts = [http_request componentsSeparatedByString:@"\r\n\r\n"];
    // should have two parts, the header and the data
    NSString* http_header = [parts objectAtIndex:0];
    NSArray* header_values = [http_header componentsSeparatedByString:@"\r\n"];

    // the post data should be NSData, not NSString - copy straight from the buffer
    NSUInteger size_of_http_header = [http_header length];

    // the data is everything after the header+double linefeed
    NSData* data = [NSData dataWithBytes:pRequest->GetData() + (int) size_of_http_header+4
                                  length:pRequest->GetLength() - (size_of_http_header+4)];

    // get the first line of the http header
    // POST /viscus/cr/v1/authorization HTTP/1.1
    // split it on spaces
    // get the middle part of that, which is the path on the server
    NSString* first_line = [header_values objectAtIndex:0];
    NSString* path = [[first_line componentsSeparatedByString:@" "] objectAtIndex:1];

#ifdef DEBUG
    LOG_RELEASE(Logger::eFiner, @"first line: %@, path: %@", first_line, path);
#endif

    components.path = path;

    NSURL* url = components.URL;
#ifdef DEBUG
    LOG_RELEASE(Logger::eFiner, [url absoluteString]);
#endif


    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    // Add values to the request
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    // is this not a part of the request already? - does it get in the way?
    [request setValue:components.host forHTTPHeaderField:@"Host"];

    wait_until_done = [[NSCondition alloc] init];

    [wait_until_done lock];

#ifdef DEBUG
    LOG(@"Sending a http request to host");
#endif
//    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:session_configuration];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *response_data, NSURLResponse *response, NSError *error)
    {
        LOG_RELEASE(Logger::eFiner, @"Response received from host, error: %@", [error localizedDescription])
        
        // TODO: handle errors here, for example, The network connection was lost.
        //       Save the error and return it to the reader in processReceive.
        //       See error handling in old code.
        if (error != nil)
        {
            host_communication_error = error;
        }
        else
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
            
            LOG(@"%@", [response description]);
            
            NSInteger status_code = [httpResponse statusCode];
            
            NSString* status_string = @"";
            if (httpCodes.find((int) status_code) != httpCodes.end())
            {
                status_string = httpCodes[(int) status_code];
            }
            
            NSString *header = [NSString stringWithFormat:@"HTTP/1.0 %d %@\r\n\r\n", (int) status_code, status_string];
            
            NSData* tmp_data = [header dataUsingEncoding:NSUTF8StringEncoding];
            host_response_data = [tmp_data mutableCopy];
            [host_response_data appendData:response_data];
        }
        // LOG([[NSString alloc] initWithData:response_data encoding:NSUTF8StringEncoding]);
        [wait_until_done signal];
    }];

    LOG([[request allHTTPHeaderFields] descriptionInStringsFileFormat]);

    //Don't forget this line ever
    [uploadTask resume];


    return new HostResponseCommand(CMD_HOST_SEND_RSP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand*)processReceive:(ReceiveRequestCommand*)pRequest
{
    LOG(@"processReceive:%lu bytes", (unsigned long) [host_response_data length]);

    // wait until upload done... then return - or just assume it worked to hurry things up!
    if (host_response_data == nil)
    {
        LOG(@"Waiting for lock");
        [wait_until_done wait];
        LOG(@"Got lock, done");
    }
    [wait_until_done unlock];
    
    // check for error - copy member data to local variables and reset
    NSError* error = host_communication_error;
    host_communication_error = nil;
    NSData* tmp = host_response_data;
    host_response_data = nil;

    if (error != nil)
    {
        return new HostResponseCommand(CMD_HOST_RECV_RSP, EFT_PP_STATUS_RECEIVING_ERROR);
    }
    else
    {
        return new ReceiveResponseCommand(tmp);
    }
}

- (RequestCommand*)processDisconnect:(DisconnectRequestCommand*)pRequest{
    [self cleanUpConnection];
	LOG_RELEASE(Logger::eFine, @"State of financial transaction changed: disconnected");
	return new HostResponseCommand(CMD_HOST_DISC_RSP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand*)processPost:(PostRequestCommand*)pRequest
{
    LOG_RELEASE(Logger::eFine, @"Posting request to bureau (length:%d).", pRequest->GetLength());
    
    // LOG_RELEASE(Logger::eFiner, ::dump(@"Outgoing message"));
    LOG(@"%@",::dump(@"Message to bureau:", pRequest->GetData(), pRequest->GetLength()));
    
    components = [[NSURLComponents alloc] init];
    components.scheme = @"https";
    components.host = pRequest->get_host();
    components.port = pRequest->get_port();
    
    timeout = pRequest->GetTimeout();

    host_response_data = nil;
    host_communication_error = nil;
    wait_until_done = nil;
    
    session_configuration.timeoutIntervalForResource = timeout;
    
    // parse the http header from the request
    //
    // POST /viscus/cr/v1/authorization HTTP/1.1\r\n
    // Accept-Language: en\r\n
    // Accept: */*\r\n
    // Host: gw2.handpoint.com\r\n
    // Content-Type: application/octet-stream\r\n
    // Connection: close\r\n
    // Content-Length: 1340\r\n\r\n          <--- double linefeed before data
    // 025\xb0\x02\x0b...[1340 bytes total]
    //
    NSString* http_request = [[NSString alloc] initWithData:pRequest->get_data() encoding:NSISOLatin1StringEncoding];
    
#ifdef DEBUG
    int log_size = std::min(100, pRequest->GetLength());
    LOG_RELEASE(Logger::eFiner, @"start of request data: %@", [http_request substringToIndex:log_size]);
#endif
    // split on double linefeed
    NSArray* parts = [http_request componentsSeparatedByString:@"\r\n\r\n"];
    // should have two parts, the header and the data
    NSString* http_header = [parts objectAtIndex:0];
    NSArray* header_values = [http_header componentsSeparatedByString:@"\r\n"];
    
    // the post data should be NSData, not NSString - copy straight from the buffer
    // NSUInteger size_of_http_header = [http_header length];
    
    // the data is everything after the header+double linefeed
    
    // NSData* data = [NSData dataWithBytes:pRequest->GetData() + (int) size_of_http_header+4
    //                              length:pRequest->GetLength() - (size_of_http_header+4)];
    // NSData* data = [[parts objectAtIndex:1] dataUsingEncoding:NSISOLatin1StringEncoding];
    
    // get the first line of the http header
    // POST /viscus/cr/v1/authorization HTTP/1.1
    // split it on spaces
    // get the middle part of that, which is the path on the server
    NSString* first_line = [header_values objectAtIndex:0];
    NSString* path = [[first_line componentsSeparatedByString:@" "] objectAtIndex:1];
    
#ifdef DEBUG
    LOG_RELEASE(Logger::eFiner, @"first line: %@, path: %@", first_line, path);
#endif
    
    components.path = path;
    
    NSURL* url = components.URL;
#ifdef DEBUG
    LOG_RELEASE(Logger::eFiner, [url absoluteString]);
#endif
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    // Add values to the request
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    // is this not a part of the request already? - does it get in the way?
    [request setValue:components.host forHTTPHeaderField:@"Host"];
    
    wait_until_done = [[NSCondition alloc] init];
    
    [wait_until_done lock];
    
#ifdef DEBUG
    LOG(@"Sending a http request to host");
#endif
    //    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:session_configuration];
    
    NSData* data = [[parts objectAtIndex:1] dataUsingEncoding:NSISOLatin1StringEncoding];
    
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *response_data, NSURLResponse *response, NSError *error)
          {
              LOG_RELEASE(Logger::eFiner, @"Response received from host, error: %@", [error localizedDescription])
              
              if (error != nil)
              {
                  host_communication_error = error;
              }
              else
              {
                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                  
                  LOG(@"%@", [response description]);
                  
                  NSInteger status_code = [httpResponse statusCode];
                  
                  NSString* status_string = @"";
                  if (httpCodes.find((int) status_code) != httpCodes.end())
                  {
                      status_string = httpCodes[(int) status_code];
                  }
                  
                  NSString *header = [NSString stringWithFormat:@"HTTP/1.1 %d %@\r\n\r\n", (int) status_code, status_string];
                  
                  NSData* tmp_data = [header dataUsingEncoding:NSUTF8StringEncoding];
                  host_response_data = [tmp_data mutableCopy];
                  [host_response_data appendData:response_data];
              }
              [wait_until_done signal];
          }
    ];
    
    // LOG([[request allHTTPHeaderFields] descriptionInStringsFileFormat]);
    
    [uploadTask resume];
    
    LOG(@"Waiting for lock");
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    // [wait_until_done wait];
    BOOL finished_in_time = [wait_until_done waitUntilDate:timeoutDate];
    LOG(@"Got lock, done");
    [wait_until_done unlock];
    
    // should use local variables.
    // check for error - copy member data to local variables and reset
    NSError* error = host_communication_error;
    host_communication_error = nil;
    NSData* tmp = host_response_data;
    host_response_data = nil;
    
    if (finished_in_time == NO)
    {
        return new HostResponseCommand(CMD_HOST_RECV_RSP, EFT_PP_STATUS_CONNECT_TIMEOUT);
    }
    else if (error != nil)
    {
        return new HostResponseCommand(CMD_HOST_RECV_RSP, EFT_PP_STATUS_RECEIVING_ERROR);
    }
    else
    {
        return new ReceiveResponseCommand(tmp);
    }
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
