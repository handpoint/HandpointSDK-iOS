//
//  HeftManager.h
//  headstart
//

/**
 *  @file   HeftManager.h
 *
 *  @brief  HeftManager interface
 *
 *
 **/

#import <Foundation/Foundation.h>
#import "HeftDiscovery.h"


@protocol HeftClient;
@protocol HeftStatusReportDelegate;
@class HeftRemoteDevice;

@interface HeftManager : NSObject <HeftDiscovery>

@property (nonatomic, readonly) NSString *version;


+ (HeftManager *)sharedManager;

/**
 Starts creation of a connection to the specified device.
 @param device					Device to be connected.
 @param sharedSecretString		Shared Secret information in string format
 @param aDelegate				Delegate which will be perform HeftStatusReportDelegate notifications.
 */
- (void)clientForDevice:(HeftRemoteDevice *)device
           sharedSecret:(NSString *)sharedSecret
               delegate:(NSObject <HeftStatusReportDelegate> *)delegate;

/**
@brief Stored array which contains all found devices.
*/
@property(nonatomic, readonly) NSArray* devicesCopy DEPRECATED_ATTRIBUTE;
@property(nonatomic, readonly) NSArray* connectedCardReaders;
/**
 Delegate object. Will handle notifications which contain in HeftDiscoveryDelegate protocol.
 */
@property(nonatomic, weak) id<HeftDiscoveryDelegate> delegate;
/**
 Start search for all available BT devices.
 */
- (void)startDiscovery;

- (BOOL)isConnectionHardwareReady;

@end

/*
@interface SimpleHeftManager
- (NSArray*) connectedCardReaders;

@property(nonatomic,readonly) HeftClient* cardReader;

@end
*/
