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



static NSString* remoteHapiHost;
static short     remoteHapiPort = 0;
static NSString* sharedSecret;


BOOL setupRemoteConnectionWithCardreader(NSString* shared_secret)
{
    // what to do?
    // connect to a card reader (or check if one is connected)
    // and then call a method on the cardreader to get the host and port
    // which could just be anything that tricks the cardreader to call connect
    // but should be something more explicit.
    
    sharedSecret = shared_secret;
    // remoteHapiHost = @"gwtest3.handpoint.com"; // TODO: Remove debug value
    remoteHapiHost = @"extest1.handpoint.com"; // TODO: Remove debug value
    // remoteHapiHost = @"157.157.10.150"; //
    // remoteHapiHost = @"gwtest3.handpointoffice.internal"; // TODO: Remove debug value
    // remoteHapiPort = 8080; // TODO: Remove debug value
    // remoteHapiPort = 3080; // TODO: Remove debug value
    return YES;
    // return NO;
}

BOOL tipAdjustment(NSString* transaction_id, NSInteger tipAmount, tipAdjustmentCompletionHandler handler)
{
    static NSString* method_path = @"/viscus/sdk/v1/tipadjustment/";
    
    // check parameters and host connection parameterse
    if (transaction_id == nil || [transaction_id isEqualToString:@""])
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
    tipAdjustmentCompletionHandler local_handler = [handler copy];

    static NSString* xml_template = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
    "<tipadjustment>\n"
    "\t<originalGuid>%@</originalGuid>\n"
    "\t<tipAmount>%d</tipAmount>\n"
    "\t<timestamp>%@</timestamp>\n"
    "</tipadjustment>";
    
    // date format: 2016-11-01T15:50:16.664Z
    NSDate* current_date = [NSDate date];
    
    // prepare the XML package for RPC
    NSString* xml_to_post = [NSString stringWithFormat:xml_template, transaction_id, tipAmount, current_date];
    
    NSLog(@"xml_to_post: %@", xml_to_post);
    
    NSData* data =[xml_to_post dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *mac = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
    CCHmac( kCCHmacAlgSHA256,
               [[sharedSecret dataUsingEncoding:NSASCIIStringEncoding] bytes],
                [sharedSecret length],
                data.bytes,
                data.length,
                mac.mutableBytes);

    
    NSString* hmac = [mac base64EncodedStringWithOptions:0];
    NSLog(@"hmac: %@", hmac);
    
    // call the http post method
    //  - set parameters, including hmac
    NSURLSessionConfiguration* session_configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    // session_configuration.timeoutIntervalForResource = timeout; // Hardcoded timeout? Parameter to method? Class if we have a class?
    
    NSURLComponents* components = [[NSURLComponents alloc] init];
    components.scheme = @"https";
    components.host = remoteHapiHost;
    if (remoteHapiPort > 0)
    {
        components.port = [NSNumber numberWithShort:remoteHapiPort];
    }
    components.path = method_path;
    
    NSLog(@"NSURLComponents string: %@", components.string);
    NSURL* url = components.URL;
    
    NSLog(@"url: %@", [url absoluteString]);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:hmac forHTTPHeaderField:@"hmac"];
    // is this not a part of the request already? - does it get in the way?
    [request setValue:components.host forHTTPHeaderField:@"Host"];
    
    NSLog(@"request: %@", request);

    NSURLSession* session = [NSURLSession sessionWithConfiguration:session_configuration];

    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:data
                                                      completionHandler:^(NSData *response_data, NSURLResponse *response, NSError *error)
                                          {
                                              //  - handle result of http post in a block
                                              //  - call handler when done
                                              //  - release handler parameter
                                              NSLog(@"response: %@", [response description]);
                                              NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                              
                                              NSInteger status_code = [httpResponse statusCode];
                                              NSString* error_code = @"no error";
                                              if (error != nil)
                                              {
                                                  error_code = error.description;
                                              }
                                              
                                              // when done, call the block - should we do it here or post it to the main (ui) thread?
                                              local_handler((int) status_code , error_code);
                                          }
    ];
    
    [uploadTask resume];

    // return from this method
    // release handler on error
    // return YES;
    return YES;
}
