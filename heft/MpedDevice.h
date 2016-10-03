//
//  MpedDevice.h
//  headstart
//

#import "HeftClient.h"

@class HeftConnection;
@protocol HeftStatusReportDelegate;

@interface MpedDevice : NSObject<HeftClient>

- (id)initWithConnection:(HeftConnection*)aConnection sharedSecret:(NSData*)aSharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate;
- (void)shutdown;
@end
