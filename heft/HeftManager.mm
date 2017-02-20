//
//  LibObject.m
//  headstart
//


// #import "StdAfx.h"

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "HeftManager.h"
#import "HeftConnection.h"
#import "MpedDevice.h"
#import "HeftRemoteDevice.h"
#import "HeftStatusReportPublic.h"


#import "debug.h"

NSString* eaProtocol = @"com.datecs.pinpad";

@interface HeftRemoteDevice ()
- (id)initWithName:(NSString*)aName address:(NSString*)aAddress;
- (id)initWithAccessory:(EAAccessory*)aAccessory;
@end

#ifdef HEFT_SIMULATOR
@interface SimulatorAccessory: EAAccessory

@property(nonatomic, readonly, getter=isConnected) BOOL connected;
@property(nonatomic, readonly) NSUInteger connectionID;
@property(nonatomic, readonly) NSString *manufacturer;
@property(nonatomic, readonly) NSString *name;
@property(nonatomic, readonly) NSString *modelNumber;
@property(nonatomic, readonly) NSString *serialNumber;
@property(nonatomic, readonly) NSString *firmwareRevision;
@property(nonatomic, readonly) NSString *hardwareRevision;

// array of strings representing the protocols supported by the accessory
@property(nonatomic, readonly) NSArray *protocolStrings;

@end

@implementation SimulatorAccessory

@synthesize connected, connectionID, manufacturer, name, modelNumber, serialNumber, firmwareRevision, hardwareRevision, protocolStrings;

-(id) initWithConnectionID:(NSUInteger)newConnectionID
              manufacturer:(NSString*)newManufacturer
                      name:(NSString*)newName
               modelNumber:(NSString*)newModelNumber
              serialNumber:(NSString*)newSerialNumber
          firmwareRevision:(NSString*)newFirmwareRevision
          hardwareRevision:(NSString*)newHardwareRevision
           protocolStrings:(NSArray*)newProtocolStrings;
{
/*    if(!(self = [super init])){
        return nil;
    }
*/
    self->connectionID      = newConnectionID;
    self->manufacturer      = newManufacturer;
    self->name              = newName;
    self->modelNumber       = newModelNumber;
    self->serialNumber      = newSerialNumber;
    self->firmwareRevision  = newFirmwareRevision;
    self->hardwareRevision  = newHardwareRevision;
    self->protocolStrings   = newProtocolStrings;
    
    return self;
}

-(BOOL)isConnected
{
    return YES;
}
@end

#endif

@implementation HeftManager {
	BOOL fNotifyForAllDevices;
	NSMutableArray* eaDevices;
}

@synthesize devicesCopy, delegate;

static dispatch_once_t onceToken;
static HeftManager* instance = 0;

+ (HeftManager*)sharedManager
{
    dispatch_once(&onceToken, ^{
        instance = [HeftManager new];
    });
    
	return instance;
}

