//
//  HeftRemoteDevice.m
//  headstart
//

#import "HeftRemoteDevice.h"

@interface HeftRemoteDevice ()

@property (nonatomic) EAAccessory *internalAccessory;

@end

@implementation HeftRemoteDevice

- (id)initWithAccessory:(EAAccessory*)aAccessory
{
    self = [super init];

	if(self)
    {
		self.internalAccessory = aAccessory;
	}
    
	return self;
}

#pragma mark property

- (NSString*)name
{
    return self.internalAccessory.name;
}

- (NSString*)address
{
    return [self.internalAccessory valueForKey:@"macAddress"];
}

- (EAAccessory*)accessory
{
    return self.internalAccessory;
}

@end
