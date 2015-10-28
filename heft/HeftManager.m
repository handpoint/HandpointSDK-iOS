//
//  LibObject.m
//  headstart
//


#import "StdAfx.h"

#import "HeftManager.h"
#import "HeftConnection.h"
#import "MpedDevice.h"
#import "HeftRemoteDevice.h"

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

-(id) initWithConnectionID:(NSUInteger)newConnectionID manufacturer:(NSString*)newManufacturer name:(NSString*)newName modelNumber:(NSString*)newModelNumber serialNumber:(NSString*)newSerialNumber firmwareRevision:(NSString*)newFirmwareRevision hardwareRevision:(NSString*)newHardwareRevision protocolStrings:(NSArray*)newProtocolStrings;
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

@implementation HeftManager{
	BOOL fNotifyForAllDevices;
	NSMutableArray* eaDevices;
}

@synthesize devicesCopy, delegate;

static HeftManager* instance = 0;

+ (void)initialize{
	if(self == [HeftManager class]){
		//file = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"log.txt"];
		//log2file = [NSMutableString string];
		//freopen([file cStringUsingEncoding:NSASCIIStringEncoding], "w+", stderr);
		LOG(@"HeftManager::initialize");
		instance = [HeftManager new];
	}
}

+ (HeftManager*)sharedManager{
	return instance;
}

- (id)init{
	if(self = [super init]){
		LOG(@"HeftManager::init");
		eaDevices = [NSMutableArray new];

#ifndef HEFT_SIMULATOR
		NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
		[defaultCenter addObserver:self selector:@selector(EAAccessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
		[defaultCenter addObserver:self selector:@selector(EAAccessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];

		EAAccessoryManager* eaManager = [EAAccessoryManager sharedAccessoryManager];
		[eaManager registerForLocalNotifications];

		NSArray* accessories = eaManager.connectedAccessories;
		[accessories indexOfObjectWithOptions:NSEnumerationConcurrent passingTest:^(EAAccessory* accessory, NSUInteger idx, BOOL *stop){
			if([accessory.protocolStrings containsObject:eaProtocol]){
				HeftRemoteDevice* newDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];
				[eaDevices addObject:newDevice];
			}
			return NO;
		}];

#endif
	}
	return self;
}

- (void)dealloc{
	LOG(@"HeftManager::dealloc");
	[[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)hasSources{
	return NO;
}

// this is a thread function, params is an array:
//                                params[0] = device
//                                params[1] = sharedSecret
//                                params[2] = delegate
- (void)asyncClientForDevice:(NSArray*)params{
	@autoreleasepool{
		id<HeftClient> result = nil;
		NSData* sharedSecret = params[1];
		NSObject<HeftStatusReportDelegate>* aDelegate = params[2];
#if HEFT_SIMULATOR
		[NSThread sleepForTimeInterval:2];
		result = [[MpedDevice alloc] initWithConnection:nil sharedSecret:sharedSecret delegate:aDelegate];
#else
		HeftRemoteDevice* device = params[0];
		result = [[MpedDevice alloc] initWithConnection:[[HeftConnection alloc] initWithDevice:device] sharedSecret:sharedSecret delegate:aDelegate];
#endif
		[aDelegate performSelectorOnMainThread:@selector(didConnect:) withObject:result waitUntilDone:NO];
	}
}

- (void)clientForDevice:(HeftRemoteDevice*)device sharedSecret:(NSData*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate{
	[NSThread detachNewThreadSelector:@selector(asyncClientForDevice:)
                             toTarget:self
                           withObject:@[device, sharedSecret, aDelegate]];
}
- (void)clientForDevice:(HeftRemoteDevice*)device sharedSecretString:(NSString*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate{
	NSData* sharedSecretData = [self SharedSecretDataFromString:sharedSecret];
	[NSThread detachNewThreadSelector:@selector(asyncClientForDevice:)
                             toTarget:self
                           withObject:@[device, sharedSecretData, aDelegate]];
}

#pragma mark property

- (NSString*)version{
	return @"2.4.1";
}

- (NSString*)buildNumber {
	return @"1";
}

// A real kludge, need to automate this so it can be independent of Xcode project settings
- (NSString*)getSDKVersion{
	NSString* SDKVersion = [self version];
	return SDKVersion;
}

- (NSString*)getSDKBuildNumber{
	NSString* SDKBuildNumber = [self buildNumber];
	return SDKBuildNumber;
}

- (NSMutableArray*)devicesCopy{
	NSMutableArray* result = [eaDevices mutableCopy];
	return result;
}

#pragma mark HeftDiscovery

- (void)startDiscovery:(BOOL)fDiscoverAllDevices{
#if HEFT_SIMULATOR
	[self performSelector:@selector(simulateDiscovery) withObject:nil afterDelay:5.];
#else
    NSError* error = NULL;
    EAAccessoryManager* eaManager = [EAAccessoryManager sharedAccessoryManager];
    [eaManager showBluetoothAccessoryPickerWithNameFilter:nil completion:^(NSError* error){
        [delegate didDiscoverFinished];
    }];
#endif
}

#if HEFT_SIMULATOR
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

- (void)EAAccessoryDidConnect:(NSNotification*)notification{
	EAAccessory* accessory = notification.userInfo[EAAccessoryKey];
	if([accessory.protocolStrings containsObject:eaProtocol]){
		HeftRemoteDevice* newDevice = [[HeftRemoteDevice alloc] initWithAccessory:accessory];
		[eaDevices addObject:newDevice];
		[delegate didFindAccessoryDevice:newDevice];
	}
}

- (void)EAAccessoryDidDisconnect:(NSNotification*)notification{
	EAAccessory* accessory = notification.userInfo[EAAccessoryKey];
	if([accessory.protocolStrings containsObject:eaProtocol]){
		NSUInteger index = [eaDevices indexOfObjectPassingTest:^(HeftRemoteDevice* device, NSUInteger index, BOOL* stop){
			if(device.accessory == accessory)
				*stop = YES;
			return *stop;
		}];
		HeftRemoteDevice* eaDevice = eaDevices[index];
		[eaDevices removeObjectAtIndex:index];
		[delegate didLostAccessoryDevice:eaDevice];
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
	
	for (int i = 0 ; i < 32; i++) {
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
