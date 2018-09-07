#pragma once

#import "BaseModel.h"

@interface DeviceStatus : BaseModel

@property (readonly, nonatomic) NSString *serialNumber;
@property (readonly, nonatomic) NSString *batteryStatus;
@property (readonly, nonatomic) NSString *batterymV;
@property (readonly, nonatomic) NSString *batteryCharging;
@property (readonly, nonatomic) NSString *externalPower;
@property (readonly, nonatomic) NSString *applicationName;
@property (readonly, nonatomic) NSString *applicationVersion;
@property (readonly, nonatomic) NSString *statusMessage;
@property (readonly, nonatomic) NSString *bluetoothName;
    
- (NSDictionary *)toDictionary;

@end
