//
//  LibObject.m
//  headstart
//

#import <DTDevices.h>

#import "StdAfx.h"

#import "HeftManager.h"
#import "HeftConnection.h"
#import "MpedDevice.h"
#import "HeftRemoteDevice.h"

//#define NSLog(...) [log2file appendFormat:@"%f:", CFAbsoluteTimeGetCurrent()];[log2file appendFormat:__VA_ARGS__];[log2file appendString:@"\n"]; \
//[log2file writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:NULL]

//NSString* file = nil;
//NSMutableString* log2file = nil;

#if HEFT_SIMULATOR
NSString* devicesFileName = @"devices_simulator";
#else
NSString* devicesFileName = @"devices";
#endif

NSString* eaProtocol = @"com.datecs.pinpad";

@interface HeftRemoteDevice ()
- (id)initWithName:(NSString*)aName address:(NSString*)aAddress;
- (id)initWithAccessory:(EAAccessory*)aAccessory;
@end


@implementation HeftManager{
	DTDevices *dtdev;
	BOOL hasBluetooth;
	NSMutableArray* devices;
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

NSString* devicesPath(){
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:devicesFileName];
}

- (id)init{
	if(self = [super init]){
		LOG(@"HeftManager::init");
		devices = [NSKeyedUnarchiver unarchiveObjectWithFile:devicesPath()];
		if(!devices)
			devices = [NSMutableArray new];
		eaDevices = [NSMutableArray new];

#if HEFT_SIMULATOR
		[self performSelectorOnMainThread:@selector(asyncSimulatorInit) withObject:nil waitUntilDone:NO];
#else
		dtdev = [DTDevices sharedDevice];
		[dtdev addDelegate:self];
		[dtdev connect];
		
		NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
		[defaultCenter addObserver:self selector:@selector(EAAccessoryDidConnect:) name:EAAccessoryDidConnectNotification object:nil];
		[defaultCenter addObserver:self selector:@selector(EAAccessoryDidDisconnect:) name:EAAccessoryDidDisconnectNotification object:nil];

		EAAccessoryManager* eaManager = [EAAccessoryManager sharedAccessoryManager];
		[eaManager registerForLocalNotifications];

		NSArray* accessories = eaManager.connectedAccessories;
		[accessories indexOfObjectWithOptions:NSEnumerationConcurrent passingTest:^(EAAccessory* accessory, NSUInteger idx, BOOL *stop){
			LOG(@"%@", accessory.protocolStrings);
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

#if HEFT_SIMULATOR
- (void)asyncSimulatorInit{
	[self connectionState:CONN_CONNECTING];
	[self connectionState:CONN_CONNECTED];
	[self deviceFeatureSupported:FEAT_BLUETOOTH value:YES];
}
#endif

- (void)dealloc{
	LOG(@"HeftManager::dealloc");
	[dtdev disconnect];
	[[EAAccessoryManager sharedAccessoryManager] unregisterForLocalNotifications];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)hasSources{
	return hasBluetooth;
}

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
	[NSThread detachNewThreadSelector:@selector(asyncClientForDevice:) toTarget:self withObject:@[device, sharedSecret, aDelegate]];
}

#pragma mark property

- (NSString*)version{
	return @"2.0";
}

- (NSMutableArray*)devicesCopy{
	NSMutableArray* result = [eaDevices mutableCopy];
	if(hasBluetooth)
		[result addObjectsFromArray:devices];
	return result;
}

#pragma mark HeftDiscovery

- (void)startDiscovery:(BOOL)fDiscoverAllDevices{
	if(hasBluetooth){
		LOG(@"bluetooth discovery started");
		fNotifyForAllDevices = fDiscoverAllDevices;
#if HEFT_SIMULATOR
		[self performSelector:@selector(simulateDiscovery) withObject:nil afterDelay:5.];
#else
		NSError* error = NULL;
		[dtdev btDiscoverPinpadsInBackground:&error];
		//[dtdev btDiscoverDevicesInBackground:10 maxTime:200 codTypes:0 error:&error];
#endif
	}
}

#if HEFT_SIMULATOR
- (void)simulateDiscovery{
	[self bluetoothDeviceDiscovered:@"" name:@"Simulator"];
	[self bluetoothDiscoverComplete:YES];
}
#endif

- (void)resetDevices{
	devices = [NSMutableArray new];
	[NSKeyedArchiver archiveRootObject:devices toFile:devicesPath()];
}

#pragma mark DTDeviceDelegate

const char* stateLabel[] = {"disconnected", "connecting", "connected"};

-(void)connectionState:(int)state {
	LOG(@"connectionState: %s", stateLabel[state]);
	switch (state) {
		case CONN_DISCONNECTED:
			break;
		case CONN_CONNECTING:
			hasBluetooth = NO;
			[delegate noSources];
			break;
		case CONN_CONNECTED:{
			/*NSError* __autoreleasing error = nil;
			BOOL b = [dtdev btEnableWriteCaching:NO error:&error];
			LOG(@"caching success:%d error: %@", b, error);*/
		}
	}
}

-(void)deviceFeatureSupported:(int)feature value:(int)value{
	if(feature == FEAT_BLUETOOTH && value && !hasBluetooth){
		LOG(@"bluetooth supported");
		hasBluetooth = YES;
		[delegate hasSources];
		/*NSError* __autoreleasing error = nil;
		BOOL b = [dtdev setActiveDeviceType:DEVICE_TYPE_PINPAD error:&error];
		LOG(@"setActiveDeviceType:DEVICE_TYPE_PINPAD success:%d error: %@", b, error);*/
	}
}

-(void)bluetoothDiscoverComplete:(BOOL)success{
	Assert(success);
	LOG(@"bluetooth discovery completed");
	[NSKeyedArchiver archiveRootObject:devices toFile:devicesPath()];
	[delegate didDiscoverFinished];
}

-(void)bluetoothDeviceDiscovered:(NSString *)btAddress name:(NSString *)btName{
	LOG(@"bluetooth device %@ with address %@ is discovered", btName, btAddress);
	NSUInteger index = [devices indexOfObjectPassingTest:^(HeftRemoteDevice* obj, NSUInteger idx, BOOL *stop){
		if([obj.address isEqualToString:btAddress])
			*stop = YES;
		return *stop;
	}];
	if(index == NSNotFound){
		HeftRemoteDevice* newDevice = [[HeftRemoteDevice alloc] initWithName:btName address:btAddress];
		[devices addObject:newDevice];
		[delegate didDiscoverDevice:newDevice];
	}
	else if(fNotifyForAllDevices){
		[delegate didDiscoverDevice:devices[index]];
	}
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
		int index = [eaDevices indexOfObjectPassingTest:^(HeftRemoteDevice* device, NSUInteger index, BOOL* stop){
			if(device.accessory == accessory)
				*stop = YES;
			return *stop;
		}];
		HeftRemoteDevice* eaDevice = eaDevices[index];
		[delegate didLostAccessoryDevice:eaDevice];
		[eaDevices removeObjectAtIndex:index];
	}
}

@end
