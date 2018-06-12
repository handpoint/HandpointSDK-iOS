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
#import <ExternalAccessory/ExternalAccessory.h>

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
    NSRunLoop *currentRunLoop = nil;
    RunLoopThread *currentRunLoopThread;
}

@interface RunLoopThread : NSThread
{
}
- (void)Run;
@end

@implementation RunLoopThread
- (void)Run
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


enum eConnectCondition
{
    eNoConnectStateCondition, eReadyStateCondition
};

@interface MPosOperation () <NSStreamDelegate>
@end

@implementation MPosOperation
{
    RequestCommand *pRequestCommand;
    HeftConnection *connection;
    __weak id <IResponseProcessor> processor;
    NSString *sharedSecret;
    BOOL runLoop;
    
    // we get the host and the port from the ConnectToHost request command.
    NSURLSessionConfiguration *session_configuration;
    NSURLComponents *components;
    int timeout;
    NSMutableData *host_response_data;
    NSError *host_communication_error;
    NSCondition *wait_until_done;
}


+ (void)startRunLoop
{
    static dispatch_once_t once;
    dispatch_once(&once, ^
    {
        // start a thread with the runloop
        LOG(@"Inside dispatch once.");
        currentRunLoopThread = [RunLoopThread new];
        [currentRunLoopThread start];
    });
}

- (void)EAAccessoryDidDisconnect:(NSNotification *)notification
{
    LOG(@"EAAccessoryDidDisconnect");
    EAAccessory *accessory = notification.userInfo[EAAccessoryKey];
    
    if ([accessory.protocolStrings containsObject:@"com.datecs.pinpad"])
    {
        runLoop = NO;
        FrameManager::TearDown();
    }
}

- (id)initWithRequest:(RequestCommand *)aRequest
           connection:(HeftConnection *)aConnection
     resultsProcessor:(id <IResponseProcessor>)aProcessor
         sharedSecret:(NSString *)aSharedSecret
{
    if (self = [super init])
    {
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(EAAccessoryDidDisconnect:)
                              name:EAAccessoryDidDisconnectNotification
                            object:nil];
        
        EAAccessoryManager *eaManager = [EAAccessoryManager sharedAccessoryManager];
        [eaManager registerForLocalNotifications];
        
        LOG(@"mPos Operation started.");
        runLoop = YES;
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

- (void)dealloc
{
    LOG(@"mPos Operation ended.");
    if (pRequestCommand)
    {
        delete pRequestCommand;
    }
}

- (void)main
{
    @autoreleasepool
    {
        @synchronized ([MPosOperation class])
        {
            try
            {
                RequestCommand *currentRequest = pRequestCommand;
                [connection resetData];

                while (true && runLoop)
                {
                    // sending the command to the device
                    FrameManager fm(*currentRequest, connection.maxFrameSize);
                    fm.Write(connection);

                    // when/why does this happen?
                    if (pRequestCommand != currentRequest)
                    {
                        delete currentRequest;
                        currentRequest = 0;
                    }

                    std::unique_ptr<ResponseCommand> pResponse;
                    BOOL retry;
                    BOOL already_cancelled = NO;
                    while (true && runLoop)
                    {
                        do
                        {
                            retry = NO;
                            try
                            {
                                // read the response from the cardreader
                                if (runLoop)
                                {
                                    pResponse.reset(fm.ReadResponse<ResponseCommand>(connection, true));
                                }
                            }
                            catch (timeout4_exception &to4)
                            {
                                // to be nice we will try to send a cancel to the card reader
                                retry = !already_cancelled ? [processor cancelIfPossible] : NO;
                                already_cancelled = retry;
                                if (!retry)
                                {
                                    throw to4;
                                }
                            }
                        } while (retry && runLoop);

                        if (pResponse->isResponse())
                        {
                            pResponse->ProcessResult(processor);
                            if (pResponse->isResponseTo(*pRequestCommand))
                            {
                                LOG_RELEASE(Logger::eInfo, @"Current mPos operation completed.");
                                return;
                            }
                            continue;
                        }
                        break;
                    }

                    IRequestProcess *pHostRequest = dynamic_cast<IRequestProcess *>(reinterpret_cast<RequestCommand *>(pResponse.get()));
                    currentRequest = pHostRequest->Process(self);
                }
            }
            catch (heft_exception &exception)
            {
                LOG(@"MPosOpoeration::main got an exception");
                [processor sendResponseError:exception.stringId()];
            }
        }
    }
}

- (void)cleanUpConnection
{
    LOG(@"MPosOpoeration::cleanUpConnection");
    runLoopRunning = NO;
    wait_until_done = nil;
    host_response_data = nil;
    host_communication_error = nil;
}

#pragma mark IHostProcessor

namespace {
    std::map<unsigned long, NSString *> eventCodes = {
            {0, @"NSStreamEventNone"},
            {1, @"NSStreamEventOpenCompleted"},
            {2, @"NSStreamEventHasBytesAvailable"},
            {4, @"NSStreamEventHasSpaceAvailable"},
            {8, @"NSStreamEventErrorOccurred"},
            {16, @"NSStreamEventEndEncountered"}
    };

    // TODO: add codes
    //       use Objective-C map?
    std::map<unsigned short, NSString *> httpCodes = {
            {200, @"OK"},
            {400, @"Bad Request"},
            {401, @"Unauthorized"},
            {403, @"Forbidden"},
            {404, @"Not Found"},
            {405, @"Method Not Allowed"},
            {500, @"Internal Server Error"}
    };
}


// Declare a new method that will be used by both processSend and processPost, almost all of the
// duplicate code should be in this method.
//
// POST data to host in the background, locking lock before returning and releasing when done
// user calls the function and if it returns YES, wait for the lock.
// BOOL sendMessage(NSString* host, short port, NSString* path, NSData* data, NSCondition* lock);

- (RequestCommand *)processConnect:(ConnectRequestCommand *)pRequest
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
    components.port = @(pRequest->GetPort());

    timeout = pRequest->GetTimeout();
    host_response_data = nil;
    host_communication_error = nil;
    wait_until_done = nil;

    session_configuration.timeoutIntervalForResource = timeout;

    return new HostResponseCommand(EFT_PACKET_HOST_CONNECT_RESP, EFT_PP_STATUS_SUCCESS);
}


