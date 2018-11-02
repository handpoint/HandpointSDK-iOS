//
// Created by Juan Nuñez on 06/06/2018.
// Copyright (c) 2018 zdv. All rights reserved.
//

#import "iOSBluetooth.h"
#import "HeftRemoteDevice.h"
#import "iOSConnection.h"
#import "HeftClient.h"
#import "HeftStatusReportDelegate.h"
#import "debug.h"
#import "MpedDevice.h"

NSString *eaProtocol = @"com.datecs.pinpad";

@interface HeftRemoteDevice ()

- (id)initWithAccessory:(EAAccessory *)accessory;

#ifdef HEFT_SIMULATOR
+ (instancetype)Simulator;
#endif

@end

@interface iOSBluetooth ()
@property (nonatomic, copy) DeviceBlock connectBlock;
@property (nonatomic, copy) DeviceBlock disconnectBlock;
@end

@implementation iOSBluetooth

- (instancetype)initWithDidConnectBlock:(DeviceBlock)connectBlock
                     didDisconnectBlock:(DeviceBlock)disconnectBlock
{
    self = [super init];

    if (self)
    {
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self
                          selector:@selector(EAAccessoryDidConnect:)
                              name:EAAccessoryDidConnectNotification
                            object:nil];

        [defaultCenter addObserver:self
                          selector:@selector(EAAccessoryDidDisconnect:)
                              name:EAAccessoryDidDisconnectNotification
                            object:nil];

        EAAccessoryManager *eaManager = [EAAccessoryManager sharedAccessoryManager];
        [eaManager registerForLocalNotifications];

        self.connectBlock = connectBlock;
        self.disconnectBlock = disconnectBlock;
    }

    return self;
}


- (NSArray *)devices
{
    EAAccessoryManager *eaManager = [EAAccessoryManager sharedAccessoryManager];

    NSMutableArray *readers = [NSMutableArray array];
    for (EAAccessory *device in eaManager.connectedAccessories)
    {
        for (NSString *protocol in device.protocolStrings)
        {
            if ([protocol isEqualToString:eaProtocol])
            {
                HeftRemoteDevice *remoteDevice = [[HeftRemoteDevice alloc] initWithAccessory:device];
                [readers addObject:remoteDevice];
            }
        }
    }
    return readers;
}

- (NSArray *)search:(VoidBlock)completed
{
    [[EAAccessoryManager sharedAccessoryManager]
            showBluetoothAccessoryPickerWithNameFilter:nil
                                            completion:^(NSError *error)
                                            {
                                                if (error)
                                                {
                                                    NSLog(@"showBluetoothAccessoryPickerWithNameFilter error :%@", error);
                                                }
                                                else
                                                {
                                                    NSLog(@"showBluetoothAccessoryPickerWithNameFilter working");
                                                }
                                                completed();
                                            }];
}

- (void)connectToDevice:(HeftRemoteDevice *)device
       withSharedSecret:(NSString *)sharedSecret
               delegate:(id <HeftStatusReportDelegate>)delegate
{

    NSRunLoop *currentRunLoop = [NSRunLoop mainRunLoop];


    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        iOSConnection *connection = [[iOSConnection alloc] initWithDevice:device
                                                                    runLoop:currentRunLoop];

        id <HeftClient> result = [[MpedDevice alloc] initWithConnection:connection
                                                           sharedSecret:sharedSecret
                                                               delegate:delegate];

        dispatch_async(dispatch_get_main_queue(), ^
        {
            id <HeftStatusReportDelegate> tmp = delegate;
            [tmp didConnect:result];
        });

        NSDictionary *mpedInfo = [result mpedInfo];
        [AnalyticsHelper addEventForActionType:actionTypeName.cardReaderAction
                                        Action:@"didConnect"
                        withOptionalParameters:@{
                                @"serialnumber": [utils ObjectOrNull:mpedInfo[kSerialNumberInfoKey]],
                                @"appNameInfoKey": [utils ObjectOrNull:mpedInfo[kAppNameInfoKey]],
                                @"appVersionInfoKey": [utils ObjectOrNull:mpedInfo[kAppVersionInfoKey]],
                                @"xml": [utils ObjectOrNull:[AnalyticsHelper XMLtoDict:mpedInfo]]

                        }];

        [result logSetLevel:eLogFull];
    });
}

- (void)disconnect
{

}

- (void)cleanup
{
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSData *)read:(NSUInteger)dataLength
{
    return nil;
}

- (void)write:(NSData *)data
{

}


#pragma mark EAAccessory notificationss

- (void)EAAccessoryDidConnect:(NSNotification *)notification
{
    NSLog(@"EAAccessoryDidConnect");

    EAAccessory *accessory = notification.userInfo[EAAccessoryKey];
    if ([accessory.protocolStrings containsObject:eaProtocol])
    {
        HeftRemoteDevice *newDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];

        [AnalyticsHelper addEventForActionType:actionTypeName.managerAction
                                        Action:@"didFindAccessoryDevice"
                        withOptionalParameters:nil];

        NSLog(@"didFindAccessoryDevice: %@ - %@", newDevice.name, newDevice.address);

        self.connectBlock(newDevice);
    }

}

- (void)EAAccessoryDidDisconnect:(NSNotification *)notification
{
    NSLog(@"EAAccessoryDidDisconnect");
    EAAccessory *accessory = notification.userInfo[EAAccessoryKey];

    if ([accessory.protocolStrings containsObject:eaProtocol])
    {
        [AnalyticsHelper addEventForActionType:actionTypeName.managerAction
                                        Action:@"didLostAccessoryDevice"
                        withOptionalParameters:nil];

        HeftRemoteDevice *remoteDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];


        NSLog(@"didLostAccessoryDevice: %@ - %@", remoteDevice.name, remoteDevice.address);
        self.disconnectBlock(remoteDevice);
    }
}

@end