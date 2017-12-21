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
	if(self = [super init])
    {
		self.accessory = accessory;
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
	if(self = [super init])
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

- (NSString *)address
{
    return self.accessory.macAddress;
}

- (EAAccessory*)accessory
{
    return self.accessory;
}

@end
