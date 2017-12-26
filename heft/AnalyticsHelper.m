//
//  AnalyticsHelper.m
//  headstart
//
//  Created by Jón Hilmar Gústafsson on 17/10/2016.
//  Copyright © 2016 zdv. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AnalyticsHelper.h"
#import "KeenClient.h"

@implementation AnalyticsHelper

const struct ActionTypeStrings actionTypeName = {
    .managerAction = @"managerAction",
    .simulatorAction = @"simulatorAction",
    .cardReaderAction = @"cardReaderAction",
    .financialAction = @"financialAction",
    .scannerAction = @"scannerAction"
};

+ (void)setupAnalyticsWithVersion:(NSString *)version
                        projectID:(NSString *)projectID
                         writeKey:(NSString *)writeKey
{
    KeenClient *keenClient = [KeenClient sharedClientWithProjectID:projectID
                                                       andWriteKey:writeKey
                                                        andReadKey:nil];

    keenClient.globalPropertiesDictionary = [self analyticsGlobalPropertiesWithVersion:version];
}

+ (NSDictionary *)analyticsGlobalPropertiesWithVersion:(NSString *)version
{
    UIDevice *currentDevice = [UIDevice currentDevice];

    NSDictionary *device = @{
            @"model": [currentDevice model],
            @"systemName": [currentDevice systemName],
            @"systemVersion": [currentDevice systemVersion],
            @"deviceID": [[currentDevice identifierForVendor] UUIDString]
    };

    NSBundle *mainBundle = [NSBundle mainBundle];

    NSDictionary *app = @{
            @"handpointSDKVersion": version,
            @"bundleId": [mainBundle bundleIdentifier],
            @"version": [mainBundle infoDictionary][@"CFBundleShortVersionString"]
    };

    NSDictionary *properties = @{
            @"Device": device,
            @"App": app
    };

    return properties;
}

+ (void)disableGeoLocation
{
    [KeenClient disableGeoLocation];
}

+ (void)enableGeoLocation
{
    [KeenClient enableGeoLocation];
}

+ (void)enableLogging
{
    [KeenClient enableLogging];
}

+ (void)disableLogging
{
    [KeenClient disableLogging];
}

+ (BOOL) addEvent:(NSDictionary *)event
toEventCollection:(NSString *)eventCollection
            error:(NSError **)anError
{
    return [[KeenClient sharedClient] addEvent:event
                             toEventCollection:eventCollection
                                         error:anError];
}

+ (void)addEventForActionType:(NSString *)actionType
                       Action:(NSString *)action
       withOptionalParameters:(NSDictionary *)optionalParameters {
    NSDictionary *event = @{
            @"actionType": actionType,
            @"action": action,
            @"optionalParameters": (optionalParameters) ? optionalParameters : @""

    };

    [[KeenClient sharedClient] addEvent:event
                      toEventCollection:KEEN_SDKEVENTCOLLECTION
                                  error:nil];
}

+ (void)upload
{
    [[KeenClient sharedClient] uploadWithFinishedBlock:nil];
}

+ (NSMutableDictionary *)XMLtoDict:(NSDictionary *)xml
{
    NSSet * keys = [NSSet setWithObjects:
            @"ApplicationVersion",
            @"CardEntryType",
            @"CardSchemeName",
            @"CardTypeId",
            @"Currency",
            @"CVM",
            @"FinancialStatus",
            @"BudgetNumber",
            @"GratuityAmount",
            @"GratuityPercentage",
            @"RequestedAmount",
            @"TotalAmount",
            @"DueAmount",
            @"BalanceAmount",
            @"BalanceCurrency",
            @"BalanceSign",
            @"TransactionType",
            @"BatteryCharging",
            @"BatterymV",
            @"BatteryStatus",
            @"ExternalPower",
            @"SerialNumber",
            @"StatusMessage",
            @"ErrorMessage",
                    nil];

    NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:20];

    for (id key in keys) {
        id object = xml[key];
        if (object) {
            result[key] = [utils ObjectOrNull:object];
        }
    }
    return result;
}

@end
