//
//  HeftRemoteDevice.h
//  headstart
//

@interface HeftRemoteDevice : NSObject<NSCoding>

@property(nonatomic, readonly) NSString* name;
@property(nonatomic, readonly) NSString* address;

@end