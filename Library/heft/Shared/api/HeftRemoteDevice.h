//
//  HeftRemoteDevice.h
//  headstart
//

#include <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

@interface HeftRemoteDevice : NSObject

- (NSString *)name;
- (NSString *)address;
- (EAAccessory *)accessory;

@end
