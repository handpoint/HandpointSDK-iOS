
#import "DeviceStatus.h"
#import "XMLTags.h"

@implementation DeviceStatus

- (NSString *)serialNumber
{
    return self.dictionary[XMLTags.SerialNumber] ?: @"";
}

- (NSString *)batteryStatus
{
    return self.dictionary[XMLTags.BatteryStatus] ?: @"";
}

- (NSString *)batterymV
{
    return self.dictionary[XMLTags.BatterymV] ?: @"";
}

- (NSString *)batteryCharging
{
    return self.dictionary[XMLTags.BatteryCharging] ?: @"";
}

- (NSString *)externalPower
{
    return self.dictionary[XMLTags.ExternalPower] ?: @"";
}

- (NSString *)applicationName
{
    return self.dictionary[XMLTags.ApplicationName] ?: @"";
}

- (NSString *)applicationVersion
{
    return self.dictionary[XMLTags.ApplicationVersion] ?: @"";
}

- (NSString *)statusMessage
{
    return self.dictionary[XMLTags.StatusMessage] ?: @"";
}

- (NSString *)bluetoothName
{
    return self.dictionary[XMLTags.BluetoothName] ?: @"";
}
    
- (NSDictionary *)toDictionary
{
    return @{
             @"serialNumber": self.serialNumber,
             @"batteryStatus": self.batteryStatus,
             @"batterymV": self.batterymV,
             @"batteryCharging": self.batteryCharging,
             @"externalPower": self.externalPower,
             @"applicationName": self.applicationName,
             @"applicationVersion": self.applicationVersion,
             @"statusMessage": self.statusMessage,
             @"bluetoothName": self.bluetoothName
             };
}

@end
