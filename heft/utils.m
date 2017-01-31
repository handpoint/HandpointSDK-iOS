//
// Created by Jón Hilmar Gústafsson on 30/01/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import "utils.h"


@implementation utils

// A function that checks if an object is nil and replaces it with an NSNull object which is safe to insert into a NSDictonary
+ (NSObject *) ObjectOrNull:(NSObject*) object {
    return object ?: [NSNull null];
}


@end