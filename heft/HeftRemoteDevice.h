//
//  HeftRemoteDevice.h
//  headstart
//

@interface HeftRemoteDevice : NSObject<NSCoding>

@property(nonatomic, readonly) NSString* name;
@property(nonatomic, readonly) NSString* address;
@property(nonatomic, readonly) EAAccessory* accessory;


- (NSString*)name;
- (EAAccessory*)accessory;

@end
