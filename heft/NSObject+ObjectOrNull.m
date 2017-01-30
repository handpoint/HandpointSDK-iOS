//
// Created by Jón Hilmar Gústafsson on 30/01/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import "NSObject+ObjectOrNull.h"


@implementation NSObject (ObjectOrNull)

static NSObject* ObjectOrNull(NSObject* object)
{
    return object ?: [NSNull null];
}

@end