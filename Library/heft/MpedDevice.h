//
//  MpedDevice.h
//  headstart
//

#import "HeftClient.h"

@class HeftConnection;
@protocol HeftStatusReportDelegate;

@interface MpedDevice : NSObject<HeftClient>

@property (readwrite, nonatomic) NSString *sharedSecret;

- (id)initWithConnection:(HeftConnection *)aConnection sharedSecret:(NSString *)aSharedSecret delegate:(id <HeftStatusReportDelegate>)aDelegate;
- (void)shutdown;

@end
