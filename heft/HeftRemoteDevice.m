//
//  HeftRemoteDevice.m
//  headstart
//

#import "HeftRemoteDevice.h"

@interface EAAccessory ()

@property (nonatomic, readonly) NSString *macAddress;

@end


@interface HeftRemoteDevice ()

@property(nonatomic) NSString* name;
@property(nonatomic) NSString* address;
@property(nonatomic) EAAccessory* accessory;

@end

@implementation HeftRemoteDevice

- (id)initWithAccessory:(EAAccessory*)accessory
{
    self = [super init];

	if(self)
    {
		self.accessory = accessory;
        self.address = [accessory valueForKey:@"macAddress"]; //accessory.macAddress;
	}
	return self;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.name forKey:@"name"];
	[aCoder encodeObject:self.address forKey:@"address"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];

	if(self)
    {
		self.name = [aDecoder decodeObjectForKey:@"name"];
		self.address = [aDecoder decodeObjectForKey:@"address"];
	}
	return self;
}

#pragma mark property

- (NSString*)name
{
	return self.name ?: self.accessory.name;
}

- (EAAccessory*)accessory
{
    return self.accessory;
}

@end
