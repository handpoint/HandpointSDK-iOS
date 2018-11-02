//
// Created by Juan Nuñez on 07/06/2018.
// Copyright (c) 2018 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IOBluetoothRFCOMMChannel;

@interface MacOSBluetoothClient : NSObject
{
    // This is the method to call in the UI when new data shows up:
    SEL	mHandleNewDataSelector;
    id	mNewDataTarget;

    // This is the method to call when the RFCOMM channel disappears:
    SEL	mHandleRemoteDisconnectionSelector;
    id	mRemoteDisconnectionTarget;
    IOBluetoothRFCOMMChannel	*mRFCOMMChannel;
}

// Returns the name of the local bluetooth device
- (NSString *)localDeviceName;

// Registers selector for incoming data:
// tells to this class to call myTarget and myTargetAction when new data shows up:
- (void)registerForNewData:(id)myTarget action:(SEL)actionMethod;

// Registers selector for disconnection:
// tells to this class to call myTarget and myTargetAction when the channel disconnects:
- (void)registerForTermination:(id)myTarget action:(SEL)actionMethod;

// Methods that must be implemented by the subclass

// Connection Method:
// returns TRUE if the connection was successful:
- (BOOL)connectToServer;

// Disconnection:
// closes the channel:
- (void)disconnectFromServer;

// Returns the name of the device we are connected to
// returns nil if not connection:
- (NSString *)remoteDeviceName;

// Send Data method
// returns TRUE if all the data was sent:
- (BOOL)sendData:(void *)buffer length:(UInt32)length;

// Implementation of delegate calls (see IOBluetoothRFCOMMChannel.h) Only the basic ones:
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength;
- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel;

@end

#endif	// !USE_C_API

