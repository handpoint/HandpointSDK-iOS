//
// Created by Juan Nuñez on 07/06/2018.
// Copyright (c) 2018 zdv. All rights reserved.
//
#include <vector>
#include <cstdint>
#import <Foundation/Foundation.h>

@class HeftRemoteDevice;
@class MpedDevice;

typedef enum{
    eAckTimeout
    , eResponseTimeout
    , ePollingTimeout
    , eFinanceTimeout
    , eTimeoutNum
} eConnectionTimeout;

@protocol Connection <NSObject>

@property(nonatomic) int maxFrameSize;
@property(nonatomic) int ourBufferSize;

- (void)shutdown;
- (void)resetData;

- (void)writeData:(uint8_t*)data length:(int)len;
- (void)writeAck:(UInt16)ack;
- (int)readData:(std::vector<std::uint8_t>&)buffer timeout:(eConnectionTimeout)timeout;
- (UInt16)readAck;

@end