//
// Created by Juan Nuñez on 14/12/2017.
// Copyright (c) 2017 zdv. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResponseInfo.h"

@protocol LogInfo <ResponseInfo>

//The history of actions and transactions from MPED that were logged.
@property (nonatomic) NSString *log;

@end

@interface LogInfo : ResponseInfo<LogInfo>
@end