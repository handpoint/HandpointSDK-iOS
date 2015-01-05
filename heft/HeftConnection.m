//
//  HeftConnection.m
//  headstart
//

#import "StdAfx.h"

#import "HeftConnection.h"
#import "HeftRemoteDevice.h"

extern NSString* eaProtocol;

const int ciDefaultMaxFrameSize = 2046; // Hotfix: 2048 bytes causes buffer overflow in EFT client.
const int ciTimeout[] = {20, 15, 1, 5*60};

enum eBufferConditions{
    eNoDataCondition
    , eHasDataCondition
};

@interface HeftConnection()<NSStreamDelegate>
@end

@implementation HeftConnection{
    HeftRemoteDevice* device;
    EASession* session;
    NSInputStream* inputStream;
    NSOutputStream* outputStream;

    uint8_t* volatile tmpBuf;
    int currentPosition;
    NSConditionLock* bufferLock;
}

@synthesize maxFrameSize;
@synthesize ourBufferSize;

- (id)initWithDevice:(HeftRemoteDevice*)aDevice{
    EASession* eaSession = nil;
    NSInputStream* is = nil;
    NSOutputStream* os = nil;
    BOOL result = NO;

    if(aDevice.accessory){
        LOG(@"%@", aDevice.accessory.protocolStrings);
        eaSession = [[EASession alloc] initWithAccessory:aDevice.accessory forProtocol:eaProtocol];
        result = eaSession != nil;
        if(result){
            NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
            is = eaSession.inputStream;
            [is scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
            [is open];
            os = eaSession.outputStream;
            [os scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
            [os open];
        }
        else
            LOG(@"Connection to %@ failed", aDevice.name);
    }
    if(result){
        if(self = [super init]){
            LOG(@"Connected to %@", aDevice.name);
            device = aDevice;
            session = eaSession;
            outputStream = os;
            inputStream = is;
            inputStream.delegate = self;
            maxFrameSize = ciDefaultMaxFrameSize;
            ourBufferSize = ciDefaultMaxFrameSize;
            tmpBuf = (uint8_t*)malloc(ourBufferSize);
            Assert(tmpBuf);
            bufferLock = [[NSConditionLock alloc] initWithCondition:eNoDataCondition];
        }
        return self;
    }

    self = nil;
    return self;
}

- (void)dealloc{
    LOG(@"Disconnection from %@", device.name);
    free(tmpBuf);
    if(device){
        if(device.accessory){
            NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
            [outputStream close];
            [outputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
            [inputStream close];
            [inputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        }
    }
}

- (void)shutdown{
    inputStream.delegate = nil;
}

- (void)resetData{

    if(currentPosition){
        LOG(@"resetData waiting for read lock");
        [bufferLock lockWhenCondition:eHasDataCondition];
        LOG(@"resetData got read lock");
        currentPosition = 0;
        [bufferLock unlockWithCondition:eNoDataCondition];
        LOG(@"resetData released read lock");
    }

}

- (void)writeData:(uint8_t*)data length:(int)len{

    while(len){
        while(![outputStream hasSpaceAvailable]);
        NSInteger nwritten = [outputStream write:data maxLength:fmin(len, maxFrameSize)];
        LOG(@"%@", ::dump(@"HeftConnection::WriteData : ", data, len));

        if(nwritten <= 0)
            throw communication_exception();

        len -= nwritten;
        data += nwritten;
    }
}

- (void)writeAck:(UInt16)ack{
    while(![outputStream hasSpaceAvailable]);
    NSInteger nwritten = [outputStream write:(uint8_t*)&ack maxLength:sizeof(ack)];
    LOG(@"%@",::dump(@"HeftConnection::writeAck : ", &ack, sizeof(ack)));
    if(nwritten != sizeof(ack))
        throw communication_exception();
}

#pragma mark NSStreamDelegate

- (void)stream:(NSInputStream*)aStream handleEvent:(NSStreamEvent)eventCode{
    if(eventCode == NSStreamEventHasBytesAvailable){
        Assert(aStream == inputStream);

        NSUInteger nread;
        //LOG(@"stream waiting for read lock");
        [bufferLock lock];
        //LOG(@"stream got read lock");
        do {
            if(ourBufferSize == currentPosition)
            {
                ourBufferSize += ciDefaultMaxFrameSize;
                uint8_t* temp = (uint8_t*)malloc(ourBufferSize);
                memcpy(temp, tmpBuf, currentPosition);
                free(tmpBuf);
                tmpBuf = temp;
            }
            double minread = ourBufferSize - currentPosition;
            nread = [inputStream read:&tmpBuf[currentPosition] maxLength:minread];
            LOG(@"%@",::dump(@"HeftConnection::ReadDataStream : ", &tmpBuf[currentPosition], (int)nread));
            currentPosition += nread;

        } while ([inputStream hasBytesAvailable]);

        [bufferLock unlockWithCondition:currentPosition ? eHasDataCondition : eNoDataCondition];
    }
    else
    {
        LOG(@"stream eventCode:%d", (int)eventCode);
    }
}

#pragma mark -

- (int)readData:(vector<UINT8>&)buffer timeout:(eConnectionTimeout)timeout{
    //vector<UINT8>& vBuf = *reinterpret_cast<vector<UINT8>*>(buffer);
    NSUInteger initSize = buffer.size();

    //LOG(@"readData waiting for read lock");
    if(![bufferLock lockWhenCondition:eHasDataCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:ciTimeout[timeout]]]){
        //LOG(@"readData read lock timed out");
        if(timeout == eFinanceTimeout){
            LOG(@"Finance timeout");
            throw timeout4_exception();
        }
        else{
            LOG(@"Response timeout");
            throw timeout2_exception();
        }
    }

    //LOG(@"readData got read lock");
    buffer.resize(initSize + currentPosition);
    memcpy(&buffer[initSize], tmpBuf, currentPosition);

    int nread = currentPosition;
    currentPosition = 0;

    [bufferLock unlockWithCondition:eNoDataCondition];
    //LOG(@"readData released lock");

    if(nread > 6)
        LOG(@"HeftConnection::readData %d: %c%c%c%c", nread, tmpBuf[2], tmpBuf[3], tmpBuf[4], tmpBuf[5]);

    return nread;
}

- (UInt16)readAck{
    UInt16 ack = 0;
    //LOG(@"readAck waiting for lock");
    if(![bufferLock lockWhenCondition:eHasDataCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:ciTimeout[eAckTimeout]]]){
        LOG(@"Ack timeout");
        throw timeout1_exception();
    }
    //LOG(@"readAck got read lock");

    Assert(currentPosition >= sizeof(ack));
    memcpy(&ack, tmpBuf, sizeof(ack));
    currentPosition -= sizeof(ack);
    memcpy(tmpBuf, tmpBuf + sizeof(ack), currentPosition);

    [bufferLock unlockWithCondition:currentPosition ? eHasDataCondition : eNoDataCondition];
    //LOG(@"readAck released lock (currentPosition: %d)", currentPosition);
    //LOG(@"HeftConnection::readAck %04X", ack);
    return ack;
}

#pragma mark property

- (void)setMaxBufferSize:(int)aMaxBufferSize{
    if(maxFrameSize != aMaxBufferSize){
        maxFrameSize = aMaxBufferSize;
        free(tmpBuf);
        tmpBuf = (uint8_t*)malloc(maxFrameSize);
        Assert(tmpBuf);
    }
}

@end
