//
// Created by Juan Nuñez on 14/12/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HeftDiscoveryDelegate.h"


/**
 @brief HeftDiscovery protocol methods
 */
@protocol HeftDiscovery
/**
 @brief Stored array which contains all found devices.
 */
@property(nonatomic, readonly) NSMutableArray* devicesCopy;
/**
 Delegate object. Will handle notifications which contain in HeftDiscoveryDelegate protocol.
 */
@property(nonatomic, weak) id<HeftDiscoveryDelegate> delegate;
/**
 Start search for all available BT devices.
 @param fDiscoverAllDevices Send didDiscoverDevice:(HeftRemoteDevice*)newDevice for found device, even if it's already in the stored array.
 */
- (void)startDiscovery:(BOOL)fDiscoverAllDevices DEPRECATED_ATTRIBUTE;
/**
 Start search for all available BT devices.
 */
- (void)startDiscovery;
/**
 Clear array of all previously founded devices.
 */
- (void)resetDevices;

@end