//
//  HeftStatusReport.h
//  headstart
//

#import "HeftStatusReportPublic.h"

@interface ResponseInfo : NSObject<ResponseInfo>
@end

@interface ScannerEventInfo : ResponseInfo<ScannerEventInfo>
@end

@interface EnableScannerResponseInfo : ResponseInfo<EnableScannerResponseInfo>
@end

@interface FinanceResponseInfo : ResponseInfo<FinanceResponseInfo>
@end

@interface LogInfo : ResponseInfo<LogInfo>
@end
