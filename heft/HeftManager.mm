//
//  HeftManager.m
//  headstart
//


// #import "StdAfx.h"

#import <Foundation/Foundation.h>
#import "HeftManager.h"
#import "HeftConnection.h"
#import "MpedDevice.h"
#import "HeftRemoteDevice.h"
#import "HeftStatusReportDelegate.h"
#import "debug.h"
#import "AnalyticsConfig.h"

NSString *eaProtocol = @"com.datecs.pinpad";

@interface HeftRemoteDevice ()
- (id)initWithName:(NSString *)aName address:(NSString *)aAddress;

- (id)initWithAccessory:(EAAccessory *)aAccessory;
@end

@implementation HeftManager
{
    NSMutableArray *eaDevices;
}

@synthesize devicesCopy, delegate;

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
    if (self = [super init])
    {
        LOG(@"HeftManager::init");
        eaDevices = [NSMutableArray new];

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

        NSArray *accessories = eaManager.connectedAccessories;

        [accessories enumerateObjectsUsingBlock:^(EAAccessory *accessory, NSUInteger idx, BOOL *stop)
        {
            if ([accessory.protocolStrings containsObject:eaProtocol])
            {
                HeftRemoteDevice *newDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];
                [eaDevices addObject:newDevice];
            }
        }];
#endif
        AnalyticsConfig *analyticsConfig = [AnalyticsConfig new];

        [AnalyticsHelper setupAnalyticsWithVersion:[self version]
                                         projectID:analyticsConfig.KeenProjectID
                                          writeKey:analyticsConfig.KeenWriteKey];

        //[AnalyticsHelper enableLogging];
        [AnalyticsHelper disableGeoLocation];
        [AnalyticsHelper addEventForActionType:actionTypeName.managerAction
                                        Action:@"heftManager created"
                        withOptionalParameters:nil];
        [AnalyticsHelper upload];

    }

    return self;
}


- (void)clientForDevice:(HeftRemoteDevice *)device
           sharedSecret:(NSString *)sharedSecret
               delegate:(NSObject <HeftStatusReportDelegate> *)delegate
{
    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction
                                    Action:@"clientForDevice-NSString"
                    withOptionalParameters:nil];

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
                    delegate:(id <HeftStatusReportDelegate>)delegate
{
    @autoreleasepool
    {
        NSData *sharedSecretData = [self SharedSecretDataFromString:sharedSecret];

#ifdef HEFT_SIMULATOR
        [NSThread sleepForTimeInterval:2];
        id<HeftClient> result = nil;
        result = [[MpedDevice alloc] initWithConnection:nil
                                           sharedSecret:sharedSecretData
                                               delegate:delegate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            id<HeftStatusReportDelegate> tmp = delegate;
            [tmp didConnect:result];
        });

        NSDictionary *mpedInfo = [result mpedInfo];
        [AnalyticsHelper addEventForActionType: actionTypeName.simulatorAction
                                Action: @"didConnect"
                withOptionalParameters: @{
                        @"serialnumber" : [utils ObjectOrNull:mpedInfo[kSerialNumberInfoKey]],
                        @"appNameInfoKey" : [utils ObjectOrNull:mpedInfo[kAppNameInfoKey]],
                                    @"appVersionInfoKey" : [utils ObjectOrNull:mpedInfo[kAppVersionInfoKey]],
                                    @"xml" : [utils ObjectOrNull:[AnalyticsHelper XMLtoDict:mpedInfo]]

                }];

#else

        NSRunLoop *currentRunLoop = [NSRunLoop mainRunLoop];


        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            HeftConnection *connection = [[HeftConnection alloc] initWithDevice:device
                                                                        runLoop:currentRunLoop];

            id <HeftClient> result = nil;

            result = [[MpedDevice alloc] initWithConnection:connection
                                               sharedSecret:sharedSecretData
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
                                    @"appVersionInfoKey" : [utils ObjectOrNull:mpedInfo[kAppVersionInfoKey]],
                                    @"xml" : [utils ObjectOrNull:[AnalyticsHelper XMLtoDict:mpedInfo]]

                            }];

        });

#endif

    }

}


#pragma mark property

// A real kludge, need to automate this so it can be independent of Xcode project settings
- (NSString *)version
{
    NSString *version = @"2.6.2";
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

    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction
                                    Action:@"getSDKVersion"
                    withOptionalParameters:@{
                            @"SDKVersion": [utils ObjectOrNull:SDKVersion]
                    }];

    return SDKVersion;
}

- (NSMutableArray *)devicesCopy
{
    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction
                                    Action:@"devicesCopy"
                    withOptionalParameters:nil];

    NSMutableArray *result = [eaDevices mutableCopy];
    return result;
}

#pragma mark HeftDiscovery

- (void)startDiscovery:(BOOL)fDiscoverAllDevices
{
    [self startDiscovery];
}

