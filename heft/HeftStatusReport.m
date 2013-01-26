//
//  HeftStatusReport.m
//  headstart
//

#import "HeftStatusReport.h"

@implementation ResponseInfo
@synthesize statusCode, status, xml;
@end

@implementation FinanceResponseInfo
@synthesize authorisedAmount,transactionId,customerReceipt;
@end

@implementation LogInfo
@synthesize log;
@end
