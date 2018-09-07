
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
    NSMutableDictionary *dict = [@{} mutableCopy];
    
    NSDictionary *info = @{
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
    
    for(NSString *key in [info allKeys])
    {
        NSObject *obj = info[key];
        
        if([obj isKindOfClass:NSString.class])
        {
            NSString *string =  (NSString *)obj;
            
            if(![string isEqualToString:@""])
            {
                dict[key] = info[key];
            }
        }
        else
        {
            dict[key] = info[key];
        }
    }
    
    return dict;
}

@end
