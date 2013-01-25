//
//  HeftStatusReport.h
//  headstart
//

@interface ResponseInfo : NSObject
@property(nonatomic,strong) NSString* status;
@property(nonatomic,strong) NSDictionary* xml;
@end

@interface FinanceResponseInfo : ResponseInfo
@property(nonatomic) NSInteger authorisedAmount;
@property(nonatomic,strong) NSString* transactionId;
@property(nonatomic,strong) NSString* customerReceipt;
@end

@interface LogInfo : ResponseInfo
@property(nonatomic,strong) NSString* log;
@end

@protocol HeftStatusReportDelegate
- (void)responseStatus:(ResponseInfo*)info;
- (void)responseError:(ResponseInfo*)info;
- (void)responseFinanceStatus:(FinanceResponseInfo*)info;
- (void)responseLogInfo:(LogInfo*)info;
- (void)requestSignature:(NSString*)receipt;
- (void)cancelSignature;
@end
