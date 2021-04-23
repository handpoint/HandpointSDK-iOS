//
// Created by Juan Nuñez on 12/03/2021.
// Copyright (c) 2021 Handpoint. All rights reserved.
//

#import "Credential.h"

@implementation Credential

- (NSString *)acquirerString
{
    switch(self.acquirer) {
        case AMEX: return @"AMEX";
        case BORGUN: return @"BORGUN";
        case EVO: return @"EVO";
        case OMNIPAY: return @"OMNIPAY";
        case POSTBRIDGE: return @"PostBridge";
        case INTERAC: return @"TNS";
        case TSYS: return @"TSYS";
        case VANTIV: return @"VANTIV";
        case SANDBOX: return @"ViscusDummy";
    }

    return @"";
}

- (NSString *)mid
{
    return [self cropString:_mid toLength:FIELD_MAX_LENGTH];
}

- (NSString *)tid
{
    return [self cropString:_tid toLength:FIELD_MAX_LENGTH];
}

- (NSString *)cropString:(NSString *)string
                toLength:(NSUInteger)desiredLength
{
    NSString* empty = @"";
    if(string == nil || [empty isEqualToString:string])
        return empty;

    NSUInteger start = 0;
    NSUInteger end = (desiredLength > string.length) ? string.length : desiredLength;
    return [string substringWithRange:NSMakeRange(start, end)];
}

static inline BOOL isEmpty(id thing) {
    return thing == nil
            || [thing isKindOfClass:[NSNull class]]
            || ([thing respondsToSelector:@selector(length)]
            && [(NSData *)thing length] == 0)
            || ([thing respondsToSelector:@selector(count)]
            && [(NSArray *)thing count] == 0);
}

+ (enum Acquirer)getAcquirerFromString:(NSString *)string {
    for (Acquirer value = 0; value <= AcquirerValueLast; value++) {
        if ([[self getAcquirerName:value] isEqualToString:string]) {
            return value;
        }
    }
    return UNDEFINED;
}
+ (NSString *)getAcquirerName:(enum Acquirer)acquirer {
    switch(acquirer) {
        case AMEX:
            return @"AMEX";
        case BORGUN:
            return @"BORGUN";
        case EVO:
            return @"EVO";
        case OMNIPAY:
            return @"OMNIPAY";
        case POSTBRIDGE:
            return @"POSTBRIDGE";
        case INTERAC:
            return @"INTERAC";
        case TSYS:
            return @"TSYS";
        case VANTIV:
            return @"VANTIV";
        case SANDBOX:
            return @"SANDBOX";
        default:
            return @"";
        }
}

- (NSString *)toXML
{
    if(isEmpty(self.mid) && isEmpty(self.tid))
    {
        return @"";
    }
    NSMutableString *credential = [NSMutableString new];
    if(self.acquirerString.length)
    {
        [credential appendFormat:@"<acquirer>%@</acquirer>", self.acquirerString];
    }
    if(self.mid.length)
    {
        [credential appendFormat:@"<mid>%@</mid>", self.mid];
    }
    if(self.tid.length)
    {
        [credential appendFormat:@"<tid>%@</tid>", self.tid];
    }
    return credential;
}
@end
