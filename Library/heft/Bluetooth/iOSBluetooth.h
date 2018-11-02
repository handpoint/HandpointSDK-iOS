//
// Created by Juan Nuñez on 06/06/2018.
// Copyright (c) 2018 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BluetoothProvider.h"


@interface iOSBluetooth : NSObject<BluetoothProvider>

- (instancetype)initWithDidConnectBlock:(DeviceBlock)connectBlock
             didDisconnectBlock:(DeviceBlock)disconnectBlock;

@end