//
//  HapiRemoteService.m
//  headstart
//
//  Created by Matti on 01/11/16.
//  Copyright © 2016 Handpoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonHMAC.h>

#import "HapiRemoteService.h"


#ifdef DEBUG
static NSString* remoteHapiHost = @"dev-api.handpoint.io";
#else
static NSString* remoteHapiHost = @"api.handpoint.com";
#endif
// static NSString* method_path = @"/viscus/sdk/v1/tipadjustment/";
static NSString* method_path = @"/sdk/financial/v1/tipadjustment/";


static short     remoteHapiPort = 0;
static NSString* sharedSecret = nil;


BOOL setupHandpointApiConnection(NSString* shared_secret)
{
    if (shared_secret == nil)
    {
        NSLog(@"shared secret must be set");
        return NO;
    }
    
    if ([shared_secret isEqualToString:@""])
    {
        NSLog(@"shared secret must not be an empty string");
        return NO;
    }
    
    sharedSecret = shared_secret;
    return YES;
}

BOOL tipAdjustment(NSString* transaction, NSInteger tipAmount, tipAdjustmentCompletionHandler handler)
{
    
    // check parameters and host connection parameterse
    if (transaction == nil || [transaction isEqualToString:@""])
    {
        NSLog(@"Invalid transactionId");
        return NO;
    }
    
    // TODO: more robust verification of the transaction id.
    if (handler == nil)
    {
        NSLog(@"handler missing");
        return NO;
    }
    
    if (tipAmount < 0)
    {
        NSLog(@"Negative tips not accepted");
        return NO;
    }
    
    if (sharedSecret == nil)
    {
        NSLog(@"Shared secret not set, a connection to a reader must be initiated.");
        return NO;
    }

    // copy the handler parameter
    // tipAdjustmentCompletionHandler local_handler = [handler copy];
    tipAdjustmentCompletionHandler local_handler = handler;

    static NSString* xml_template = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    "<tipadjustment>\n"
    "\t<originalGuid>%@</originalGuid>\n"
    "\t<tipAmount>%d</tipAmount>\n"
    "\t<timestamp>%@</timestamp>\n"
    "</tipadjustment>";
    
    // date format: 2016-11-01T15:50:16.664Z
    NSDate* current_date = [NSDate date];
    
    // prepare the XML package for RPC
    NSString* xml_to_post = [NSString stringWithFormat:xml_template, transaction, tipAmount, current_date];
    
#ifdef DEBUG
    NSLog(@"xml_to_post: %@", xml_to_post);
#endif
    
    NSData* data =[xml_to_post dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *mac = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac( kCCHmacAlgSHA256,
               [[sharedSecret dataUsingEncoding:NSASCIIStringEncoding] bytes],
                [sharedSecret length],
                data.bytes,
                data.length,
                mac.mutableBytes);

    
    NSString* hmac = [mac base64EncodedStringWithOptions:0];

#ifdef DEBUG
    NSLog(@"hmac: %@", hmac);
#endif
    // call the http post method
    //  - set parameters, including hmac
    NSURLSessionConfiguration* session_configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    // session_configuration.timeoutIntervalForResource = timeout; // Hardcoded timeout? Parameter to method? Class if we have a class?
    
    NSURLComponents* components = [[NSURLComponents alloc] init];
#ifdef DEBUG
    components.scheme = @"https";
#else
    components.scheme = @"https";
#endif
    components.host = remoteHapiHost;
    if (remoteHapiPort > 0)
    {
        components.port = [NSNumber numberWithShort:remoteHapiPort];
    }
    components.path = method_path;

#ifdef DEBUG
    NSLog(@"NSURLComponents string: %@", components.string);
#endif
    NSURL* url = components.URL;

#ifdef debug
    NSLog(@"url: %@", [url absoluteString]);
#endif
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:hmac forHTTPHeaderField:@"hmac"];
    // is this not a part of the request already? - does it get in the way?
    [request setValue:components.host forHTTPHeaderField:@"Host"];
    
#ifdef DEBUG
    NSLog(@"request: %@", request);
#endif

    NSURLSession* session = [NSURLSession sessionWithConfiguration:session_configuration];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *response_data, NSURLResponse *response, NSError *error)
                                          {
                                              TipAdjustmentStatus returnValue = TipAdjustmentFailed; // lets assume the worst

                                              //  - handle result of http post in a block
                                              //  - call handler when done
                                              //  - release handler parameter
                                              NSLog(@"response: %@", [response description]);
                                              
                                              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                              NSInteger status_code = [httpResponse statusCode];
                                              if (error != nil)
                                              {
                                                  NSString* error_code = error.description;
                                                  NSLog([NSString stringWithFormat:@"http status: [%ld] error: [%@]", (long)status_code, error_code]);
                                              }
                                              else
                                              {
                                                  switch (status_code)
                                                  {
                                                      case 200:
                                                          returnValue = TipAdjustmentAuthorised;
                                                          break;
                                                      case 403:
                                                          returnValue = TipAdjustmentDeclined;
                                                          break;
                                                      default:
                                                          // use TipAdjustmentusFailed
                                                          break;
                                                  };
                                              }
                                              
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  // call the completion block in the main thread
                                                  local_handler(returnValue);
                                              });
                                          }
    ];
    
    [uploadTask resume];

    // return from this method
    // release handler on error
    // return YES;
    return YES;
}
