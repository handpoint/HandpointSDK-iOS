//
// Created by Juan Nuñez on 12/03/2021.
// Copyright (c) 2021 Handpoint. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "toXML.h"

typedef enum Acquirer {
    UNDEFINED,
    AMEX,
    BORGUN,
    EVO,
    OMNIPAY,
    POSTBRIDGE,
    INTERAC,
    TSYS,
    VANTIV,
    SANDBOX
    #define AcquirerValueLast SANDBOX
} Acquirer;

static const int FIELD_MAX_LENGTH = 23;

@interface Credential : NSObject<ToXML>

@property (readwrite) enum Acquirer acquirer;
@property (readwrite) NSString* mid;
@property (readwrite) NSString* tid;

- (NSString *)acquirerString;

+ (enum Acquirer)getAcquirerFromString:(NSString *)string;

+ (NSString *)getAcquirerName:(enum Acquirer)acquirer;

- (NSString *)toXML;
@end