- (id)init
{
	if(self = [super init])
    {
		LOG(@"HeftManager::init");
		eaDevices = [NSMutableArray new];

#ifdef HEFT_SIMULATOR
        NSString* KEEN_PROJECT_ID = @"585180208db53dfda8a7bf78"; //So we can track the simulator development
        NSString* KEEN_WRITE_KEY = @"708E857964F9B97F1D6F83578A533F9B6B4A5C59FD611E228466156360DAA13DB30ACF66EAC9F8D542C3C4C99140C3B176F909080134314AE7FBF56A61EBD9B756B6A24FD219A8809A6FD3410E9026A6EF9D56AD961DA7D4DC912AC6E6D9FC15";
#else
    #ifdef DEBUG
        NSString* KEEN_PROJECT_ID = @"56afbb7e46f9a76bfe19bfdc";
        NSString* KEEN_WRITE_KEY = @"6460787402f46a7cafef91ec1d666cc37e14cc0f0bc26a0e3066bfc2e3c772d83a91a99f0ddec23a59fead9051e53bb2e2693201df24bd29eac9c78a61a2208993e9cef175bca6dc029ef28a93a0e5e135201bda7d6a98b2aa1f5aa76c5a4002";
    #else
        NSString* KEEN_PROJECT_ID = @"56afc865672e6c6e5a9dc431";
        NSString* KEEN_WRITE_KEY = @"68acf442839a15c214424f06d8b3298c2b0a9901e0cf3068977ad13d24b8e8e3590c853f2935772d632aefaef5c60b4f35383bd01fd8d65f9bf37a57f3ba2e6de21317e9f91ba1172ca79040e237e354b3f71c2147e3cca2250fb263a49d5a09";
    #endif

        NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
		[defaultCenter addObserver:self
                          selector:@selector(EAAccessoryDidConnect:)
                              name:EAAccessoryDidConnectNotification
                            object:nil];
        
		[defaultCenter addObserver:self
                          selector:@selector(EAAccessoryDidDisconnect:)
                              name:EAAccessoryDidDisconnectNotification
                            object:nil];

		EAAccessoryManager* eaManager = [EAAccessoryManager sharedAccessoryManager];
		[eaManager registerForLocalNotifications];

		NSArray* accessories = eaManager.connectedAccessories;
        
        [accessories enumerateObjectsUsingBlock:^(EAAccessory* accessory, NSUInteger idx, BOOL *stop) {
            if([accessory.protocolStrings containsObject:eaProtocol])
            {
                HeftRemoteDevice* newDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];
                [eaDevices addObject:newDevice];
            }
        }];
#endif

        [AnalyticsHelper setupAnalyticsWithGlobalProperties:[self analyticsGlobalProperties]
                                                  projectID:KEEN_PROJECT_ID
                                                   writeKey:KEEN_WRITE_KEY];

        //[AnalyticsHelper enableLogging];
        [AnalyticsHelper disableGeoLocation];
        [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"heftManager created" withOptionalParameters:nil];
        [AnalyticsHelper upload];

	}

	return self;
}

- (NSDictionary *)analyticsGlobalProperties
{
    UIDevice *currentDevice = [UIDevice currentDevice];

    NSDictionary *device = @{
            @"model" : [currentDevice model],
            @"systemName" : [currentDevice systemName],
            @"systemVersion" : [currentDevice systemVersion],
            @"deviceID" : [[currentDevice identifierForVendor] UUIDString]
    };

    NSBundle *mainBundle = [NSBundle mainBundle];

    NSDictionary *app = @{
            @"handpointSDKVersion" : [self getSDKVersion],
            @"bundleId" : [mainBundle bundleIdentifier],
            @"version" : [mainBundle infoDictionary][@"CFBundleShortVersionString"]
    };

    NSDictionary *properties = @{
            @"Device" : device,
            @"App" : app
    };

    return properties;
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

- (BOOL)hasSources
{
    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"hasSources" withOptionalParameters:@{@"deprecated": @"YES"}];

	return NO;
}

