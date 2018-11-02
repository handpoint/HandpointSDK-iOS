//
// Created by Juan Nuñez on 2018-09-25.
// Copyright (c) 2018 Handpoint. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BluetoothDevice <NSObject>

- (NSString *)name;
- (NSString *)address;

@end