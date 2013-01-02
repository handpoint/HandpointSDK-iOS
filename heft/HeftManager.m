//
//  LibObject.m
//  headstart
//

#import <DTDevices.h>

#import "HeftManager.h"
#import "HeftConnection.h"
#import "MpedDevice.h"
#import "HeftRemoteDevice.h"

//#define NSLog(...) [log2file appendFormat:@"%f:", CFAbsoluteTimeGetCurrent()];[log2file appendFormat:__VA_ARGS__];[log2file appendString:@"\n"]; \
//[log2file writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:NULL]

//NSString* file = nil;
//NSMutableString* log2file = nil;

@interface HeftRemoteDevice ()
- (id)initWithName:(NSString*)aName address:(NSString*)aAddress;
@end


@implementation HeftManager

@synthesize devices, delegate;

static HeftManager* instance = 0;

+ (void)initialize{
	if(self == [HeftManager class]){
		//file = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"log.txt"];
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
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"devices"];
}

- (id)init{
	if(self = [super init]){
		LOG(@"HeftManager::init");
		devices = [NSKeyedUnarchiver unarchiveObjectWithFile:devicesPath()];
		if(!devices)
			devices = [NSMutableArray new];

		dtdev = [DTDevices sharedDevice];
		[dtdev addDelegate:self];
		[dtdev connect];
	}
	return self;
}

- (void)dealloc{
	LOG(@"HeftManager::dealloc");
	[dtdev disconnect];
}

- (BOOL)hasSources{
	return hasBluetooth;
}

- (id<HeftClient>)clientForDevice:(HeftRemoteDevice*)device sharedSecret:(NSData*)sharedSecret delegate:(NSObject<HeftStatusReportDelegate>*)aDelegate{
	return [[MpedDevice alloc] initWithConnection:[[HeftConnection alloc] initWithDevice:device] sharedSecret:sharedSecret delegate:aDelegate];
}

#pragma mark property

- (NSString*)version{
	return @"1.0";
}

#pragma mark HeftDiscovery

- (void)startDiscovery{
	if(hasBluetooth){
		LOG(@"bluetooth discovery started");
		NSError* error = NULL;
		[dtdev btDiscoverPinpadsInBackground:&error];
		//[dtdev btDiscoverDevicesInBackground:10 maxTime:200 codTypes:0 error:&error];
	}
}

#pragma mark DTDeviceDelegate

char* stateLabel[] = {"disconnected", "connecting", "connected"};

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
}

@end