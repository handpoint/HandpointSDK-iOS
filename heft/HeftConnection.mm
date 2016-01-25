//
//  HeftConnection.m
//  headstart
//

#import "HeftConnection.h"
#import "HeftRemoteDevice.h"
#import "HeftManager.h"
#import "MpedDevice.h"

#import "Exception.h"
#import "Logger.h"
#import "debug.h"

#include <queue>
#include <vector>
#include <algorithm> // min

using std::min;
using Buffer = std::vector<uint8_t>;
using InputQueue = std::queue<Buffer>;
using OutputQueue = std::queue<Buffer>;

extern NSString* eaProtocol;

const int ciDefaultMaxFrameSize = 4096; // Bluetooth frame is 0 - ~343 bytes
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
    NSRunLoop* streamRunLoop;
    
    // __weak MpedDevice* aPedDevice;
    
    // __weak NSObject<HeftStatusReportDelegate>* delegate;
    
    InputQueue inputQueue;
    OutputQueue outputQueue;
    NSConditionLock* bufferLock;
}

@synthesize maxFrameSize;
@synthesize ourBufferSize;

- (id)initWithDevice:(HeftRemoteDevice*)aDevice runLoop:(NSRunLoop*) runLoop
{
    EASession* eaSession = nil;
    NSInputStream* is = nil;
    NSOutputStream* os = nil;
    BOOL result = NO;
    streamRunLoop = runLoop;
    
    if(aDevice.accessory) {
        LOG(@"protocol strings: %@", aDevice.accessory.protocolStrings);
        eaSession = [[EASession alloc] initWithAccessory:aDevice.accessory
                                             forProtocol:eaProtocol];
        result = eaSession != nil;
        if(result) {
            // TODO: Testing currentRunLoop instead of mainRunLoop - change or remove ol
            // NSRunLoop* runLoop = [NSRunLoop mainRunLoop];
            // NSRunLoop* runLoop = [NSRunLoop currentRunLoop];            
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



- (void)dealloc
{
    LOG(@"Heftconnection dealloc [%@]", device.name);
    [self shutdown];
}

- (void)addClient:(MpedDevice*)pedDevice
{
    // self->aPedDevice = pedDevice;
}

- (void)shutdown
{
    LOG(@"Heftconnection shutdown");
    if(device && device.accessory)
    {
        if (streamRunLoop)
        {
            NSRunLoop* runLoop = streamRunLoop;
            streamRunLoop = nil;
            
            [outputStream close];
            [outputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
            [inputStream close];
            [inputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        }
        
        device = nil;
    }
    session = nil;

    if (inputStream)
    {
        inputStream.delegate = nil;
        inputStream = nil;
    }

    if (outputStream)
    {
        outputStream.delegate = nil;
        outputStream = nil;
    }
    
    [self resetData];
    
    // HeftManager* heftManager = [HeftManager sharedManager];
    // [heftManager cleanup];
    
    
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [aPedDevice didLostAccessoryDevice:device];
    });
    */

   
}

- (void)resetData
{
    if(inputQueue.size())
    {
        LOG(@"resetData waiting for read lock");
        // TODO: simple wait for lock, we know there is data
        // [bufferLock lockWhenCondition:eHasDataCondition];
        [bufferLock lock];
        LOG(@"resetData got read lock");
        while (!inputQueue.empty())
        {
            inputQueue.pop();
        }
        [bufferLock unlockWithCondition:eNoDataCondition];
        LOG(@"resetData released read lock");
    }
}

// TODO: put data into outputqueue...
//       and write to the stream when
//       possible.
//       That means we have to copy the data
//       And since this is blocking, we must look
//       at the calling code, writing should be a
//       fire and forget method
- (void)writeData:(uint8_t*)data length:(int)len
{
    while (len) {
        while(![outputStream hasSpaceAvailable])
        {
            [NSThread sleepForTimeInterval:.025];
        }
        
        NSInteger nwritten = [outputStream write:data maxLength:min(len, maxFrameSize)];
        
        if(nwritten <= 0)
            throw communication_exception();

        LOG(@"%@", ::dump(@"HeftConnection::WriteData : ", data, nwritten));
        
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
    LOG(@"handleEvent starting, eventCode: %d", (int)eventCode);
    
    switch (eventCode)
    {
        case NSStreamEventHasBytesAvailable:
            if (aStream == inputStream)
            {
                // Assert(aStream == inputStream); // why the assert? what if it is a outputStream?
                
                /*
                 * Have a buffer (vector). Read into it until there is no more data
                 * Add the buffer to the input queue.
                 */
                
                NSUInteger nread;
                const int bufferSize = ciDefaultMaxFrameSize;

                do {
                    Buffer readBuffer;
                    readBuffer.resize(bufferSize);
                    nread = [inputStream read:&readBuffer[0] maxLength:bufferSize];
                    LOG(@"%@ (%d bytes)",::dump(@"HeftConnection::handleEvent: ", &readBuffer[0], (int)nread), (int)nread);
                    
                    if (nread > 0)
                    {
                        readBuffer.resize(nread);
                        
                        // TODO: hafa ekki sama lás hér, lásinn fyrir readData er í raun EVENT
                        // en þessi þráður á aldrei að blokka eftir readData fallinu
                        
                        // nota GCD queue til að stjórna þessu, þá sér stýrikerfið um
                        // lásana...nota barrier í readData partion (þá blokkar það)
                        
                        [bufferLock lock]; // don't care for a condition, queue can be empty or not
                        inputQueue.push(std::move(readBuffer));
                        [bufferLock unlockWithCondition:eHasDataCondition];
                    }
                } while ([inputStream hasBytesAvailable]);
            }
            else
            {
                LOG(@"HeftConnection::handleEvent, stream is not an inputStream");
            }
        
        
            // hvað með að gera unlock eNoDataCondition?
            break;
        case NSStreamEventEndEncountered:
            LOG(@"HeftConnection::handleEvent, NSStreamEventEndEncountered");
            [self shutdown];
            break;
        case NSStreamEventErrorOccurred:
            LOG(@"HeftConnection::handleEvent, NSStreamEventErrorOccurred");
            [self shutdown];
            break;
        default:
            LOG(@"HeftConnection::handleEvent, unhandled event");
            break;
    }
    
    LOG(@"handleEvent returning");
}

#pragma mark -

- (int)readData:(std::vector<std::uint8_t>&)buffer timeout:(eConnectionTimeout)timeout
{
    auto initSize = buffer.size();
    
    if(![bufferLock lockWhenCondition:eHasDataCondition beforeDate:[NSDate dateWithTimeIntervalSinceNow:ciTimeout[timeout]]])
    {
        LOG(@"readData read lock timed out. inputQueue.empty() == %@", inputQueue.empty() ? @"True" : @"False");
        
        if(timeout == eFinanceTimeout)
        {
            LOG(@"Finance timeout");
            throw timeout4_exception();
        }
        else
        {
            LOG(@"Response timeout");
            throw timeout2_exception();
        }
    }
    
    LOG(@"readData got read lock");
    // get everything from the queue
    while (inputQueue.empty() == false)
    {
        Buffer& head = inputQueue.front();
        buffer.insert(std::end(buffer), std::begin(head), std::end(head));
        inputQueue.pop();
    }
    
    [bufferLock unlockWithCondition:eNoDataCondition];
    
    auto bytes_read = buffer.size() - initSize;
    LOG(@"readData returning %lu bytes", bytes_read);

    return static_cast<int>(bytes_read);
}

- (UInt16)readAck{
    UInt16 ack = 0;
    
    if(![bufferLock lockWhenCondition:eHasDataCondition
                           beforeDate:[NSDate dateWithTimeIntervalSinceNow:ciTimeout[eAckTimeout]]])
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
        LOG(@"readAck, queue empty");

        [bufferLock unlockWithCondition:eNoDataCondition];
    }
    else
    {
        LOG(@"readAck, data still in queue - %lu items and %lu bytes at head", inputQueue.size(), head.size());
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