// header_values: a list of strings where each string is a key: value pair
void copy_headervalues_to_request (NSArray *header_values, NSMutableURLRequest *request)
{
    static const NSArray *keys_to_ignore
            = [NSArray arrayWithObjects:@"Accept",
                                        @"Content-Type",
                                        @"Host",
                                        @"Connection",
                                        @"Content-Length",
                                        @"Accept-Language", nil];

    for (int i = 1; i < [header_values count]; i++)
    {
        NSString *line = [header_values objectAtIndex:i];
        NSArray *key_value = [line componentsSeparatedByString:@":"];
        NSString *key = [key_value firstObject];

        // ignore keys we already set
        if ([keys_to_ignore containsObject:key])
        {
            NSLog(@"ignore key: %@", key_value);
            continue;
        }
        NSLog(@"add key: %@", key_value);

        NSString *value = [key_value[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [request setValue:value forHTTPHeaderField:key];
    }
}

- (RequestCommand *)processSend:(SendRequestCommand *)pRequest
{
    LOG_RELEASE(Logger::eFine, @"Sending request to bureau (length:%d).", pRequest->GetLength());

    // LOG_RELEASE(Logger::eFiner, ::dump(@"Outgoing message"));
    LOG(@"%@", ::dump(@"Message to bureau:", pRequest->GetData(), pRequest->GetLength()));

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

    NSString *http_request = [[NSString alloc] initWithBytes:pRequest->GetData()
                                                      length:pRequest->GetLength()
                                                    encoding:NSISOLatin1StringEncoding];

#ifdef DEBUG
    int log_size = std::min(100, pRequest->GetLength());
    LOG_RELEASE(Logger::eFiner, @"start of request data: %@", [http_request substringToIndex:log_size]);
#endif

    // split on double linefeed
    NSArray *parts = [http_request componentsSeparatedByString:@"\r\n\r\n"];
    // should have two parts, the header and the data
    NSString *http_header = [parts objectAtIndex:0];
    NSArray *header_values = [http_header componentsSeparatedByString:@"\r\n"];

    // the post data should be NSData, not NSString - copy straight from the buffer
    NSUInteger size_of_http_header = [http_header length];

    // the data is everything after the header+double linefeed
    NSData *data = [NSData dataWithBytes:pRequest->GetData() + (int) size_of_http_header + 4
                                  length:pRequest->GetLength() - (size_of_http_header + 4)];

    // get the first line of the http header, looks like this
    // POST /viscus/cr/v1/authorization HTTP/1.1
    // split it on spaces, get the middle part, which is the path on the server
    NSString *first_line = [header_values objectAtIndex:0];
    NSString *path = [[first_line componentsSeparatedByString:@" "] objectAtIndex:1];

#ifdef DEBUG
    LOG_RELEASE(Logger::eFiner, @"first line: %@, path: %@", first_line, path);
#endif

    components.path = path;

    NSURL *url = components.URL;
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

    // parse the rest (after first line) of the header values (key: value) and add relevant values to the request.
    // iterate with a for loop instead of using subarrayWithRange which copies the array
    copy_headervalues_to_request(header_values, request);

    wait_until_done = [[NSCondition alloc] init];

    [wait_until_done lock];

#ifdef DEBUG
    LOG(@"Sending a http request to host");
#endif
    NSURLSession *session = [NSURLSession sessionWithConfiguration:session_configuration];

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

                                                              NSString *status_string = @"";
                                                              auto http_code_found = httpCodes.find((int) status_code);
                                                              if (http_code_found != httpCodes.end())
                                                              {
                                                                  status_string = http_code_found->second;
                                                              }

                                                              NSString *header = [NSString stringWithFormat:@"HTTP/1.1 %d %@\r\n\r\n",
                                                                                                            (int) status_code,
                                                                                                            status_string];

                                                              NSData *tmp_data = [header dataUsingEncoding:NSUTF8StringEncoding];
                                                              host_response_data = [tmp_data mutableCopy];
                                                              [host_response_data appendData:response_data];
                                                          }
                                                          [wait_until_done signal];
                                                      }];


    LOG([[request allHTTPHeaderFields] descriptionInStringsFileFormat]);

    //Don't forget this line ever
    [uploadTask resume];


    return new HostResponseCommand(EFT_PACKET_HOST_SEND_RESP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand *)processReceive:(ReceiveRequestCommand *)pRequest
{
    LOG(@"processReceive:%lu bytes", (unsigned long) [host_response_data length]);

    // wait until upload done... then return
    // first check if we alread have data or error
    if (host_response_data == nil && host_communication_error == nil)
    {
        LOG(@"Waiting for lock");
        [wait_until_done wait];
        LOG(@"Got lock, done");
    }
    [wait_until_done unlock];

    // check for error - copy member data to local variables and reset
    NSError *error = host_communication_error;
    host_communication_error = nil;
    NSData *tmp = host_response_data;
    host_response_data = nil;

    if (error != nil)
    {
        return new HostResponseCommand(EFT_PACKET_HOST_RECEIVE_RESP, EFT_PP_STATUS_RECEIVING_ERROR);
    }
    else
    {
        return new ReceiveResponseCommand(tmp);
    }
}

