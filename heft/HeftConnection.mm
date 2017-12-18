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

#include <vector>

extern NSString *eaProtocol;

int ciDefaultMaxFrameSize = 256; // Bluetooth frame is 0 - ~343 bytes
const int64_t ciTimeout[] = {20, 15, 1, 5 * 60};

const int64_t SECOND_IN_NANOSECONDS = 1000000000;

enum eBufferConditions
{
    eNoDataCondition, eHasDataCondition
};

@interface HeftConnection () <NSStreamDelegate>
@end

@implementation HeftConnection
{
    HeftRemoteDevice *device;
    EASession *session;
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    NSRunLoop *streamRunLoop;

    NSMutableData *outputData;
    NSMutableData *inputData;
    NSConditionLock *bufferLock;
    dispatch_semaphore_t fd_sema;
}

@synthesize maxFrameSize;
@synthesize ourBufferSize;

- (id)initWithDevice:(HeftRemoteDevice *)aDevice runLoop:(NSRunLoop *)runLoop
{
    EASession *eaSession = nil;
    NSInputStream *is = nil;
    NSOutputStream *os = nil;
    streamRunLoop = runLoop;

    NSUInteger outputDataCapacitySize = 4096;
    NSUInteger inputDataCapacitySize = 16384;

    outputData = [NSMutableData dataWithCapacity:outputDataCapacitySize];
    inputData = [NSMutableData dataWithCapacity:inputDataCapacitySize];

    if (aDevice.accessory)
    {
        LOG(@"protocol strings: %@", aDevice.accessory.protocolStrings);
        eaSession = [[EASession alloc] initWithAccessory:aDevice.accessory
                                             forProtocol:eaProtocol];
        if (eaSession != nil)
        {
            is = eaSession.inputStream;
            [is scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
            [is open];
            os = eaSession.outputStream;
            [os scheduleInRunLoop:runLoop forMode:NSDefaultRunLoopMode];
            [os open];

            if (self = [super init])
            {
                LOG(@"Connected to %@", aDevice.name);
                device = aDevice;
                session = eaSession;
                outputStream = os;
                outputStream.delegate = self;
                inputStream = is;
                inputStream.delegate = self;
                maxFrameSize = ciDefaultMaxFrameSize;
                ourBufferSize = ciDefaultMaxFrameSize;
                bufferLock = [[NSConditionLock alloc] initWithCondition:eNoDataCondition];
                fd_sema = dispatch_semaphore_create(0);
            }
            return self;
        }
    }

    // it failed
    LOG(@"Connection to %@ failed", aDevice.name);
    self = nil;
    return self;
}


- (void)dealloc
{
    LOG(@"Heftconnection dealloc [%@]", device.name);
    [self shutdown];
}


- (void)shutdown
{
    LOG(@"Heftconnection shutdown");
    NSRunLoop *runLoop = nil;;
    if (device && device.accessory)
    {
        if (streamRunLoop)
        {
            runLoop = streamRunLoop;
            streamRunLoop = nil;
        }

        device = nil;
    }
    session = nil;

    if (inputStream)
    {
        // TODO:   fix crash, EXC_BAD_ACCESS(code=1, address=0x1281bb00)
        [inputStream close];
        if (runLoop)
        {
            [inputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        }
        inputStream.delegate = nil;
        inputStream = nil;
    }

    if (outputStream)
    {
        [outputStream close];
        if (runLoop)
        {
            [outputStream removeFromRunLoop:runLoop forMode:NSDefaultRunLoopMode];
        }
        outputStream.delegate = nil;
        outputStream = nil;
    }

    outputData = nil;
    inputData = nil;

    [self resetData];
}

- (void)resetData
{
}


/*
 NSStreamStatus
 ---------------
 NSStreamStatusNotOpen = 0,
 NSStreamStatusOpening = 1,
 NSStreamStatusOpen = 2,
 NSStreamStatusReading = 3,
 NSStreamStatusWriting = 4,
 NSStreamStatusAtEnd = 5,
 NSStreamStatusClosed = 6,
 NSStreamStatusError = 7
 */
bool isStatusAnError (NSStreamStatus status)
{
    return status == NSStreamStatusNotOpen ||
            status == NSStreamStatusClosed ||
            status == NSStreamStatusError ||
            status == NSStreamStatusAtEnd;
}

- (void)writeData:(uint8_t *)data length:(int)len
{
    LOG(@"%@", ::dump(@"HeftConnection::WriteData : ", data, (int) len));

    @synchronized (outputData)
    {
        [outputData appendBytes:data length:len];
    }
    [self write_from_queue_to_stream];
}

- (void)writeAck:(UInt16)ack
{
    LOG(@"writeAck");
    @synchronized (outputData)
    {
        [outputData appendBytes:(uint8_t *) &ack length:sizeof(ack)];
    }
    [self write_from_queue_to_stream];
}

- (void)write_from_queue_to_stream;
{
    LOG(@"HeftConnection::write_from_queue_to_stream");
    @synchronized (outputData)
    {
        if ([outputData length] > 0)
        {
            NSInteger written = [outputStream write:(uint8_t *) [outputData bytes] maxLength:[outputData length]];

            LOG(@"HeftConnection::write_from_queue_to_stream, sent %d bytes, len=%d", (int) written, (int) [outputData length]);

            if (written < [outputData length])
            {
                // remove the written bytes from the buffer and shift everything else to the front
                NSRange range = NSMakeRange(0, written);
                [outputData replaceBytesInRange:range withBytes:NULL length:0];
                return; // since we could not write all of the data, we wait for the next event
            }
            else
            {
                // we are done with this packet, remove the buffer from the queue
                [outputData setLength:0];
            }
        }
    }
}

#pragma mark NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    LOG(@"handleEvent starting, eventCode: %d, thread: <%@>", (int) eventCode, [NSThread currentThread]);

    switch (eventCode)
    {
        case NSStreamEventOpenCompleted:
            LOG(@"HeftConnection::handleEvent, NSStreamEventOpenCompleted");
            break;
        case NSStreamEventHasBytesAvailable:
            LOG(@"HeftConnection::handleEvent, NSStreamEventHasBytesAvailable");

            if (aStream == inputStream)
            {
                NSUInteger nread;
                const int bufferSize = ciDefaultMaxFrameSize * 2; // the buffer isn't large - keep a bigger buffer
                // just in case things are ... buffered up!
                do
                {
                    uint8_t buf[bufferSize];
                    nread = [inputStream read:buf maxLength:bufferSize];
                    LOG(@"%@ (%d bytes)", ::dump(@"HeftConnection::handleEvent: ", buf, (int) nread), (int) nread);

                    if (nread > 0)
                    {
                        @synchronized (inputData)
                        {
                            [inputData appendBytes:buf length:nread];
                        }
                    }
                } while ([inputStream hasBytesAvailable]);

                LOG(@"Signaling semaphore");
                dispatch_semaphore_signal(fd_sema);
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
        case NSStreamEventHasSpaceAvailable:
            if (aStream == outputStream)
            {
                LOG(@"HeftConnection::handleEvent, NSStreamEventHasSpaceAvailable on outputStream");
                [self write_from_queue_to_stream];
            }
            else
            {
                LOG(@"HeftConnection::handleEvent, NSStreamEventHasSpaceAvailable on inputStream!");
            }
            break;

        default:
            LOG(@"HeftConnection::handleEvent, unhandled event");
            break;
    }

    LOG(@"handleEvent returning");
}

#pragma mark -

- (int)readData:(std::vector<std::uint8_t> &)buffer timeout:(eConnectionTimeout)timeout
{
    LOG(@"readData");

    if (dispatch_semaphore_wait(fd_sema, dispatch_time(DISPATCH_TIME_NOW, ciTimeout[timeout] * SECOND_IN_NANOSECONDS)))
    {
        if (timeout == eFinanceTimeout)
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

    NSUInteger length = 0;
    @synchronized (inputData)
    {
        length = [inputData length];
        if (length)
        {
            buffer.insert(std::end(buffer), (uint8_t *) [inputData bytes], (uint8_t *) [inputData bytes] + length);
            [inputData setLength:0];
        }
    }
    return (int) length;
}

- (UInt16)readAck
{
    LOG(@"readAck");

    UInt16 ack = 0;

    @synchronized (inputData)
    {
        if ([inputData length] >= 2)
        {
            ack = *(UInt16 *) [inputData bytes]; // cast the void* to a UInt16* and then dereference that
            NSRange range = NSMakeRange(0, 2);
            [inputData replaceBytesInRange:range withBytes:NULL length:0]; // remove the bytes from inputData
            return ack;
        }
    }


    // need to wait for data since buffer did not have two bytes
    if (dispatch_semaphore_wait(fd_sema, dispatch_time(DISPATCH_TIME_NOW, ciTimeout[eAckTimeout] * SECOND_IN_NANOSECONDS)))
    {
        LOG(@"Ack timeout");
        throw timeout1_exception();
    }

    @synchronized (inputData)
    {
        if ([inputData length] >= 2)
        {
            ack = *(UInt16 *) [inputData bytes]; // cast int the void* to a UInt16* and then dereference that
            NSRange range = NSMakeRange(0, 2);
            [inputData replaceBytesInRange:range withBytes:NULL length:0]; // remove the bytes from inputData
            if ([inputData length])
            {
                // still data in buffer, don't want to block on it, so we signal the semaphore
                dispatch_semaphore_signal(fd_sema);
            }
        }
    }
    return ack;
}

#pragma mark property

- (void)setMaxBufferSize:(int)aMaxBufferSize
{
    if (maxFrameSize != aMaxBufferSize)
    {
        maxFrameSize = aMaxBufferSize;
    }
}

@end