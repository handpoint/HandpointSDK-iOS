//
//  HeftStatusReport.m
//  headstart
//

#import "HeftStatusReport.h"

@implementation ResponseInfo
@synthesize statusCode, status, xml;
@end

@implementation ScannerEventResponseInfo
@synthesize scanCode;
@end

@implementation EnableScannerResponseInfo
@end

@implementation ScannerDisabledResponseInfo
@end

@implementation FinanceResponseInfo
@synthesize financialResult, isRestarting, authorisedAmount, transactionId, customerReceipt, merchantReceipt;
@end

@implementation LogInfo
@synthesize log;
@end
