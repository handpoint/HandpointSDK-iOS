//
// Created by Jón Hilmar Gústafsson on 30/01/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import "utils.h"


@implementation utils

+ (NSObject *) ObjectOrNull:(NSObject*) object {
    return object ?: [NSNull null];
}


@end