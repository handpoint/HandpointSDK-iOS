//
//  AnalyticsHelper.h
//  headstart
//
//  Created by Jón Hilmar Gústafsson on 17/10/2016.
//  Copyright © 2016 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEEN_SDKEVENTCOLLECTION @"sdkEventCollection"


@interface AnalyticsHelper : NSObject

struct ActionTypeStrings
{
    __unsafe_unretained NSString* const managerAction;
    __unsafe_unretained NSString* const simulatorAction;
    __unsafe_unretained NSString* const cardReaderAction;
    __unsafe_unretained NSString* const financialAction;
    __unsafe_unretained NSString* const scannerAction;
};
extern const struct ActionTypeStrings actionTypeName;

+ (void)setupAnalyticsWithGlobalProperties:(NSDictionary *)properties
                                 projectID:(NSString *)projectID
                                  writeKey:(NSString *)writeKey;

+ (void)enableGeoLocation;

+ (void)disableGeoLocation;

+ (void)enableLogging;

+ (void)disableLogging;

+ (BOOL)addEvent:(NSDictionary *)event toEventCollection:(NSString *)eventCollection error:(NSError **)anError;

+ (void)addEventForActionType:(NSString *)actionType Action:(NSString *)action withOptionalParameters:(NSDictionary *)optionalParameters;

+ (void)upload;

+ (NSMutableDictionary *)XMLtoDict:(NSDictionary *)xml;

@end