- (RequestCommand *)processDisconnect:(DisconnectRequestCommand *)pRequest
{
    [self cleanUpConnection];
    LOG_RELEASE(Logger::eFine, @"State of financial transaction changed: disconnected");
    return new HostResponseCommand(EFT_PACKET_HOST_DISCONNECT_RESP, EFT_PP_STATUS_SUCCESS);
}

- (RequestCommand *)processPost:(PostRequestCommand *)pRequest
{
    LOG_RELEASE(Logger::eFine, @"Posting request to bureau (length:%d).", pRequest->GetLength());

    LOG(@"%@", ::dump(@"Message to bureau:", pRequest->GetData(), pRequest->GetLength()));

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
    NSString *http_request = [[NSString alloc] initWithData:pRequest->get_data() encoding:NSISOLatin1StringEncoding];

#ifdef DEBUG
    int log_size = std::min(100, pRequest->GetLength());
    LOG_RELEASE(Logger::eFiner, @"start of request data: %@", [http_request substringToIndex:log_size]);
#endif
    // split on double linefeed
    NSArray *parts = [http_request componentsSeparatedByString:@"\r\n\r\n"];
    // should have two parts, the header and the data
    NSString *http_header = parts[0];
    NSArray *header_values = [http_header componentsSeparatedByString:@"\r\n"];

    // the post data should be NSData, not NSString - copy straight from the buffer
    // the data is everything after the header+double linefeed

    // get the first line of the http header
    // POST /viscus/cr/v1/authorization HTTP/1.1
    // split it on spaces
    // get the middle part of that, which is the path on the server
    NSString *first_line = header_values[0];
    NSString *path = [first_line componentsSeparatedByString:@" "][1];

#ifdef DEBUG
    LOG_RELEASE(Logger::eFiner, @"first line: %@, path: %@", first_line, path);
#endif

    components.path = path;

    NSURL *url = components.URL;
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

    copy_headervalues_to_request(header_values, request);

    wait_until_done = [[NSCondition alloc] init];

    [wait_until_done lock];

#ifdef DEBUG
    LOG(@"Sending a http request to host");
#endif
    NSURLSession *session = [NSURLSession sessionWithConfiguration:session_configuration];

    NSData *data = [parts[1] dataUsingEncoding:NSISOLatin1StringEncoding];

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

                                                              NSString *status_string = @"";
                                                              auto http_code_found = httpCodes.find((int) status_code);
                                                              if (http_code_found != httpCodes.end())
                                                              {
                                                                  // status_string = httpCodes[(int) status_code];
                                                                  status_string = http_code_found->second;
                                                              }

                                                              NSString *header = [NSString stringWithFormat:@"HTTP/1.1 %d %@\r\n\r\n",
                                                                                                            (int) status_code,
                                                                                                            status_string];

                                                              NSData *tmp_data = [header dataUsingEncoding:NSUTF8StringEncoding];
                                                              host_response_data = [tmp_data mutableCopy];
                                                              [host_response_data appendData:response_data];
                                                          }
                                                          [wait_until_done signal];
                                                      }
    ];

    [uploadTask resume];

    LOG(@"Waiting for lock");
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    // [wait_until_done wait];
    BOOL finished_in_time = [wait_until_done waitUntilDate:timeoutDate];
    LOG(@"Got lock, done");
    [wait_until_done unlock];

    // should use local variables.
    // check for error - copy member data to local variables and reset
    NSError *error = host_communication_error;
    host_communication_error = nil;
    NSData *tmp = host_response_data;
    host_response_data = nil;

    if (finished_in_time == NO)
    {
        return new HostResponseCommand(EFT_PACKET_HOST_RECEIVE_RESP, EFT_PP_STATUS_CONNECT_TIMEOUT);
    }
    else if (error != nil)
    {
        return new HostResponseCommand(EFT_PACKET_HOST_RECEIVE_RESP, EFT_PP_STATUS_RECEIVING_ERROR);
    }
    else
    {
        return new ReceiveResponseCommand(tmp);
    }
}

