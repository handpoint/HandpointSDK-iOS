//
//  LogInfo.h
//  headstart
//
//  Created by Juan Nuñez on 18/12/2017.
//  Copyright © 2017 zdv. All rights reserved.
//

#ifndef LogInfo_h
#define LogInfo_h


#import "ResponseInfo.h"

@protocol LogInfo <ResponseInfo>

//The history of actions and transactions from MPED that were logged.
@property (nonatomic) NSString *log;

@end

#endif /* LogInfo_h */
