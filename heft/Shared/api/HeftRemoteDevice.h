//
//  HeftRemoteDevice.h
//  headstart
//

#include <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

@interface HeftRemoteDevice : NSObject

@property(nonatomic, readonly) EAAccessory* accessory;

- (NSString *)name;
- (NSString *)address;

@end