- (RequestCommand *)processSignature:(SignatureRequestCommand *)pRequest
{
    LOG(@"Signature required request");
    int status = [processor processSign:pRequest];
    return new HostResponseCommand(EFT_PACKET_SIGNATURE_REQ_RESP, status);
}

- (RequestCommand *)processChallenge:(ChallengeRequestCommand *)pRequest
{
    LOG(@"Challenge required request");

    NSData *sharedSecretData = [self SharedSecretDataFromString:sharedSecret];

    CCHmacContext hmacContext;
    std::vector<std::uint8_t> mx([sharedSecretData length]);
    std::vector<std::uint8_t> zx(mx.size());
    std::vector<std::uint8_t> msg(pRequest->GetRandomNum());

    SecRandomCopyBytes(kSecRandomDefault, mx.size(), &mx[0]);
    msg.resize(mx.size() * 2);
    memcpy(&msg[mx.size()], &mx[0], mx.size());

    CCHmacInit(&hmacContext, kCCHmacAlgSHA256, [sharedSecretData bytes], [sharedSecretData length]);
    CCHmacUpdate(&hmacContext, &msg[0], msg.size());
    CCHmacFinal(&hmacContext, &zx[0]);

    return new ChallengeResponseCommand(mx, zx);
}

- (NSData *)SharedSecretDataFromString:(NSString *)sharedSecretString;
{
    NSUInteger sharedSecretLength = 64; //Shared secret string length
    NSMutableData *data = [NSMutableData data];
    //Check if shared secret has correct length, othervise we create a string of zeros with the correct length. That will result in a "shared secret invalid"
    if ([sharedSecretString length] != sharedSecretLength)
    {
        LOG(@"Shared secret string must be exactly %@ characters.", @(sharedSecretLength));
        sharedSecretString = [@"0" stringByPaddingToLength:sharedSecretLength withString:@"0" startingAtIndex:0];
    }

    for (int i = 0; i < 32; i++)
    {
        NSUInteger index = static_cast<NSUInteger>(i * 2);
        NSRange range = NSMakeRange(index, 2);
        NSString *bytes = [sharedSecretString substringWithRange:range];
        NSScanner *scanner = [NSScanner scannerWithString:bytes];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

@end

#endif
