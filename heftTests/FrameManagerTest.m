//
//  FrameManagerTest.m
//  headstart
//

#import "FrameManagerTest.h"
#import "../heft/Shared/Frame.h"
#import "../heft/Shared/FrameManager.h"
#import "../heft/Shared/RequestCommand.h"
#import "HeftConnection.h"

#define FREEMANAGER_READ_GENERAL_STAGE_0 0x49, 0x30, 0x31, 0x30
#define FREEMANAGER_READ_GENERAL_STAGE_1 0x30, 0x30, 0x30, 0x30, 0x30, 0x30

#pragma mark -

@interface TestConnection : HeftConnection
@end

@implementation TestConnection

- (void)writeData:(uint8_t *)data length:(int)len{
}

- (void)writeAck:(UInt16)ack{
}

- (int)readData:(vector<UINT8>&)buffer timeout:(eConnectionTimeout)timeout{
	return 0;
}

- (UInt16)readAck{
	return POSITIVE_ACK;
}

@end

#pragma mark -

@interface TestConnectionGeneral : TestConnection
@end

@implementation TestConnectionGeneral
- (int) readData:(vector<UINT8> &)buffer timeout:(eConnectionTimeout)timeout{
	static int state = 0;
	switch(state++){
		case 0:{
			UINT8 state0[] = {FREEMANAGER_READ_GENERAL_STAGE_0};
			buffer.insert(buffer.end(), &state0[0], &state0[sizeof state0]);
			return sizeof state0;
		}
		case 1:{
			UINT8 state1[] = {FREEMANAGER_READ_GENERAL_STAGE_1, 0x10, 0x03, 0xEA, 0x69};
			buffer.insert(buffer.end(), &state1[0], &state1[sizeof state1]);
			return sizeof state1;
		}
	}
	return 0;
}

@end

#pragma mark -

@interface TestConnectionDleDoubling : TestConnection
@end

@implementation TestConnectionDleDoubling

- (int)readData:(vector<UINT8> &)buffer timeout:(eConnectionTimeout)timeout{
	const UINT8 standard[] = {0x49, 0x10, 0x10, 0x03, 0x10, 0x03, 0x57, 0x4F};
	buffer.insert(buffer.end(), &standard[0], &standard[sizeof standard]);
	return sizeof standard;
}

@end

#pragma mark -

@interface TestConnectionSplit : TestConnection
@end

@implementation TestConnectionSplit

- (int)readData:(vector<UINT8> &)buffer timeout:(eConnectionTimeout)timeout{
    const UINT8 standard[] = {0x49, 0x30, 0x31, 0x30, 0x10, 0x17, 0xD0, 0x41, 0x10, 0x02, 0x30, 0x30, 0x10, 0x03, 0xDA, 0x5C};
    buffer.insert(buffer.end(), &standard[0], &standard[sizeof standard]);
    return sizeof standard;
}

@end

#pragma mark -

@interface TestConnectionSplitWithClearBuffer : TestConnection
@end

@implementation TestConnectionSplitWithClearBuffer

- (int)readData:(vector<UINT8> &)buffer timeout:(eConnectionTimeout)timeout{
    static int state;
    const UINT8 standard[] = {0x49, 0x30, 0x31, 0x30, 0x10, 0x17, 0xD0, 0x41};
    const UINT8 standard1[] = {0x10, 0x02, 0x30, 0x30, 0x10, 0x03, 0xDA, 0x5C};
    if(state == 0){
        ++state;
        buffer.insert(buffer.end(), &standard[0], &standard[sizeof standard]);
        return sizeof standard;
    }
    else{
        buffer.insert(buffer.end(), &standard1[0], &standard1[sizeof standard1]);
        return sizeof standard1;
    }
}

@end

#pragma mark -

@implementation FrameManagerTest

- (void)testFrameManagerWriteGeneral{
	IdleRequestCommand src;
	FrameManager fm(src, 100);
	vector<Frame>& frames(fm.GetFrames());
	STAssertEquals(frames.size(), (vector<Frame>::size_type)1, @"");
	
	const UINT8 standard[] = {0x10, 0x02, 0x49, 0x30, 0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x10, 0x03, 0xEA, 0x69};
	Frame& frame(frames[0]);
	STAssertEquals(frame.GetLength(), (int)sizeof standard, @"");
	STAssertEquals(memcmp(frame.GetData(), standard, sizeof standard), 0, @"");
}

