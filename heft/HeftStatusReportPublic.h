//
//  HeftStatusReportPublic.h
//  headstart
//

@protocol ResponseInfo
@property(nonatomic) int statusCode;
@property(nonatomic,strong) NSString* status;
@property(nonatomic,strong) NSDictionary* xml;
@end

@protocol FinanceResponseInfo<ResponseInfo>
@property(nonatomic) NSInteger authorisedAmount;
@property(nonatomic,strong) NSString* transactionId;
@property(nonatomic,strong) NSString* customerReceipt;
@property(nonatomic,strong) NSString* merchantReceipt;
@end

@protocol LogInfo<ResponseInfo>
@property(nonatomic,strong) NSString* log;
@end

@protocol HeftClient;

@protocol HeftStatusReportDelegate
- (void)didConnect:(id<HeftClient>)client;
- (void)responseStatus:(id<ResponseInfo>)info;
- (void)responseError:(id<ResponseInfo>)info;
- (void)responseFinanceStatus:(id<FinanceResponseInfo>)info;
- (void)responseLogInfo:(id<LogInfo>)info;
- (void)requestSignature:(NSString*)receipt;
- (void)cancelSignature;
@end
