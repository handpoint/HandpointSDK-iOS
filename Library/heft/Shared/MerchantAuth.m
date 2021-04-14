//
// Created by Juan Nuñez on 12/03/2021.
// Copyright (c) 2021 Handpoint. All rights reserved.
//

#import "MerchantAuth.h"
#import "Credential.h"
#import "SaleOptions.h"
#import "MerchantAuthOptions.h"
#import "Options.h"


@interface MerchantAuth()

@property (atomic) NSMutableArray *credentials;

@end

@implementation MerchantAuth

- (instancetype)initWithCredential:(Credential *)credential
{
    self = [super init];
    if (self)
    {
        self.credentials = [NSMutableArray new];
        [self.credentials addObject:credential];
    }

    return self;
}

- (instancetype)initWithCredentials:(NSArray *)credentials
{
    self = [super init];
    if (self)
    {
        self.credentials = [NSMutableArray new];
        [self.credentials addObjectsFromArray:credentials];
    }

    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.credentials = [NSMutableArray new];
    }

    return self;
}

- (void)add:(Credential *)credential {
    [self.credentials addObject:credential];
}

- (NSString *)toXML
{
    NSArray *credentials = [self.credentials copy];
    NSMutableString *xml = [NSMutableString new];

    for(Credential *credential in credentials) {
        [xml appendFormat:@"<credential>%@</credential>", credential.toXML];
    }

    return xml;
}

@end
