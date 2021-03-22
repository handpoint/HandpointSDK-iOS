//
// Created by Juan Nuñez on 12/03/2021.
// Copyright (c) 2021 Handpoint. All rights reserved.
//

#import "MerchantAuth.h"
#import "Credential.h"
#import "SaleOptions.h"
#import "MerchantAuthOptions.h"
#import "Options.h"

@implementation MerchantAuth

- (instancetype)initWithCredential:(Credential *)credential
{
    self = [super init];
    if (self)
    {
        [self addObject:credential];
    }

    return self;
}

- (instancetype)initWithCredentials:(NSArray *)credentials
{
    self = [super init];
    if (self)
    {
        [self addObjectsFromArray:credentials];
    }

    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {}

    return self;
}

- (NSString *)toXML
{
    NSArray *credentials = [self copy];
    NSMutableString *xml = [NSMutableString new];

    for(Credential *credential in credentials) {
        [xml appendString:credential.toXML];
    }

    return xml;
}

@end