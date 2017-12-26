//
// Created by Juan Nuñez on 15/12/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnalyticsConfig.h"


@interface AnalyticsConfig ()

@property (nonatomic) NSString *KeenProjectID;
@property (nonatomic) NSString *KeenWriteKey;

@end

@implementation AnalyticsConfig

- (instancetype)init
{
    self = [super init];

    if (self)
    {

#ifdef HEFT_SIMULATOR
        self.KeenProjectID = @"585180208db53dfda8a7bf78"; //So we can track the simulator development
        self.KeenWriteKey = @"708E857964F9B97F1D6F83578A533F9B6B4A5C59FD611E228466156360DAA13DB30ACF66EAC9F8D542C3C4C99140C3B176F909080134314AE7FBF56A61EBD9B756B6A24FD219A8809A6FD3410E9026A6EF9D56AD961DA7D4DC912AC6E6D9FC15";
#else
    #ifdef DEBUG
        self.KeenProjectID = @"56afbb7e46f9a76bfe19bfdc";
        self.KeenWriteKey = @"6460787402f46a7cafef91ec1d666cc37e14cc0f0bc26a0e3066bfc2e3c772d83a91a99f0ddec23a59fead9051e53bb2e2693201df24bd29eac9c78a61a2208993e9cef175bca6dc029ef28a93a0e5e135201bda7d6a98b2aa1f5aa76c5a4002";
    #else
        self.KeenProjectID = @"56afc865672e6c6e5a9dc431";
        self.KeenWriteKey = @"68acf442839a15c214424f06d8b3298c2b0a9901e0cf3068977ad13d24b8e8e3590c853f2935772d632aefaef5c60b4f35383bd01fd8d65f9bf37a57f3ba2e6de21317e9f91ba1172ca79040e237e354b3f71c2147e3cca2250fb263a49d5a09";
    #endif
#endif
    }

    return self;
}

@end