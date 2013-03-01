//
//  HeftStatusReport.h
//  headstart
//

#import "HeftStatusReportPublic.h"

@interface ResponseInfo : NSObject<ResponseInfo>
@property(nonatomic) int statusCode;
@property(nonatomic,strong) NSString* status;
@property(nonatomic,strong) NSDictionary* xml;
@end

@interface FinanceResponseInfo : ResponseInfo<FinanceResponseInfo>
@property(nonatomic) NSInteger authorisedAmount;
@property(nonatomic,strong) NSString* transactionId;
@property(nonatomic,strong) NSString* customerReceipt;
@property(nonatomic,strong) NSString* merchantReceipt;
@end

@interface LogInfo : ResponseInfo<LogInfo>
@property(nonatomic,strong) NSString* log;
@end
