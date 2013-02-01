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

@interface HeftConnection : NSObject{
	HeftRemoteDevice* device;
	NSInputStream* inputStream;
	NSOutputStream* outputStream;

	uint8_t* tmpBuf;
	//int currentPosition;
	NSConditionLock* bufferLock;
}

@property(nonatomic) int maxBufferSize;
@property(nonatomic) int currentPosition;

- (id)initWithDevice:(HeftRemoteDevice*)aDevice;
- (void)shutdown;

- (void)writeData:(uint8_t*)data length:(int)len;
- (void)writeAck:(UInt16)ack;
- (int)readData:(vector<UINT8>&)buffer timeout:(eConnectionTimeout)timeout;
- (UInt16)readAck;

@end

extern const int ciTimeout[];
