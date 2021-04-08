//
// Created by Juan Nuñez on 12/03/2021.
// Copyright (c) 2021 Handpoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Options.h"

@class MerchantAuth;

@interface MerchantAuthOptions : Options

@property (atomic, readwrite) MerchantAuth* merchantAuth;

@end