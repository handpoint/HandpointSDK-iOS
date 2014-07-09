//
//  HeftStatusReport.h
//  headstart
//

#import "HeftStatusReportPublic.h"

@interface ResponseInfo : NSObject<ResponseInfo>
@end

@interface ScannerEventResponseInfo : ResponseInfo<ScannerEventResponseInfo>
@end

DEPRECATED_ATTRIBUTE
@interface EnableScannerResponseInfo : ResponseInfo<EnableScannerResponseInfo>
@end

@interface ScannerDisabledResponseInfo : ResponseInfo<ScannerDisabledResponseInfo>
@end

@interface FinanceResponseInfo : ResponseInfo<FinanceResponseInfo>
@end

@interface LogInfo : ResponseInfo<LogInfo>
@end