- (void)startDiscovery
{
#ifdef HEFT_SIMULATOR

    [AnalyticsHelper addEventForActionType: actionTypeName.simulatorAction
                                    Action: @"startDiscovery"
                    withOptionalParameters: nil];

    [self performSelector:@selector(simulateDiscovery) withObject:nil afterDelay:5.];

#else

    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction
                                    Action:@"startDiscovery"
                    withOptionalParameters:nil];

    // NSError* error = NULL;
    EAAccessoryManager *eaManager = [EAAccessoryManager sharedAccessoryManager];
    [eaManager showBluetoothAccessoryPickerWithNameFilter:nil
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
                [readers addObject:device];
            }
        }
    }
    return readers;
}


#ifdef HEFT_SIMULATOR
static EAAccessory* simulatorAccessory = nil;

- (void)simulateDiscovery{
    if(simulatorAccessory == nil) {
        simulatorAccessory = [[SimulatorAccessory alloc] initWithConnectionID:24373085 manufacturer:@"Handpoint" name:@"Simulator" modelNumber:@"" serialNumber:@"123400123" firmwareRevision:@"2.2.7" hardwareRevision:@"1.0.0" protocolStrings:@[eaProtocol]];
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithObjects:@[simulatorAccessory] forKeys:@[EAAccessoryKey]];
        NSNotification* notification = [[NSNotification alloc] initWithName:@"EAAccessoryDidConnectNotification" object:nil userInfo:dictionary];
        [self EAAccessoryDidConnect:notification];
        [delegate didDiscoverFinished];
    }
}

- (void)simulateDisconnect{
    if(simulatorAccessory != nil) {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithObjects:@[simulatorAccessory] forKeys:@[EAAccessoryKey]];
        NSNotification* notification = [[NSNotification alloc] initWithName:@"EAAccessoryDidDisconnectNotification" object:nil userInfo:dictionary];
        [self EAAccessoryDidDisconnect:notification];
        simulatorAccessory = nil;
    }
}
#endif

- (void)resetDevices
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
        [eaDevices addObject:newDevice];

        [AnalyticsHelper addEventForActionType:actionTypeName.managerAction
                                        Action:@"didFindAccessoryDevice"
                        withOptionalParameters:nil];

        [delegate didFindAccessoryDevice:newDevice];
    }
    else
    {
        NSLog(@"Empty EAAccessoryDidConnect notification");
    }
}

- (void)EAAccessoryDidDisconnect:(NSNotification *)notification
{
    NSLog(@"EAAccessoryDidDisconnect - # eaDevices %lu", (unsigned long) [eaDevices count]);
    EAAccessory *accessory = notification.userInfo[EAAccessoryKey];
    if ([accessory.protocolStrings containsObject:eaProtocol] && [eaDevices count] > 0)
    {
        NSUInteger index = [eaDevices indexOfObjectPassingTest:^(HeftRemoteDevice *device, NSUInteger index, BOOL *stop)
        {
            if (device.accessory == accessory)
            {
                *stop = YES;
            }
            return *stop;
        }];

        if (index < [eaDevices count])
        {
            HeftRemoteDevice *eaDevice = eaDevices[index];
            [eaDevices removeObjectAtIndex:index];
            [AnalyticsHelper addEventForActionType:actionTypeName.managerAction
                                            Action:@"didLostAccessoryDevice"
                            withOptionalParameters:nil];
            [delegate didLostAccessoryDevice:eaDevice]; // todo: stop calling this on delegate unless this is the connected device

            NSLog(@"EAAccessoryDidDisconnect index [%lu], device [%@]", (unsigned long) index, [eaDevice name]);
        }
        else
        {
            NSLog(@"EAAccessoryDidDisconnect index [%lu] out of bounds", (unsigned long) index);
        }
    }
    else
    {
        NSLog(@"Empty EAAccessoryDidDisconnect notification.");
    }
}

#pragma mark - Utilities

// Convert Shared secret from NSString to NSData
- (NSData *)SharedSecretDataFromString:(NSString *)sharedSecretString;
{
    NSInteger sharedSecretLength = 64; //Shared secret string length
    NSMutableData *data = [NSMutableData data];
    //Check if shared secret has correct length, othervise we create a string of zeros with the correct length. That will result in a "shared secret invalid"
    if ([sharedSecretString length] != sharedSecretLength)
    {
        LOG(@"Shared secret string must be exactly %ld characters.", (long) sharedSecretLength);
        sharedSecretString = [@"0" stringByPaddingToLength:sharedSecretLength withString:@"0" startingAtIndex:0];
    }

    for (int i = 0; i < 32; i++)
    {
        NSRange range = NSMakeRange(i * 2, 2);
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
void simulateDeviceDisconnect()
{
    HeftManager* manager = [HeftManager sharedManager];
    [manager simulateDisconnect];
}
#endif
