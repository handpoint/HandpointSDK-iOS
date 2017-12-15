//
// Created by Juan Nuñez on 13/12/2017.
// Copyright (c) 2017 Handpoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ResponseInfo <NSObject>

//Code of the terminal status message.
@property (nonatomic) int statusCode;
//Financial transaction status message.
@property (nonatomic) NSString *status;
//xml details about transaction from MPED inside.
@property (nonatomic) NSDictionary *xml;

@end

@interface ResponseInfo : NSObject<ResponseInfo>
@end
