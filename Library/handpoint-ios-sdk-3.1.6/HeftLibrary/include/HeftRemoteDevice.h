//
//  HeftRemoteDevice.h
//  headstart
//

#include <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import <IOBluetooth/IOBluetooth.h>

@interface HeftRemoteDevice : NSObject

- (NSString *)name;
- (NSString *)address;
- (EAAccessory *)accessory;
//TODO extension
- (IOBluetoothDevice *)device;


@end
