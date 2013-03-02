//
//  HeftStatusReport.h
//  headstart
//

#import "HeftStatusReportPublic.h"

@interface ResponseInfo : NSObject<ResponseInfo>
@end

@interface FinanceResponseInfo : ResponseInfo<FinanceResponseInfo>
@end

@interface LogInfo : ResponseInfo<LogInfo>
@end
