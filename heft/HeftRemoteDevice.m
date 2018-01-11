//
//  HeftRemoteDevice.m
//  headstart
//

#import "HeftRemoteDevice.h"

@interface HeftRemoteDevice ()

@property (nonatomic) EAAccessory *internalAccessory;

@end

@implementation HeftRemoteDevice

- (id)initWithAccessory:(EAAccessory*)accessory
{
    self = [super init];

	if(self)
    {
		self.internalAccessory = accessory;
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
    return [NSString stringWithFormat:@"68:AA:%@", @([self.internalAccessory connectionID])];
}

- (EAAccessory*)accessory
{
    return self.internalAccessory;
}

@end
