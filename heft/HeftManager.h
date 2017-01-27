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


@protocol HeftClient;
@protocol HeftStatusReportDelegate;
@class HeftRemoteDevice;

/** 
 @brief HeftDiscoveryDelegate protocol methods
 */
@protocol HeftDiscoveryDelegate
/** @defgroup HDD_PROTOCOL HeftDiscoveryDelegate Notifications
 Notifications sent by the SDK on various events - new available device found, connection lost, connection found, etc
 @{
 */

/**
 Notifies that new accessory device was connected.
 @param newDevice   Contains information(name, adress) about discovered device.
 */
- (void)didFindAccessoryDevice:(HeftRemoteDevice*)newDevice;
/**
 Notifies that accessory device was disconnected.
 @param oldDevice   Contains information(name) about disconnected device.
 */
- (void)didLostAccessoryDevice:(HeftRemoteDevice*)oldDevice;
/**
 Notifies that search of all available BT devices was completed.
 */
- (void)didDiscoverFinished;

@optional
/**
 Notifies that Bluetooth is available.
 @deprecated This delegate method is deprecated starting from version 2.2.2
 */
- (void)hasSources DEPRECATED_ATTRIBUTE;
/**
 Notifies that Bluetooth isn't available anymore.
 @deprecated This delegate method is deprecated starting from version 2.2.2
 */
- (void)noSources DEPRECATED_ATTRIBUTE;
/**
 Notifies that new BT device was discovered.
 @param newDevice   Contains information(name, adress) about discovered device.
 @deprecated This delegate method is deprecated starting from version 2.2.2
 */
- (void)didDiscoverDevice:(HeftRemoteDevice*)newDevice DEPRECATED_ATTRIBUTE;

/**@}*/

@end

/** 
 @brief HeftDiscovery protocol methods
 */
@protocol HeftDiscovery
/** @defgroup HFD_PROTOCOL HeftDiscovery Protocol
 Contains discovery properties and methods.
 @{
 */

/** 
 @brief Stored array which contains all found devices.
 */
@property(nonatomic, readonly) NSMutableArray* devicesCopy;
/** 
 Delegate object. Will handle notifications which contain in HeftDiscoveryDelegate protocol. 
 */
@property(nonatomic, weak) NSObject<HeftDiscoveryDelegate>* delegate;
/**
 Start search for all available BT devices.
 @param fDiscoverAllDevices Send didDiscoverDevice:(HeftRemoteDevice*)newDevice for found device, even if it's already in the stored array.
 */
- (void)startDiscovery:(BOOL)fDiscoverAllDevices;
/**
 Clear array of all previously founded devices.
 */
- (void)resetDevices;

/**@}*/

@end

/** @brief HeftManager class methods*/ 
@interface HeftManager : NSObject<HeftDiscovery>
/** 
 Returns heft manager instance.
 */
+ (HeftManager*)sharedManager;

/** 
 DEPRECATED: use -(NSString*)getSDKVersion;
 @brief Current HeftManager version. 
 */
@property(nonatomic, readonly) NSString* version;

/**
 @brief Current Handpoint SDK version.
 */
@property(nonatomic, readonly) NSString* getSDKVersion;

/**
 @brief Current build number.
 */
@property(nonatomic, readonly) NSString* getSDKBuildNumber;

/**
 Performs hasSources request.
 @return YES if Bluetooth is available and NO if it isn't.
 */
- (BOOL)hasSources DEPRECATED_ATTRIBUTE;

/**
 Starts creation of a connection to the specified device.
 @param device					Device to be connected.
 @param sharedSecret			Shared Secret information in NSData format
 @param aDelegate				Delegate which will be perform HeftStatusReportDelegate notifications.
 */
- (void)clientForDevice:(HeftRemoteDevice*)device sharedSecret:(NSData*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate;

/**
 Starts creation of a connection to the specified device.
 @param device					Device to be connected.
 @param sharedSecretString		Shared Secret information in string format
 @param aDelegate				Delegate which will be perform HeftStatusReportDelegate notifications.
 */
- (void)clientForDevice:(HeftRemoteDevice*)device sharedSecretString:(NSString*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate;

- (void)cleanup;

- (void)timerCallback;

@end

/*
@interface SimpleHeftManager
- (NSArray*) connectedCardReaders;

@property(nonatomic,readonly) HeftClient* cardReader;

@end
*/
