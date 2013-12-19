//
//  HeftStatusReport.m
//  headstart
//

#import "HeftStatusReport.h"

@implementation ResponseInfo
@synthesize statusCode, status, xml;
@end

@implementation ScannerEventInfo
@synthesize scanCode;
@end

@implementation EnableScannerResponseInfo
@end

@implementation FinanceResponseInfo
@synthesize authorisedAmount, transactionId, customerReceipt, merchantReceipt;
@end

@implementation LogInfo
@synthesize log;
@end
