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

+(void)setupAnalyticsWithSDKVersion:(NSString*)SDKVersion {
    
    KeenClient *keenClient = [KeenClient sharedClientWithProjectID:DEV_KEEN_PROJECTID andWriteKey:DEV_KEEN_WRITEKEY andReadKey: nil];
    
    NSDictionary *device = [NSDictionary dictionaryWithObjectsAndKeys:
                            [[UIDevice currentDevice] model], @"model",
                            [[UIDevice currentDevice] systemName], @"systemName",
                            [[UIDevice currentDevice] systemVersion], @"systemVersion",
                            [[[UIDevice currentDevice] identifierForVendor] UUIDString], @"deviceID",
                            nil];
    
    NSDictionary *app = [NSDictionary dictionaryWithObjectsAndKeys:
                         SDKVersion, @"handpointSDKVersion",
                         [[NSBundle mainBundle] bundleIdentifier], @"bundleId",
                         [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], @"version",
                         nil];
    
    keenClient.globalPropertiesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                             device, @"Device",
                                             app, @"App",
                                             nil];

    
}

+(void)disableGeoLocation {
    [KeenClient disableGeoLocation];
}

+(void)enableGeoLocation {
    [KeenClient enableGeoLocation];
}

+(void)enableLogging {
    [KeenClient enableLogging];
}

+(void)disableLogging {
    [KeenClient disableLogging];
}

+(BOOL)addEvent:(NSDictionary *)event toEventCollection:(NSString *)eventCollection error:(NSError **)anError {
    return [[KeenClient sharedClient] addEvent:event toEventCollection:eventCollection error:anError];
}

+(BOOL)addCardreaderEvent:(NSDictionary *)event error:(NSError **)anError {
    return [[KeenClient sharedClient] addEvent:event toEventCollection:KEEN_CARDREADERACTION error:anError];
}
+(BOOL)addManagerEvent:(NSDictionary *)event error:(NSError **)anError {
    return [[KeenClient sharedClient] addEvent:event toEventCollection:KEEN_MANAGERACTION error:anError];
}

+(void)uploadWithFinishedBlock:(void (^)())block {
    [[KeenClient sharedClient] uploadWithFinishedBlock:block];
}

@end
