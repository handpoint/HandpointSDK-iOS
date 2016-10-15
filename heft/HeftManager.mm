//
//  LibObject.m
//  headstart
//


// #import "StdAfx.h"

#import "HeftManager.h"
#import "HeftConnection.h"
#import "MpedDevice.h"
#import "HeftRemoteDevice.h"
#import "HeftStatusReportPublic.h"
#import <UIKit/UIKit.h>

#import "debug.h"

//#define NSLog(...) [log2file appendFormat:@"%f:", CFAbsoluteTimeGetCurrent()];[log2file appendFormat:__VA_ARGS__];[log2file appendString:@"\n"]; \
//[log2file writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:NULL]

//NSString* file = nil;
//NSMutableString* log2file = nil;

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
    BOOL runLoopRunning;
	NSMutableArray* eaDevices;
}

@synthesize devicesCopy, delegate;

static HeftManager* instance = 0;

+ (void)initialize
{
	if(self == [HeftManager class]) {
		//file = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"log.txt"];
		//log2file = [NSMutableString string];
		//freopen([file cStringUsingEncoding:NSASCIIStringEncoding], "w+", stderr);
		LOG(@"HeftManager::initialize");
		instance = [HeftManager new];
	}
}

+ (HeftManager*)sharedManager
{
	return instance;
}

- (id)init
{
	if(self = [super init])
    {
		LOG(@"HeftManager::init");
		eaDevices = [NSMutableArray new];

#ifndef HEFT_SIMULATOR
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
        
		[accessories indexOfObjectWithOptions:NSEnumerationConcurrent
                                  passingTest:^(EAAccessory* accessory, NSUInteger idx, BOOL *stop){
                                      if([accessory.protocolStrings containsObject:eaProtocol]){
                                          HeftRemoteDevice* newDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];
                                          [eaDevices addObject:newDevice];
                                      }
                                      return NO;
                                  }];
#endif
	}
    
    KeenClient *keenClient = [KeenClient sharedClientWithProjectID:DEV_KEEN_PROJECTID andWriteKey:DEV_KEEN_WRITEKEY andReadKey: nil];
    [KeenClient enableLogging];
    [KeenClient disableGeoLocation];
    
    NSDictionary *device = [NSDictionary dictionaryWithObjectsAndKeys:
                            [[UIDevice currentDevice] model], @"model",
                            [[UIDevice currentDevice] systemName], @"systemName",
                            [[UIDevice currentDevice] systemVersion], @"systemVersion",
                            [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID",
                            nil];
    
    NSDictionary *app = [NSDictionary dictionaryWithObjectsAndKeys:
                         [self getSDKVersion], @"handpointSDKVersion",
                         [[NSBundle mainBundle] bundleIdentifier], @"bundleId",
                         [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], @"version",
                         nil];
    
    NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"heftManager created", @"action",
                           nil];
    
    
    keenClient.globalPropertiesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                             device, @"Device",
                                             app, @"App",
                                             nil];
    
    [[KeenClient sharedClient] addEvent:event toEventCollection:KEEN_MANAGERCREATED error:nil];
    [[KeenClient sharedClient] uploadWithFinishedBlock:nil];
    
	return self;
}


- (void)cleanup
{
    LOG(@"HeftManager::cleanup");
    [[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    runLoopRunning = NO; // stop the run loop
}

- (void)dealloc
{
	LOG(@"HeftManager::dealloc");
    [self cleanup];
}

- (BOOL)hasSources
{
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

#else
        
        NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            HeftRemoteDevice* device = params[0];
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
            
            NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"cardReaderAction", @"actionType",
                                   @"Card reader connected", @"action",
                                   [[result mpedInfo] objectForKey:kSerialNumberInfoKey], @"serialnumber",
                                   [[result mpedInfo] objectForKey:kAppNameInfoKey], @"appNameInfoKey",
                                   [[result mpedInfo] objectForKey:kAppVersionInfoKey], @"appVersionInfoKey",
                                   nil];
            [[KeenClient sharedClient] addEvent:event toEventCollection:KEEN_CARDREADERACTION error:nil];
            
        });
        
        // runloop
        {
            NSLog(@"Starting runloop in thread.");
            runLoopRunning = YES;
            
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:15
                                                              target:self
                                                            selector:@selector(timerCallback)
                                                            userInfo:nil
                                                             repeats:YES];
            
            while (runLoopRunning)
            {
                @autoreleasepool  // need a nested autoreleasepool. If it's not here the NSDate
                {                 // leaks memory like crazy in some situations.
                    [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
                }
            }
            
            [timer invalidate];

            NSLog(@"Runloop stopped.");
        }
#endif

    }
    
}

- (void)timerCallback
{
    // NSLog(@"Timer callback in HeftManager");
}


- (void)clientForDevice:(HeftRemoteDevice*)device sharedSecret:(NSData*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate
{
    [NSThread detachNewThreadSelector:@selector(asyncClientForDevice:)
                             toTarget:self
                           withObject:@[device, sharedSecret, aDelegate]];
}


- (void)clientForDevice:(HeftRemoteDevice*)device sharedSecretString:(NSString*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate
{
	NSData* sharedSecretData = [self SharedSecretDataFromString:sharedSecret];
    [self clientForDevice:device sharedSecret:sharedSecretData delegate:aDelegate];

}

#pragma mark property

- (NSString*)version
{
	return @"2.5.9";  // TODO: move this to a config file (include file or something else)
                      //       see old comment below
}

- (NSString*)buildNumber
{
	return @"1";
}

// A real kludge, need to automate this so it can be independent of Xcode project settings
- (NSString*)getSDKVersion
{
	NSString* SDKVersion = [self version];
	return SDKVersion;
}

- (NSString*)getSDKBuildNumber
{
	NSString* SDKBuildNumber = [self buildNumber];
	return SDKBuildNumber;
}

- (NSMutableArray*)devicesCopy
{
	NSMutableArray* result = [eaDevices mutableCopy];
	return result;
}

#pragma mark HeftDiscovery

- (void)startDiscovery:(BOOL)fDiscoverAllDevices
{
#ifdef HEFT_SIMULATOR
	[self performSelector:@selector(simulateDiscovery) withObject:nil afterDelay:5.];
#else
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

#pragma mark EAAccessory notifications

- (void)EAAccessoryDidConnect:(NSNotification*)notification
{
    NSLog(@"EAAccessoryDidConnect");
    
    // [self init];  TODO: who put this in here, should it be here?

	EAAccessory* accessory = notification.userInfo[EAAccessoryKey];
	if([accessory.protocolStrings containsObject:eaProtocol])
    {
		HeftRemoteDevice* newDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];
		[eaDevices addObject:newDevice];
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
            [delegate didLostAccessoryDevice:eaDevice];
            runLoopRunning = NO;

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
