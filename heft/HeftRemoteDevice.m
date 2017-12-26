//
//  HeftRemoteDevice.m
//  headstart
//

#import "HeftRemoteDevice.h"

/*@interface EAAccessory ()

@property (nonatomic, readonly) NSString *macAddress;

@end*/


@interface HeftRemoteDevice ()

//@property(nonatomic) NSString* name;
//@property(nonatomic) NSString* address;
@property(nonatomic) EAAccessory* accessory;

@end

@implementation HeftRemoteDevice

@synthesize accessory;

- (id)initWithAccessory:(EAAccessory*)aAccessory
{
    self = [super init];

	if(self)
    {
		accessory = aAccessory;
	}
    
	return self;
}

#pragma mark NSCoding
/*
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
 
*/
#pragma mark property

- (NSString*)name
{
    return accessory.name;
}

- (NSString*)address
{
    return [accessory valueForKey:@"macAddress"];
}

- (EAAccessory*)accessory
{
    return accessory;
}

@end
