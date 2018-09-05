//
//  Logger.m
//  headstart
//
//  Created by Matthías Ásgeirsson on 13/11/15.
//  Copyright © 2015 zdv. All rights reserved.
//

#if 0
#import <Foundation/Foundation.h>

#import "Logger.h"

@implementation HPLogger

+ (id) instance
{
    static HPLogger *theLogger = nil;
    @synchronized(self) {
        if (theLogger == nil)
            theLogger = [[self alloc] init];
    }
    return theLogger;
}

@end

#endif

/*
<#methods#>

@end

@interface HPLogger : NSObject
+ (HPLogger*) instance;
- (void) setFileName:(NSString*)fileName;
- (void) setLevel:(eLevel)level;
- (BOOL) isLogable:(eLevel)level;
- (void) log:(NSString*)format, ...;
#endif

*/