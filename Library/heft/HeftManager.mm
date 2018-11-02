//
//  HeftManager.m
//  headstart
//

#import <Foundation/Foundation.h>
#import "HeftManager.h"
#import "HeftConnection.h"
#import "MpedDevice.h"
#import "HeftRemoteDevice.h"
#import "HeftStatusReportDelegate.h"
#import "debug.h"
#import "Version.h"
#import "BluetoothProvider.h"
#import "iOSBluetooth.h"
#import "iOSConnection.h"

#ifdef HEFT_SIMULATOR

#import "SimulatorAccessory.h"

#endif

NSString *eaProtocol = @"com.datecs.pinpad";

@interface HeftRemoteDevice ()

- (id)initWithAccessory:(EAAccessory *)accessory;

#ifdef HEFT_SIMULATOR
+ (instancetype)Simulator;
#endif

@end

@implementation HeftManager

//@synthesize delegate;

static dispatch_once_t onceToken;
static HeftManager *instance = nil;

+ (HeftManager *)sharedManager
{
    dispatch_once(&onceToken, ^
    {
        instance = [HeftManager new];
    });

    return instance;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        LOG(@"HeftManager::init");

#ifndef HEFT_SIMULATOR
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

#endif
    }

    return self;
}


- (void)clientForDevice:(HeftRemoteDevice *)device
           sharedSecret:(NSString *)sharedSecret
               delegate:(NSObject <HeftStatusReportDelegate> *)delegate
{
    [self asyncClientForDevice:device
                  sharedSecret:sharedSecret
                      delegate:delegate];
}

- (void)cleanup
{
    LOG(@"HeftManager::cleanup");
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    LOG(@"HeftManager::dealloc");
    [self cleanup];
}

- (void)asyncClientForDevice:(HeftRemoteDevice *)device
                sharedSecret:(NSString *)sharedSecret
                    delegate:(NSObject <HeftStatusReportDelegate> *)delegate
{
    @autoreleasepool
    {
#ifdef HEFT_SIMULATOR
        [NSThread sleepForTimeInterval:2];
        id <HeftClient> result = nil;
        result = [[MpedDevice alloc] initWithConnection:nil
                                           sharedSecret:sharedSecret
                                               delegate:delegate];

        dispatch_async(dispatch_get_main_queue(), ^
        {
            id <HeftStatusReportDelegate> tmp = delegate;
            [tmp didConnect:result];
        });
#else

        NSRunLoop *currentRunLoop = [NSRunLoop mainRunLoop];


        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            HeftConnection *connection = [[HeftConnection alloc] initWithDevice:device
                                                                        runLoop:currentRunLoop];

            id <HeftClient> result = [[MpedDevice alloc] initWithConnection:connection
                                                               sharedSecret:sharedSecret
                                                                   delegate:delegate];
            
            LOG(@"version: %@", self.version);
            
            dispatch_async(dispatch_get_main_queue(), ^
            {
                id <HeftStatusReportDelegate> tmp = delegate;
                [tmp didConnect:result];
            });

            [result logSetLevel:eLogFull];
        });

#endif

    }

}


#pragma mark property

- (NSString *)version
{
    NSString *version = CODE_GENERATED_VERSION;
    NSString *SDKVersion;
#ifdef HEFT_SIMULATOR
    //Simulator
    SDKVersion = [NSString stringWithFormat:@"%@ Simulator", version];
#else
#ifdef DEBUG
    //Debug
    SDKVersion = [NSString stringWithFormat:@"%@ Debug", version];
#else
    //Release
    SDKVersion = version;
#endif
#endif
    return SDKVersion;
}

- (NSArray *)devicesCopy
{
    return [self connectedCardReaders];
}

#pragma mark HeftDiscovery

- (void)startDiscovery
{
#ifdef HEFT_SIMULATOR
    [self performSelector:@selector(simulateDiscovery) withObject:nil afterDelay:5.];
#else
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
                                                [self.delegate didDiscoverFinished];
                                            }];
#endif
}

- (NSArray *)connectedCardReaders
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


#ifdef HEFT_SIMULATOR

static HeftRemoteDevice *simulatorAccessory = [HeftRemoteDevice Simulator];

- (void)simulateDiscovery
{
    if (simulatorAccessory == nil)
    {
        simulatorAccessory = [HeftRemoteDevice Simulator];
    }

    [self.delegate didFindAccessoryDevice:simulatorAccessory];
    [self.delegate didDiscoverFinished];
}

- (void)simulateDisconnect
{
    if (simulatorAccessory != nil)
    {
        [self.delegate didLostAccessoryDevice:simulatorAccessory];
        simulatorAccessory = nil;
    }
}

#endif


#pragma mark EAAccessory notificationss

- (void)EAAccessoryDidConnect:(NSNotification *)notification
{
    NSLog(@"EAAccessoryDidConnect");

    EAAccessory *accessory = notification.userInfo[EAAccessoryKey];
    if ([accessory.protocolStrings containsObject:eaProtocol])
    {
        HeftRemoteDevice *newDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];

        NSLog(@"didFindAccessoryDevice: %@ - %@", newDevice.name, newDevice.address);
        [self.delegate didFindAccessoryDevice:newDevice];
    }
}

- (void)EAAccessoryDidDisconnect:(NSNotification *)notification
{
    NSLog(@"EAAccessoryDidDisconnect");
    EAAccessory *accessory = notification.userInfo[EAAccessoryKey];

    if ([accessory.protocolStrings containsObject:eaProtocol])
    {
        HeftRemoteDevice *remoteDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];


        NSLog(@"didLostAccessoryDevice: %@ - %@", remoteDevice.name, remoteDevice.address);
        [self.delegate didLostAccessoryDevice:remoteDevice];
    }
}

#pragma mark - Utilities

// Convert Shared secret from NSString to NSData
- (NSData *)SharedSecretDataFromString:(NSString *)sharedSecretString;
{
    NSUInteger sharedSecretLength = 64; //Shared secret string length
    NSMutableData *data = [NSMutableData data];
    //Check if shared secret has correct length, othervise we create a string of zeros with the correct length. That will result in a "shared secret invalid"
    if ([sharedSecretString length] != sharedSecretLength)
    {
        LOG(@"Shared secret string must be exactly %@ characters.", @(sharedSecretLength));
        sharedSecretString = [@"0" stringByPaddingToLength:sharedSecretLength withString:@"0" startingAtIndex:0];
    }

    for (int i = 0; i < 32; i++)
    {
        NSUInteger index = static_cast<NSUInteger>(i * 2);
        NSRange range = NSMakeRange(index, 2);
        NSString *bytes = [sharedSecretString substringWithRange:range];
        NSScanner *scanner = [NSScanner scannerWithString:bytes];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

@end

#ifdef HEFT_SIMULATOR

void simulateDeviceDisconnect ()
{
    HeftManager *manager = [HeftManager sharedManager];
    [manager simulateDisconnect];
}

#endif
