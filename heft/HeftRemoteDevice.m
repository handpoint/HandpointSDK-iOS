//
//  HeftRemoteDevice.m
//  headstart
//

#import "HeftRemoteDevice.h"


@implementation HeftRemoteDevice

@synthesize name, address, accessory;

- (id)initWithName:(NSString*)aName address:(NSString*)aAddress
{
	if(self = [super init])
    {
		name = aName;
		address = aAddress;
	}
	return self;
}

- (id)initWithAccessory:(EAAccessory*)aAccessory
{
	if(self = [super init])
    {
		accessory = aAccessory;
	}
	return self;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:name forKey:@"name"];
	[aCoder encodeObject:address forKey:@"address"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if(self = [super init])
    {
		name = [aDecoder decodeObjectForKey:@"name"];
		address = [aDecoder decodeObjectForKey:@"address"];
	}
	return self;
}

#pragma mark property

- (NSString*)name
{
	return name ? name : accessory.name;
}

- (EAAccessory*)accessory
{
    return accessory ? accessory : nil;
}

@end
