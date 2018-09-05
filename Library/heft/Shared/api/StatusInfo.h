
#import "BaseModel.h"
#import "DeviceStatus.h"

@interface StatusInfo : BaseModel
    
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                        statusCode:(int)statusCode;
    
@property (readonly, nonatomic) BOOL cancelAllowed;
@property (readonly, nonatomic) int status;
@property (readonly, nonatomic) NSString *message;
@property (readonly, nonatomic) NSString *statusString;
@property (readonly, nonatomic) DeviceStatus *deviceStatus;

@end
