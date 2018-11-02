//
// Created by Juan Nuñez on 08/06/2018.
// Copyright (c) 2018 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BluetoothProvider.h"

FOUNDATION_EXPORT unsigned char DATECS_UUID[];	//00001101-0000-1000-8000-00805F9B34FB


@interface MacOSBluetooth : NSObject<BluetoothProvider>

@property (nonatomic, readonly) NSArray *devices;

- (instancetype)initWithDidConnectBlock:(DeviceBlock)connectBlock
                     didDisconnectBlock:(DeviceBlock)disconnectBlock;

@end