// this is a thread function, params is an array:
//                                params[0] = HeftRemoteDevice* device
//                                params[1] = NSData* sharedSecret
//                                params[2] = HeftStatusReportDelegate* delegate
- (void)asyncClientForDevice:(NSArray*)params
{
	@autoreleasepool
    {
        HeftRemoteDevice* device = params[0];
		NSData* sharedSecret = params[1];
		NSObject<HeftStatusReportDelegate>* aDelegate = params[2];
#ifdef HEFT_SIMULATOR
		[NSThread sleepForTimeInterval:2];
        id<HeftClient> result = nil;
		result = [[MpedDevice alloc] initWithConnection:nil
                                           sharedSecret:sharedSecret
                                               delegate:aDelegate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            id<HeftStatusReportDelegate> tmp = aDelegate;
            [tmp didConnect:result];
        });

        NSDictionary *mpedInfo = [result mpedInfo];
        [AnalyticsHelper addEventForActionType: actionTypeName.simulatorAction
                                Action: @"didConnect"
                withOptionalParameters: @{
                        @"serialnumber" : [utils ObjectOrNull:mpedInfo[kSerialNumberInfoKey]],
                        @"appNameInfoKey" : [utils ObjectOrNull:mpedInfo[kAppNameInfoKey]],
                        @"appVersionInfoKey" : [utils ObjectOrNull:mpedInfo[kAppVersionInfoKey]]

                }];

#else
       
        NSRunLoop* currentRunLoop = [NSRunLoop mainRunLoop];


        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            HeftConnection* connection = [[HeftConnection alloc] initWithDevice:device
                                                                        runLoop:currentRunLoop];
            
            id<HeftClient> result = nil;

            result = [[MpedDevice alloc] initWithConnection:connection
                                           sharedSecret:sharedSecret
                                               delegate:aDelegate];

            dispatch_async(dispatch_get_main_queue(), ^{
                id<HeftStatusReportDelegate> tmp = aDelegate;
                [tmp didConnect:result];
            });
            NSDictionary *mpedInfo = [result mpedInfo];
            [AnalyticsHelper addEventForActionType:actionTypeName.cardReaderAction Action:@"didConnect" withOptionalParameters:@{
                    @"serialnumber": [utils ObjectOrNull:mpedInfo[kSerialNumberInfoKey]],
                    @"appNameInfoKey": [utils ObjectOrNull:mpedInfo[kAppNameInfoKey]],
                    @"appVersionInfoKey": [utils ObjectOrNull:mpedInfo[kAppVersionInfoKey]]

            }];
            
        });
       
#endif

    }
    
}


- (void)clientForDevice:(HeftRemoteDevice*)device sharedSecret:(NSData*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate
{
    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"clientForDevice-NSData" withOptionalParameters:nil];
    [self asyncClientForDevice:@[device, sharedSecret, aDelegate]];
}


- (void)clientForDevice:(HeftRemoteDevice*)device sharedSecretString:(NSString*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate
{
    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"clientForDevice-NSString" withOptionalParameters:nil];

	NSData* sharedSecretData = [self SharedSecretDataFromString:sharedSecret];
    [self clientForDevice:device sharedSecret:sharedSecretData delegate:aDelegate];

}

#pragma mark property

- (NSString*)version
{
	return @"2.6.1";  // TODO: move this to a config file (include file or something else)
                      //       see old comment below
}

- (NSString*)buildNumber
{
	return @"1";
}

// A real kludge, need to automate this so it can be independent of Xcode project settings
- (NSString*)getSDKVersion
{
    NSString* SDKVersion;
#ifdef HEFT_SIMULATOR
    //Simulator
    SDKVersion = [NSString stringWithFormat:@"%@ Simulator",[self version]];
#else
    #ifdef DEBUG
        //Debug
        SDKVersion = [NSString stringWithFormat:@"%@ Debug",[self version]];
    #else
        //Release
        SDKVersion = [self version];
    #endif
#endif

    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"getSDKVersion" withOptionalParameters:@{
            @"SDKVersion": [utils ObjectOrNull:SDKVersion]
    }];
	
	return SDKVersion;
}

- (NSString*)getSDKBuildNumber
{
    NSString* SDKBuildNumber = [self buildNumber];

    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"getSDKBuildNumber" withOptionalParameters:@{
            @"SDKBuildNumber": [utils ObjectOrNull:SDKBuildNumber]
    }];
	
	return SDKBuildNumber;
}

- (NSMutableArray*)devicesCopy
{
    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"devicesCopy" withOptionalParameters:nil];

	NSMutableArray* result = [eaDevices mutableCopy];
	return result;
}

#pragma mark HeftDiscovery

