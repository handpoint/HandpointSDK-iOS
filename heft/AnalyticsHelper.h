//
//  AnalyticsHelper.h
//  headstart
//
//  Created by Jón Hilmar Gústafsson on 17/10/2016.
//  Copyright © 2016 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// DEV Project keys
#define DEV_KEEN_PROJECTID @"56afbb7e46f9a76bfe19bfdc"
#define DEV_KEEN_WRITEKEY @"6460787402f46a7cafef91ec1d666cc37e14cc0f0bc26a0e3066bfc2e3c772d83a91a99f0ddec23a59fead9051e53bb2e2693201df24bd29eac9c78a61a2208993e9cef175bca6dc029ef28a93a0e5e135201bda7d6a98b2aa1f5aa76c5a4002"
// End DEV Project keys

// Production Project Keys
#define KEEN_PROJECTID @"56afc865672e6c6e5a9dc431"
#define KEEN_WRITEKEY @"68acf442839a15c214424f06d8b3298c2b0a9901e0cf3068977ad13d24b8e8e3590c853f2935772d632aefaef5c60b4f35383bd01fd8d65f9bf37a57f3ba2e6de21317e9f91ba1172ca79040e237e354b3f71c2147e3cca2250fb263a49d5a09"
// End Production Project Keys

#define KEEN_MANAGERACTION @"managerAction"
#define KEEN_CARDREADERACTION @"cardreaderAction"


@interface AnalyticsHelper : NSObject

+(void)setupAnalyticsWithSDKVersion:(NSString*)SDKVersion;
+(void)enableGeoLocation;
+(void)disableGeoLocation;
+(void)enableLogging;
+(void)disableLogging;
+(BOOL)addEvent:(NSDictionary *)event toEventCollection:(NSString *)eventCollection error:(NSError **)anError;
+(BOOL)addCardreaderEvent:(NSDictionary *)event error:(NSError **)anError;
+(BOOL)addManagerEvent:(NSDictionary *)event error:(NSError **)anError;
+(void)uploadWithFinishedBlock:(void (^)())block;

@end
