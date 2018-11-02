//
// Created by Juan Nuñez on 09/06/2018.
// Copyright (c) 2018 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Connection.h"

@class IOBluetoothRFCOMMChannel;


@interface MacOSConnection : NSObject<Connection>
{
    IOBluetoothRFCOMMChannel	*RFCOMMChannel;

    // This is the method to call in the UI when new data shows up:
    SEL	mHandleNewDataSelector;
    id	mNewDataTarget;

    // This is the method to call when the RFCOMM channel disappears:
    SEL	mHandleRemoteDisconnectionSelector;
    id	mRemoteDisconnectionTarget;
}

@property(nonatomic) int maxFrameSize;
@property(nonatomic) int ourBufferSize;

- (instancetype)initWithRFCOMMChannel:(IOBluetoothRFCOMMChannel *)rFCOMMChannel;

@end