//
//  MpedDevice.h
//  headstart
//

#import "HeftClient.h"

@class HeftConnection;
@protocol HeftStatusReportDelegate;

@interface MpedDevice : NSObject<HeftClient>

@property (readwrite, nonatomic) NSData *sharedSecret;

- (id)initWithConnection:(HeftConnection*)aConnection sharedSecret:(NSData*)aSharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate;
- (void)shutdown;

@end
