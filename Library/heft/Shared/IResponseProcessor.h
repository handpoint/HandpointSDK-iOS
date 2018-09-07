#pragma once

#import <Foundation/Foundation.h>

class ResponseCommand;
class EventInfoResponseCommand;
class XMLCommandResponseCommand;
class FinanceResponseCommand;
class GetLogInfoResponseCommand;
class SignatureRequestCommand;

@protocol IResponseProcessor

-(void)sendResponseInfo:(NSString*)status code:(int)code xml:(NSDictionary*)xml;
-(void)sendResponseError:(NSString*)status;
-(int)processSign:(SignatureRequestCommand*)pRequest;
-(void)processResponse:(ResponseCommand*)pResponse;
-(void)processEventInfoResponse:(EventInfoResponseCommand*)pResponse;
-(void)processXMLCommandResponseCommand:(XMLCommandResponseCommand*)pResponse;
-(void)processFinanceResponse:(FinanceResponseCommand*)pResponse;
-(void)processLogInfoResponse:(GetLogInfoResponseCommand*)pResponse;

-(BOOL)cancelIfPossible;

@end
