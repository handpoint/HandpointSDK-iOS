//
//  HeftConnection.h
//  headstart
//

@class HeftRemoteDevice;

typedef enum{
	eAckTimeout
	, eResponseTimeout
	, ePollingTimeout
	, eFinanceTimeout
	, eTimeoutNum
} eConnectionTimeout;

@interface HeftConnection : NSObject

@property(nonatomic) int maxBufferSize;

- (id)initWithDevice:(HeftRemoteDevice*)aDevice;
- (void)shutdown;
- (void)resetData;

- (void)writeData:(uint8_t*)data length:(int)len;
- (void)writeAck:(UInt16)ack;
- (int)readData:(vector<UINT8>&)buffer timeout:(eConnectionTimeout)timeout;
- (UInt16)readAck;

@end

extern const int ciTimeout[];
