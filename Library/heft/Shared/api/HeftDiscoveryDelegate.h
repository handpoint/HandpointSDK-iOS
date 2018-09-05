//
// Created by Juan Nuñez on 14/12/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@end