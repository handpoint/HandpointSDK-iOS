//
// Created by Juan Nuñez on 08/06/2018.
// Copyright (c) 2018 zdv. All rights reserved.
//

#import "MacOSBluetooth.h"
#import "HeftRemoteDevice.h"
#import "MacOSBluetoothClient.h"
#import "MpedDevice.h"
#import "MacOSConnection.h"
#import <IOBluetooth/IOBluetoothUserLib.h>
#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetooth/objc/IOBluetoothSDPServiceRecord.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

//00001101-0000-1000-8000-00805F9B34FB
unsigned char DATECS_UUID[] = {
        0x00, 0x00, 0x11, 0x01, 0x00, 0x00, 0x10, 0x00,
        0x80, 0x00, 0x00, 0x80, 0x5f, 0x9b, 0x34, 0xfb
};

@interface MacOSBluetooth ()

@property (nonatomic, copy) DeviceBlock connectBlock;
@property (nonatomic, copy) DeviceBlock disconnectBlock;
@property (nonatomic) NSArray *devices;
@property (nonatomic) IOBluetoothDeviceSelectorController *deviceSelector;
@property (nonatomic) IOBluetoothSDPUUID *chatServiceUUID;
@property (nonatomic) IOBluetoothSDPServiceRecord *chatServiceRecord;
//@property (nonatomic) IOBluetoothRFCOMMChannel *mRFCOMMChannel;

@end

@implementation MacOSBluetooth

- (instancetype)initWithDidConnectBlock:(DeviceBlock)connectBlock
                     didDisconnectBlock:(DeviceBlock)disconnectBlock
{
    self = [super init];

    if (self)
    {
        self.connectBlock = connectBlock;
        self.disconnectBlock = disconnectBlock;

        self.deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];

        // Create an IOBluetoothSDPUUID object for the chat service UUID
        self.chatServiceUUID = [IOBluetoothSDPUUID uuidWithBytes:DATECS_UUID length:16];

        // Tell the device selector what service we are interested in.
        // It will only allow the user to select devices that have that service.
        [self.deviceSelector addAllowedUUID:self.chatServiceUUID];
    }

    return self;
}

- (NSArray *)search:(VoidBlock)completed
{
    NSArray *tempDevices = @[];

    self.devices = tempDevices;

    if ( self.deviceSelector == nil )
    {
        NSLog( @"Error - unable to allocate IOBluetoothDeviceSelectorController.\n" );
        completed();
        return tempDevices;
    }

    // Run the device selector modal.  This won't return until the user has selected a device and the device has
    // been validated to contain the specified service or the user has hit the cancel button.
    if ( [self.deviceSelector runModal] != kIOBluetoothUISuccess )
    {
        NSLog( @"User has cancelled the device selection.\n" );
        completed();
        return tempDevices;
    }

    // Get the list of devices the user has selected.
    // By default, only one device is allowed to be selected.
    tempDevices = [self.deviceSelector getResults] ?: tempDevices;

    completed();
    return tempDevices;
}

- (void)connectToDevice:(HeftRemoteDevice *)device
       withSharedSecret:(NSString *)sharedSecret
               delegate:(id <HeftStatusReportDelegate>)delegate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        IOBluetoothDevice *selectedDevice = device.device;
        IOReturn status;
        UInt8 rfcommChannelID;
        //self.chatServiceRecord = [selectedDevice getServiceRecordForUUID:self.chatServiceUUID];
        //status = [self.chatServiceRecord getRFCOMMChannelID:&rfcommChannelID];
        status = [selectedDevice openConnection];
        IOBluetoothRFCOMMChannel *mRFCOMMChannel;


        if (status != kIOReturnSuccess)
        {
            NSLog(@"Error: 0x%lx opening connection to device.\n", status);
            return;
        }

        // Open the RFCOMM channel on the new device connection
        status = [selectedDevice openRFCOMMChannelSync:&mRFCOMMChannel
                                         withChannelID:rfcommChannelID
                                              delegate:self];
        if ((status == kIOReturnSuccess) && (mRFCOMMChannel != nil))
        {
            // And the return value is TRUE !!
            MacOSConnection *connection = [[MacOSConnection alloc] initWithRFCOMMChannel:mRFCOMMChannel];

            id <HeftClient> result = [[MpedDevice alloc] initWithConnection:connection
                                                               sharedSecret:sharedSecret
            dispatch_async(dispatch_get_main_queue(), ^
            {
                id <HeftStatusReportDelegate> tmp = delegate;
                [tmp didConnect:result];
            });

        }
        else
        {
            NSLog(@"Error: 0x%lx - unable to open RFCOMM channel.\n", status);
        }
    });
}

- (void)disconnect
{

}

- (void)cleanup
{

}

- (NSData *)read:(NSUInteger)dataLength
{
    return nil;
}

- (void)write:(NSData *)data
{

}


@end