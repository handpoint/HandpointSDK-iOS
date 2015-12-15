//
//  HeftConnection.m
//  headstart
//

#import "HeftConnection.h"
#import "HeftRemoteDevice.h"


#import "Exception.h"
#import "Logger.h"
#import "debug.h"

#include <queue>
#include <vector>

using Buffer = std::vector<uint8_t>;
using InputQueue = std::queue<Buffer>;

extern NSString* eaProtocol;

const int ciDefaultMaxFrameSize = 256; // Bluetooth frame is 0 - ~343 bytes
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
    
    InputQueue inputQueue; // a queue for all incoming bluetooth data
    NSConditionLock* bufferLock;
}

@synthesize maxFrameSize;
@synthesize ourBufferSize;

- (id)initWithDevice:(HeftRemoteDevice*)aDevice
{
    EASession* eaSession = nil;
    NSInputStream* is = nil;
    NSOutputStream* os = nil;
    BOOL result = NO;
    
    if(aDevice.accessory) {
        LOG(@"protocol strings: %@", aDevice.accessory.protocolStrings);
        eaSession = [[EASession alloc] initWithAccessory:aDevice.accessory forProtocol:eaProtocol];
        result = eaSession != nil;
        if(result) {
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
    if(result)
    {
        if(self = [super init])
        {
            LOG(@"Connected to %@", aDevice.name);
            device = aDevice;
            session = eaSession;
            outputStream = os;
            inputStream = is;
            inputStream.delegate = self;
            maxFrameSize = ciDefaultMaxFrameSize;
            ourBufferSize = ciDefaultMaxFrameSize;
            bufferLock = [[NSConditionLock alloc] initWithCondition:eNoDataCondition];
        }
        return self;
    }
    
    self = nil;
    return self;
}


/*
 [[_session inputStream] close];
 [[_session inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
 [[_session inputStream] setDelegate:nil];
 [[_session outputStream] close];
 [[_session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
 [[_session outputStream] setDelegate:nil];
 
 [_session release];
 _session = nil;
 
 [_writeData release];
 _writeData = nil;
 [_readData release];
 _readData = nil;
 */


- (void)dealloc
{
    LOG(@"Disconnection from %@", device.name);
    [self shutdown];
}

- (void)shutdown
{
    LOG(@"Heftconnection shutdown.");
    if(device)
    {
        if(device.accessory)
        {
            NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
            [outputStream close];
            [outputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
            [inputStream close];
            [inputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        }
    }
    session = nil;
    
    inputStream.delegate = nil;
    outputStream.delegate = nil;
    
    outputStream = nil;
    inputStream = nil;
}

- (void)resetData
{
    
    if(inputQueue.size())
    {
        LOG(@"resetData waiting for read lock");
        [bufferLock lockWhenCondition:eHasDataCondition];
        LOG(@"resetData got read lock");
        while (!inputQueue.empty())
        {
            inputQueue.pop();
        }
        [bufferLock unlockWithCondition:eNoDataCondition];
        LOG(@"resetData released read lock");
    }
    
}

- (void)writeData:(uint8_t*)data length:(int)len
{
    
    while (len) {
        while(![outputStream hasSpaceAvailable])
        {
            [NSThread sleepForTimeInterval:.025];
        }
        
        NSInteger nwritten = [outputStream write:data maxLength:fmin(len, maxFrameSize)];
        LOG(@"%@", ::dump(@"HeftConnection::WriteData : ", data, len));
        
        if(nwritten <= 0)
            throw communication_exception();
        
        len -= nwritten;
        data += nwritten;
    }
}

- (void)writeAck:(UInt16)ack {
    while(![outputStream hasSpaceAvailable])
    {
        [NSThread sleepForTimeInterval:.025];
    }
    NSInteger nwritten = [outputStream write:(uint8_t*)&ack maxLength:sizeof(ack)];
    LOG(@"%@",::dump(@"HeftConnection::writeAck : ", &ack, sizeof(ack)));
    if(nwritten != sizeof(ack))
        throw communication_exception();
}

#pragma mark NSStreamDelegate

- (void)stream:(NSInputStream*)aStream handleEvent:(NSStreamEvent)eventCode
{
    if(eventCode == NSStreamEventHasBytesAvailable)
    {
        Assert(aStream == inputStream);
        
        
        /*
         * Have a buffer (vector). Read into it until there is no more data
         * Add the buffer to the input queue.
         * This implementation is still locking too much, it should only lock
         * when inserting a buffer into the input queue.
         */
        
        NSUInteger nread;
        const int bufferSize = 512;
        
        do {
            Buffer readBuffer;
            readBuffer.resize(bufferSize);
            nread = [inputStream read:&readBuffer[0] maxLength:bufferSize];
            LOG(@"%@ (%d bytes)",::dump(@"HeftConnection::ReadDataStream : ", &readBuffer[0], (int)nread), (int)nread);
            readBuffer.resize(nread);
            [bufferLock lock]; // don't care for a condition, queue can be empty or not
            inputQueue.push(std::move(readBuffer));
            [bufferLock unlockWithCondition:eHasDataCondition];
        } while ([inputStream hasBytesAvailable]);
    }
    else
    {
        LOG(@"stream eventCode:%d", (int)eventCode);
    }
}

#pragma mark -

- (int)readData:(std::vector<std::uint8_t>&)buffer timeout:(eConnectionTimeout)timeout
{
    auto initSize = buffer.size();
    
    if(![bufferLock lockWhenCondition:eHasDataCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:ciTimeout[timeout]]])
    {
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
    
    // if we want to hold the lock for as short a time as possible, create a local array of references/pointers
    // and remove all the buffers from the queue - release the lock and then copy buffers from queueue
    // to the read buffer
    
    LOG(@"readData got read lock");
    // get everything from the queue
    while (inputQueue.empty() == false)
    {
        Buffer& head = inputQueue.front();
        buffer.insert(std::end(buffer), std::begin(head), std::end(head));
        inputQueue.pop();
    }
    
    [bufferLock unlockWithCondition:eNoDataCondition];
    
    int bytes_read = static_cast<int>(buffer.size() - initSize);
    return bytes_read;
}

- (UInt16)readAck{
    UInt16 ack = 0;
    
    if(![bufferLock lockWhenCondition:eHasDataCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:ciTimeout[eAckTimeout]]])
    {
        LOG(@"Ack timeout");
        throw timeout1_exception();
    }
    
    Buffer& head = inputQueue.front();
    if (head.size() >= sizeof(ack))
    {
        memcpy(&ack, &head[0], sizeof(ack));
        if (head.size() > sizeof(ack))
        {
            // remove the first elements from the buffer and shift everything else to the front
            // do not remove the buffer from queue
            head.erase(head.begin(), head.begin() + sizeof(ack));
        }
        else
        {
            // we are done with this packet, remove the buffer from the queue
            inputQueue.pop();
        }
    }
    
    if (inputQueue.empty())
    {
        [bufferLock unlockWithCondition:eNoDataCondition];
    }
    else
    {
        [bufferLock unlockWithCondition:eHasDataCondition];
    }
    
    LOG(@"HeftConnection::readAck %04X %04X", ack, ntohs(ack));
    return ack;
}

#pragma mark property

- (void)setMaxBufferSize:(int)aMaxBufferSize{
    if(maxFrameSize != aMaxBufferSize){
        maxFrameSize = aMaxBufferSize;
    }
}

@end
