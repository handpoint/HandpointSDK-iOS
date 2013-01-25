//
//  HeftConnection.m
//  headstart
//

#import "StdAfx.h"
#import <DTDevices.h>

#import "HeftConnection.h"
#import "HeftRemoteDevice.h"

const int ciDefaultMaxFrameSize = 2048;

enum eBufferConditions{
	eNoDataCondition
	, eHasDataCondition
};

@interface HeftConnection()<NSStreamDelegate>
@end

@implementation HeftConnection

@synthesize maxBufferSize, currentPosition;

- (id)initWithDevice:(HeftRemoteDevice*)aDevice{
	NSError* error = nil;
	DTDevices *dtdev = [DTDevices sharedDevice];
	if([dtdev btConnect:aDevice.address pin:@"0000" error:&error]){
		Assert(!error);
		if(self = [super init]){
			LOG(@"Connected to %@", aDevice.name);
			device = aDevice;
			outputStream = dtdev.btOutputStream;
			inputStream = dtdev.btInputStream;
			inputStream.delegate = self;

			maxBufferSize = ciDefaultMaxFrameSize;
			tmpBuf = (uint8_t*)malloc(maxBufferSize);
			Assert(tmpBuf);
			bufferLock = [[NSConditionLock alloc] initWithCondition:eNoDataCondition];
		}
		return self;
	}
	else
		LOG(@"Connection to %@ error:%@", aDevice.name, error);

	self = nil;
	return self;
}

- (void)shutdown{
	inputStream.delegate = nil;
}

- (void)dealloc{
	LOG(@"Disconnection from %@", device.name);
	free(tmpBuf);
	NSError* error = nil;
	if(device && ![[DTDevices sharedDevice] btDisconnect:device.address error:&error])
		LOG(@"btDisconnect error: %@", error);
}

- (void)writeData:(uint8_t*)data length:(int)len{
	while(len){
		while(![outputStream hasSpaceAvailable]);
		/*uint8_t packet[] = {0x10, 0x02, 0x49, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x37, 0x20, 0x12, 0x08, 0x10, 0x10, 0x18, 0x08, 0x34, 0x10, 0x03, 0x2F, 0xBD};
		BOOL b = [outputStream hasSpaceAvailable];
		int nwritten = [outputStream write:packet maxLength:sizeof(packet)];*/
		int nwritten = [outputStream write:data maxLength:fmin(len, maxBufferSize)];
		LOG(@"HeftConnection::writeData %d: %c%c%c%c", nwritten, data[2], data[3], data[4], data[5]);
		Assert(nwritten > 0);

		/*uint8_t buf[100] = {0};
		b = [inputStream hasBytesAvailable];
		int nread = [inputStream read:buf maxLength:sizeof(buf)];
		NSError* serr = inputStream.streamError;
		NSLog(@"inputStream error: %@", serr);
		NSLog(@"outputStream error: %@", outputStream.streamError);*/

		len -= nwritten;
		data += nwritten;
	}
}

- (void)writeAck:(UInt16)ack{
	//LOG(@"HeftConnection::writeAck %04X", ack_n);
	while(![outputStream hasSpaceAvailable]);
	int nwritten = [outputStream write:(uint8_t*)&ack maxLength:sizeof(ack)];
	Assert(nwritten == sizeof(ack));
}

- (void)stream:(NSInputStream*)aStream handleEvent:(NSStreamEvent)eventCode{
	if(eventCode == NSStreamEventHasBytesAvailable){
		uint8_t* buf = 0;
		NSUInteger nread = 0;
		[bufferLock lock];
		if([aStream getBuffer:&buf length:&nread]){
			LOG(@"stream:handleEvent: has bytes: %d", nread);
			Assert(nread);
			double minread = fmin(nread, maxBufferSize - currentPosition);
			nread = [inputStream read:&tmpBuf[currentPosition] maxLength:minread];
			Assert(nread == minread);
			currentPosition += nread;
		}
		[bufferLock unlockWithCondition:currentPosition ? eHasDataCondition : eNoDataCondition];
		//[NSThread sleepForTimeInterval:.1];
	}
}

- (int)readData:(void*)buffer timeout:(eConnectionTimeout)timeout{
	vector<UINT8>& vBuf = *reinterpret_cast<vector<UINT8>*>(buffer);
	int initSize = vBuf.size();

	if(![bufferLock lockWhenCondition:eHasDataCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:ciTimeout[timeout]]]){
		if(timeout == eFinanceTimeout){
			LOG(@"Finance timeout");
			throw timeout4_exception();
		}
		else{
			LOG(@"Response timeout");
			throw timeout2_exception();
		}
		
	}
	
	vBuf.resize(initSize + currentPosition);
	memcpy(&vBuf[initSize], tmpBuf, currentPosition);

	int nread = currentPosition;
	currentPosition = 0;
	
	[bufferLock unlockWithCondition:eNoDataCondition];

	if(nread > 6)
		LOG(@"HeftConnection::readData %d: %c%c%c%c", nread, tmpBuf[2], tmpBuf[3], tmpBuf[4], tmpBuf[5]);

	return nread;
}

- (UInt16)readAck{
	UInt16 ack = 0;
	
	if(![bufferLock lockWhenCondition:eHasDataCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:ciTimeout[eAckTimeout]]]){
		LOG(@"Ack timeout");
		throw timeout1_exception();
	}

	Assert(currentPosition >= sizeof(ack));
	memcpy(&ack, tmpBuf, sizeof(ack));
	currentPosition -= sizeof(ack);
	memcpy(tmpBuf, tmpBuf + sizeof(ack), currentPosition);
	
	[bufferLock unlockWithCondition:currentPosition ? eHasDataCondition : eNoDataCondition];

	//LOG(@"HeftConnection::readAck %04X", ack);
	return ack;
}

#pragma mark property

- (void)setMaxBufferSize:(int)aMaxBufferSize{
	if(maxBufferSize != aMaxBufferSize){
		maxBufferSize = aMaxBufferSize;
		free(tmpBuf);
		tmpBuf = (uint8_t*)malloc(maxBufferSize);
		Assert(tmpBuf);
	}
}

@end
