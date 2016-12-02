//
//  AnalyticsHelper.h
//  headstart
//
//  Created by Jón Hilmar Gústafsson on 17/10/2016.
//  Copyright © 2016 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEEN_MANAGERCREATED @"managerCreated"
#define KEEN_MANAGERACTION @"managerAction"
#define KEEN_CARDREADERACTION @"cardreaderAction"


@interface AnalyticsHelper : NSObject

+ (void)setupAnalyticsWithGlobalProperties:(NSDictionary *)properties
                                 projectID:(NSString *)projectID
                                  writeKey:(NSString *)writeKey;

+ (void)enableGeoLocation;

+ (void)disableGeoLocation;

+ (void)enableLogging;

+ (void)disableLogging;

+ (BOOL)addEvent:(NSDictionary *)event toEventCollection:(NSString *)eventCollection error:(NSError **)anError;

+ (BOOL)addCardReaderEvent:(NSDictionary *)event;

+ (BOOL)addManagerEvent:(NSDictionary *)event;

+ (void)upload;

@end
