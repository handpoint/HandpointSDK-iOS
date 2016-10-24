//
//  AnalyticsHelper.h
//  headstart
//
//  Created by Jón Hilmar Gústafsson on 17/10/2016.
//  Copyright © 2016 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define DEV_KEEN_PROJECTID @"56afbb7e46f9a76bfe19bfdc"
#define DEV_KEEN_WRITEKEY @"6460787402f46a7cafef91ec1d666cc37e14cc0f0bc26a0e3066bfc2e3c772d83a91a99f0ddec23a59fead9051e53bb2e2693201df24bd29eac9c78a61a2208993e9cef175bca6dc029ef28a93a0e5e135201bda7d6a98b2aa1f5aa76c5a4002"
#define KEEN_MANAGERCREATED @"managerCreated"
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
