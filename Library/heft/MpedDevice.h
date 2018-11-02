//
//  MpedDevice.h
//  headstart
//

#import <Foundation/Foundation.h>
#import "HeftClient.h"

@class iOSConnection;
@protocol HeftStatusReportDelegate;

@interface MpedDevice : NSObject<HeftClient>

@property (readwrite, nonatomic) NSString *sharedSecret;

- (id)initWithConnection:(iOSConnection *)aConnection
            sharedSecret:(NSString *)aSharedSecret
                delegate:(NSObject <HeftStatusReportDelegate>  *)aDelegate;

- (void)shutdown;

@end
