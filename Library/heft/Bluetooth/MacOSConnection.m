//
// Created by Juan Nuñez on 09/06/2018.
// Copyright (c) 2018 zdv. All rights reserved.
//

#import <IOBluetooth/IOBluetooth.h>
#import "MacOSConnection.h"

@implementation MacOSConnection

- (instancetype)initWithRFCOMMChannel:(IOBluetoothRFCOMMChannel *)rFCOMMChannel
{
    self = [super init];

    if (self)
    {
       RFCOMMChannel = rFCOMMChannel;
    }

    return self;
}

- (void)shutdown
{
    if ( RFCOMMChannel != nil )
    {
        IOBluetoothDevice *device = [RFCOMMChannel getDevice];

        // This will close the RFCOMM channel and start an inactivity timer to close the baseband connection if no
        // other channels (L2CAP or RFCOMM) are open.
        [RFCOMMChannel closeChannel];

        // Release the channel object since we are done with it and it isn't useful anymore.
        RFCOMMChannel = nil;

        // This signals to the system that we are done with the baseband connection to the device.  If no other
        // channels are open, it will immediately close the baseband connection.
        [device closeConnection];
    }
}

- (void)resetData
{

}

- (void)writeData:(uint8_t *)data length:(int)len
{
    if ( RFCOMMChannel != nil )
    {
        UInt32				numBytesRemaining;
        IOReturn			result;
        BluetoothRFCOMMMTU	rfcommChannelMTU;

        numBytesRemaining = len;
        result = kIOReturnSuccess;

        // Get the RFCOMM Channel's MTU.  Each write can only contain up to the MTU size
        // number of bytes.
        rfcommChannelMTU = [RFCOMMChannel getMTU];

        // Loop through the data until we have no more to send.
        while ( ( result == kIOReturnSuccess ) && ( numBytesRemaining > 0 ) )
        {
            // finds how many bytes I can send:
            UInt32 numBytesToSend = ( ( numBytesRemaining > rfcommChannelMTU ) ? rfcommChannelMTU :  numBytesRemaining );

            // This method won't return until the buffer has been passed to the Bluetooth hardware to be sent to the remote device.
            // Alternatively, the asynchronous version of this method could be used which would queue up the buffer and return immediately.
            result = [RFCOMMChannel writeSync:data length:numBytesToSend];

            // Updates the position in the buffer:
            numBytesRemaining -= numBytesToSend;
            data += numBytesToSend;
        }

        // We are successful only if all the data was sent:
        if ( ( numBytesRemaining == 0 ) && ( result == kIOReturnSuccess ) )
        {
           // return TRUE;
        }
    }

    //return FALSE;
}

- (void)writeAck:(UInt16)ack
{

}

- (int)readData:(void*)buffer timeout:(eConnectionTimeout)timeout
{
    return 0;
}

- (UInt16)readAck
{
    return 0;
}

// Implementation of delegate calls (see IOBluetoothRFCOMMChannel.h) Only the basic ones:
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel*)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength;
{
    [mNewDataTarget performSelector:mHandleNewDataSelector withObject:[NSData dataWithBytes:dataPointer length:dataLength]];
}

- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel*)rfcommChannel;
{
    [mRemoteDisconnectionTarget performSelector:mHandleRemoteDisconnectionSelector];
}

@end