
#import <Foundation/Foundation.h>
#import "BaseModel.h"

@interface BaseModel ()

@property (readwrite, nonatomic) NSDictionary *dataDictionary;

@end

@implementation BaseModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self)
    {
        self.dataDictionary = dictionary;
    }

    return self;
}

- (NSDictionary *)dictionary
{
    return self.dataDictionary;
}

@end
