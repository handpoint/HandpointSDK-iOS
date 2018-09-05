#pragma once

#import <Foundation/Foundation.h>

class ResponseCommand;
class EventInfoResponseCommand;
class XMLCommandResponseCommand;
class FinanceResponseCommand;
//class DebugInfoResponseCommand;
class GetLogInfoResponseCommand;
class SignatureRequestCommand;

@protocol IResponseProcessor

-(void)sendResponseInfo:(NSString*)status code:(int)code xml:(NSDictionary*)xml;
-(void)sendResponseError:(NSString*)status;
//-(int)processSign:(NSString*)receipt;
-(int)processSign:(SignatureRequestCommand*)pRequest;
-(void)processResponse:(ResponseCommand*)pResponse;
-(void)processEventInfoResponse:(EventInfoResponseCommand*)pResponse;
-(void)processXMLCommandResponseCommand:(XMLCommandResponseCommand*)pResponse;
-(void)processFinanceResponse:(FinanceResponseCommand*)pResponse;
//-(void)processDebugInfoResponse:(DebugInfoResponseCommand*)pResponse;
-(void)processLogInfoResponse:(GetLogInfoResponseCommand*)pResponse;

-(BOOL)cancelIfPossible;

@end