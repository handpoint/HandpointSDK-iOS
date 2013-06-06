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

@protocol HeftClient;
@protocol HeftStatusReportDelegate;
@class HeftRemoteDevice;
@class DTDevices;

/** 
 @brief HeftDiscoveryDelegate protocol methods
 */
@protocol HeftDiscoveryDelegate
/** @defgroup HDD_PROTOCOL HeftDiscoveryDelegate Notifications
 Notifications sent by the SDK on various events - new available device found, connection lost, connection found, etc
 @{
 */

/**
 Notifies that Bluetooth is available.
 */
- (void)hasSources;
/**
 Notifies that Bluetooth isn't available anymore.
 */
- (void)noSources;
/**
 Notifies that new device was discovered.
 @param newDevice				Contains information(name, adress) about discovered device.
 */
- (void)didDiscoverDevice:(HeftRemoteDevice*)newDevice;
/**
 Notifies that search of all available devices was completed.
 */
- (void)didDiscoverFinished;

/**
 Notifies that new accessory device was connected.
 @param newDevice				Contains information(name, adress) about discovered device.
 */
- (void)didFindAccessoryDevice:(HeftRemoteDevice*)newDevice;
/**
 Notifies that accessory device was disconnected.
 @param oldDevice				Contains information(name) about disconnected device.
 */
- (void)didLostAccessoryDevice:(HeftRemoteDevice*)oldDevice;

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
 Start search for all available devices.
 @param fDiscoverAllDevices				Send didDiscoverDevice:(HeftRemoteDevice*)newDevice for found device, even if it's already in the stored array.
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
 @brief Current HeftManager version. 
 */
@property(nonatomic, readonly) NSString* version;

/**
 Performs hasSources request.
 @return YES if Bluetooth is available and NO if it isn't.
 */
- (BOOL)hasSources;

/**
 Starts creation of a connection to the specified device.
 @param device				Device to be connected.
 @param sharedSecret		Shared Secret information
 @param aDelegate			Delegate which will be perform HeftStatusReportDelegate notifications.
 */
- (void)clientForDevice:(HeftRemoteDevice*)device sharedSecret:(NSData*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate;

@end