- (void)testFrameManagerWriteDleDoubling{
	UINT8 src_data[] = {0x00, 0x10, 0x20};
	vector<UINT8> data(&src_data[0], &src_data[sizeof src_data]);
	ReceiveResponseCommand src(data);
	FrameManager fm(src, 100);
	vector<Frame>& frames(fm.GetFrames());
	STAssertEquals(frames.size(), (vector<Frame>::size_type)1, @"");
	
	const UINT8 standard[] = {0x10, 0x02, 0x48, 0x30, 0x32, 0x31, 0x30, 0x30, 0x30, 0x31, 0x30, 0x30, 0x30, 0x30, 0x30, 0x37, 0x00, 0x00, 0x00, 0x03, 0x00, 0x10, 0x10, 0x20, 0x10, 0x03, 0x40, 0x01};
	Frame& frame(frames[0]);
	STAssertEquals(frame.GetLength(), (int)sizeof standard, @"");
	STAssertEquals(memcmp(frame.GetData(), standard, sizeof standard), 0, @"");
}

-(void)testFrameManagerWriteSplit{
	IdleRequestCommand src;
	FrameManager fm(src, 10);
	vector<Frame>& frames(fm.GetFrames());
	STAssertEquals(frames.size(), (vector<Frame>::size_type)3, @"");
	
	const UINT8 standard1[] = {0x10, 0x02, 0x49, 0x30, 0x31, 0x30, 0x10, 0x17, 0xD0, 0x41};
	Frame& frame1(frames[0]);
	STAssertEquals(frame1.GetLength(), (int)sizeof standard1, @"");
	STAssertEquals(memcmp(frame1.GetData(), standard1, sizeof standard1), 0, @"");
	
	const UINT8 standard2[] = {0x10, 0x02, 0x30, 0x30, 0x10, 0x03, 0xDA, 0x5C};
	Frame& frame2(frames[2]);
	STAssertEquals(frame2.GetLength(), (int)sizeof standard2, @"");
	STAssertEquals(memcmp(frame2.GetData(), standard2, sizeof standard2), 0, @"");
}

- (void) testFrameManagerReadGeneral{
	const UINT8 start_buf[] = {0x10, 0x02};
	vector<UINT8> buf(&start_buf[0], &start_buf[sizeof start_buf]);
	FrameManager fm(IdleRequestCommand(), 100);
	STAssertTrue(fm.ReadFrames_test([TestConnectionGeneral new], buf), @"");
    
	const UINT8 standard[] = {FREEMANAGER_READ_GENERAL_STAGE_0, FREEMANAGER_READ_GENERAL_STAGE_1};
	vector<UINT8>& data(fm.GetData());
	STAssertEquals(data.size(), sizeof standard, @"");
    STAssertEquals(memcmp(&data[0], standard, sizeof standard), 0, @"");
}

- (void)testFrameManagerReadDleDoubling{
	const UINT8 start_buf[] = {0x10, 0x02};
	vector<UINT8> buf(&start_buf[0], &start_buf[sizeof start_buf]);
	FrameManager fm(IdleRequestCommand(), 100);
	STAssertTrue(fm.ReadFrames_test([TestConnectionDleDoubling new], buf), @"");
    
	const UINT8 standard[] = {0x49, 0x10, 0x03};
	vector<UINT8>& data(fm.GetData());
	STAssertEquals(data.size(), sizeof standard, @"");
    STAssertEquals(memcmp(&data[0], standard, sizeof standard), 0, @"");
}

- (void)testFrameManagerReadSplit{
	const UINT8 start_buf[] = {0x10, 0x02};
	vector<UINT8> buf(&start_buf[0], &start_buf[sizeof start_buf]);
	FrameManager fm(IdleRequestCommand(), 100);
	STAssertTrue(fm.ReadFrames_test([TestConnectionSplit new], buf), @"");
    
	const UINT8 standard[] = {0x49, 0x30, 0x31, 0x30, 0x30, 0x30};
	vector<UINT8>& data(fm.GetData());
    
    STAssertEquals(data.size(), sizeof standard, @"");
    STAssertEquals(memcmp(&data[0], standard, sizeof standard), 0, @"");
}

- (void)testFrameManagerReadSplitWithClearBuffer{
	const UINT8 start_buf[] = {0x10, 0x02};
	vector<UINT8> buf(&start_buf[0], &start_buf[sizeof start_buf]);
	FrameManager fm(IdleRequestCommand(), 100);
	STAssertTrue(fm.ReadFrames_test([TestConnectionSplitWithClearBuffer new], buf), @"");
    
	const UINT8 standard[] = {0x49, 0x30, 0x31, 0x30, 0x30, 0x30};
	vector<UINT8>& data(fm.GetData());
	STAssertEquals(data.size(), sizeof standard, @"");
    STAssertEquals(memcmp(&data[0], standard, sizeof standard), 0, @"");
}

@end