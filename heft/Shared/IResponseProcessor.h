#pragma once

class ResponseCommand;
class EventInfoResponseCommand;
class FinanceResponseCommand;
class DebugInfoResponseCommand;
class GetLogInfoResponseCommand;

@protocol IResponseProcessor

-(void)sendResponseInfo:(NSString*)status xml:(NSDictionary*)xml;
-(void)sendResponseError:(NSString*)status;
-(int)processSign:(NSString*)receipt;
-(void)processResponse:(ResponseCommand*)pResponse;
-(void)processEventInfoResponse:(EventInfoResponseCommand*)pResponse;
-(void)processFinanceResponse:(FinanceResponseCommand*)pResponse;
-(void)processDebugInfoResponse:(DebugInfoResponseCommand*)pResponse;
-(void)processLogInfoResponse:(GetLogInfoResponseCommand*)pResponse;

@end