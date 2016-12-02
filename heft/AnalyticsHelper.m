//
//  AnalyticsHelper.m
//  headstart
//
//  Created by Jón Hilmar Gústafsson on 17/10/2016.
//  Copyright © 2016 zdv. All rights reserved.
//

#import "AnalyticsHelper.h"
#import "KeenClient.h"

@implementation AnalyticsHelper

+ (void)setupAnalyticsWithGlobalProperties:(NSDictionary *)properties
                                 projectID:(NSString *)projectID
                                  writeKey:(NSString *)writeKey
{
    KeenClient *keenClient = [KeenClient sharedClientWithProjectID:projectID
                                                       andWriteKey:writeKey
                                                        andReadKey:nil];

    keenClient.globalPropertiesDictionary = properties;
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

+ (BOOL)addCardReaderEvent:(NSDictionary *)event
{
    return [[KeenClient sharedClient] addEvent:event
                             toEventCollection:KEEN_CARDREADERACTION
                                         error:nil];
}

+ (BOOL)addManagerEvent:(NSDictionary *)event
{
    return [[KeenClient sharedClient] addEvent:event
                             toEventCollection:KEEN_MANAGERACTION
                                         error:nil];
}

+ (void)upload
{
    [[KeenClient sharedClient] uploadWithFinishedBlock:nil];
}

@end
