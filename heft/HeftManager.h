//
//  HeftManager.h
//  headstart
//

@protocol HeftClient;
@protocol HeftStatusReportDelegate;
@class HeftRemoteDevice;
@class DTDevices;


@protocol HeftDiscoveryDelegate
- (void)hasSources;
- (void)noSources;
- (void)didDiscoverDevice:(HeftRemoteDevice*)newDevice;
- (void)didDiscoverFinished;
@end


@protocol HeftDiscovery
@property(nonatomic, readonly) NSArray* devices;
@property(nonatomic, weak) NSObject<HeftDiscoveryDelegate>* delegate;
- (void)startDiscovery:(BOOL)fDiscoverAllDevices;
- (void)resetDevices;
@end


@interface HeftManager : NSObject<HeftDiscovery>

+ (HeftManager*)sharedManager;

@property(nonatomic, readonly) NSString* version;

- (BOOL)hasSources;
- (id<HeftClient>)clientForDevice:(HeftRemoteDevice*)device sharedSecret:(NSData*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate;

@end
