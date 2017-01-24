//
//  HeftConnection.h
//  headstart
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

@interface HeftConnection : NSObject

@property(nonatomic) int maxFrameSize;
@property(nonatomic) int ourBufferSize;

- (id)initWithDevice:(HeftRemoteDevice*)aDevice runLoop:(NSRunLoop*) runLoop;
- (void)addClient:(MpedDevice*)pedDevice;
- (void)shutdown;
- (void)resetData;

- (void)writeData:(uint8_t*)data length:(int)len;
- (void)writeAck:(UInt16)ack;
- (int)readData:(std::vector<std::uint8_t>&)buffer timeout:(eConnectionTimeout)timeout;
- (UInt16)readAck;
- (void)write_from_queue_to_stream;

@end

extern const int ciTimeout[];
