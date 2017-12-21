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
@property(nonatomic, readonly) NSArray* connectedCardReaders;
/**
 Delegate object. Will handle notifications which contain in HeftDiscoveryDelegate protocol.
 */
@property(nonatomic, weak) id<HeftDiscoveryDelegate> delegate;
/**
 Start search for all available BT devices.
 */
- (void)startDiscovery;

@end