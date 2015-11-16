//
//  HeftConnection.h
//  headstart
//

#include <vector>
#include <cstdint>

#import <Foundation/Foundation.h>


@class HeftRemoteDevice;

typedef enum{
	eAckTimeout
	, eResponseTimeout
	, ePollingTimeout
	, eFinanceTimeout
	, eTimeoutNum
} eConnectionTimeout;

@interface HeftConnection : NSObject

@property(nonatomic) int maxFrameSize;
@property(nonatomic) int ourBufferSize;

- (id)initWithDevice:(HeftRemoteDevice*)aDevice;
- (void)shutdown;
- (void)resetData;

- (void)writeData:(uint8_t*)data length:(int)len;
- (void)writeAck:(UInt16)ack;
- (int)readData:(std::vector<std::uint8_t>&)buffer timeout:(eConnectionTimeout)timeout;
- (UInt16)readAck;

@end

extern const int ciTimeout[];
