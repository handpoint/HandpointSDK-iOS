//
// Created by Juan Nuñez on 12/03/2021.
// Copyright (c) 2021 Handpoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "toXML.h"

@class Credential;

@interface MerchantAuth: NSObject
- (instancetype)init;
- (instancetype)initWithCredential:(Credential *)credential;
- (instancetype)initWithCredentials:(NSArray *)credentials;
- (void)add:(Credential *)credential;
- (NSString *)toXML;
@end
