//
//  HeftRemoteDevice.m
//  headstart
//

#import "HeftRemoteDevice.h"


@implementation HeftRemoteDevice

@synthesize name, address;

- (id)initWithName:(NSString*)aName address:(NSString*)aAddress{
	if(self = [super init]){
		name = aName;
		address = aAddress;
	}
	return self;
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject:name forKey:@"name"];
	[aCoder encodeObject:address forKey:@"address"];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
	if(self = [super init]){
		name = [aDecoder decodeObjectForKey:@"name"];
		address = [aDecoder decodeObjectForKey:@"address"];
	}
	return self;
}

- (BOOL)isEqual:(HeftRemoteDevice*)other {
    if (other == self)
		return YES;
    if (!other || ![other isKindOfClass:[self class]])
		return NO;
 	if (![self.address isEqual:other.address])
		return NO;
	if (![self.name isEqual:other.name])
		return NO;
    return YES;
}

@end