- (void)startDiscovery:(BOOL)fDiscoverAllDevices
{
#ifdef HEFT_SIMULATOR

    [AnalyticsHelper addEventForActionType: actionTypeName.simulatorAction
                                    Action: @"startDiscovery"
                    withOptionalParameters: nil];

	[self performSelector:@selector(simulateDiscovery) withObject:nil afterDelay:5.];

#else

    [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"startDiscovery" withOptionalParameters:nil];

    // NSError* error = NULL;
    EAAccessoryManager* eaManager = [EAAccessoryManager sharedAccessoryManager];
    [eaManager showBluetoothAccessoryPickerWithNameFilter:nil
                                               completion:^(NSError* error) {
                                                   if (error) {
                                                       NSLog(@"showBluetoothAccessoryPickerWithNameFilter error :%@", error);
                                                   }
                                                   else{
                                                       NSLog(@"showBluetoothAccessoryPickerWithNameFilter working");
                                                   }
                                                   [delegate didDiscoverFinished];
                                               }];
#endif
}


- (NSArray*) connectedCardReaders
{
    EAAccessoryManager* eaManager = [EAAccessoryManager sharedAccessoryManager];

    NSMutableArray *readers = [NSMutableArray array];
    for (EAAccessory* device in eaManager.connectedAccessories)
    {
        for (NSString* protocol in device.protocolStrings)
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

- (void)resetDevices{
}

#pragma mark EAAccessory notificationss

- (void)EAAccessoryDidConnect:(NSNotification*)notification
{
    NSLog(@"EAAccessoryDidConnect");
    
	EAAccessory* accessory = notification.userInfo[EAAccessoryKey];
	if([accessory.protocolStrings containsObject:eaProtocol])
    {
		HeftRemoteDevice* newDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];
		[eaDevices addObject:newDevice];

        [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"didFindAccessoryDevice" withOptionalParameters:nil];

		[delegate didFindAccessoryDevice:newDevice];
	}
    else{
        NSLog(@"Empty EAAccessoryDidConnect notification");
    }
}

- (void)EAAccessoryDidDisconnect:(NSNotification*)notification
{
    NSLog(@"EAAccessoryDidDisconnect - # eaDevices %lu", (unsigned long)[eaDevices count]);
	EAAccessory* accessory = notification.userInfo[EAAccessoryKey];
	if([accessory.protocolStrings containsObject:eaProtocol] && [eaDevices count] > 0)
    {
		NSUInteger index = [eaDevices indexOfObjectPassingTest:^(HeftRemoteDevice* device, NSUInteger index, BOOL* stop) {
			if(device.accessory == accessory)
				*stop = YES;
			return *stop;
		}];
        
        if (index < [eaDevices count])
        {
            HeftRemoteDevice* eaDevice = eaDevices[index];
            [eaDevices removeObjectAtIndex:index];
            [AnalyticsHelper addEventForActionType:actionTypeName.managerAction Action:@"didLostAccessoryDevice" withOptionalParameters:nil];
            [delegate didLostAccessoryDevice:eaDevice]; // todo: stop calling this on delegate unless this is the connected device

            NSLog(@"EAAccessoryDidDisconnect index [%lu], device [%@]", (unsigned long)index, [eaDevice name]);
        }
        else
        {
            NSLog(@"EAAccessoryDidDisconnect index [%lu] out of bounds", (unsigned long)index);
        }
	}
    else
    {
        NSLog(@"Empty EAAccessoryDidDisconnect notification.");        
    }
}
 
#pragma mark Utilities

// Convert Shared secret from NSString to NSData
-(NSData*)SharedSecretDataFromString:(NSString*)sharedSecretString;
{
	NSInteger sharedSecretLength = 64; //Shared secret string length
	NSMutableData* data = [NSMutableData data];
	//Check if shared secret has correct length, othervise we create a string of zeros with the correct length. That will result in a "shared secret invalid"
	if ([sharedSecretString length] != sharedSecretLength)
	{
		LOG(@"Shared secret string must be exactly %ld characters.", (long)sharedSecretLength);
		sharedSecretString = [@"0" stringByPaddingToLength:sharedSecretLength withString:@"0" startingAtIndex:0];
	}
	
	for (int i = 0 ; i < 32; i++)
    {
		NSRange range = NSMakeRange (i*2, 2);
		NSString *bytes = [sharedSecretString substringWithRange:range];
		NSScanner* scanner = [NSScanner scannerWithString:bytes];
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
