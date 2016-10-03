//
//  FrameTest.m
//  headstart
//

#if 0

#import "FrameTest.h"
#import "../heft/Shared/Frame.h"

@implementation FrameTest

#define STAssertThrowsSpecificCpp(expr, specificException, description, ...) \
do { \
	BOOL __caughtException = NO; \
	try { \
		(expr);\
	} \
	catch (specificException) { \
		__caughtException = YES; \
	}\
	catch (...) {\
		__caughtException = YES; \
		NSString *_descrip = [@(#specificException) stringByAppendingString: @" is not expected exception."] ;\
		[self failWithException:([NSException failureInRaise:@(#expr) \
													exception:nil \
														inFile:@(__FILE__) \
														atLine:__LINE__ \
												withDescription:@"%@", STComposeString(_descrip, ##__VA_ARGS__)])]; \
	}\
	if (!__caughtException) { \
		NSString *_descrip = [@(#specificException) stringByAppendingString: @" expected exception was not thrown."] ;\
		[self failWithException:([NSException failureInRaise:@(#expr) \
													exception:nil \
													inFile:@(__FILE__) \
													atLine:__LINE__ \
												withDescription:@"%@", STComposeString(_descrip, ##__VA_ARGS__)])]; \
	} \
} while (0)

- (void)testWriteFrameGeneral{
   	UINT8 src[] = {1, 2, 3};
	const UINT8 standard[] = {0x10, 0x02, 1, 2, 3, 0x10, 0x03, 0x2D, 0x79};
	Frame frame(src, sizeof src, false);
	STAssertEquals(frame.GetLength(), (int)sizeof standard, @"");
	STAssertEquals(memcmp(frame.GetData(), standard, sizeof standard), 0, @"");
 }

- (void)testWriteFramePartial{
	UINT8 src[] = {1, 2, 3};
	const UINT8 standard[] = {0x10, 0x02, 1, 2, 3, 0x10, 0x17, 0x7F, 0xCC};
	Frame frame(src, sizeof src, true);
	STAssertEquals(frame.GetLength(), (int)sizeof standard, @"");
	STAssertEquals(memcmp(frame.GetData(), standard, sizeof standard), 0, @"");
}

- (void)testReadFrameGeneral{
	UINT8 src[] = {0x10, 0x02, 1, 2, 3, 0x10, 0x03, 0x2D, 0x79};
	Frame frame(src, sizeof src);
	STAssertTrue(frame.isValidCrc(), @"");
	STAssertTrue(!frame.isPartial(), @"");
}

- (void)testReadFrameLessThanMin{
	UINT8 src[] = {0x10, 0x02, 0x00, 0x10, 0x03};
	STAssertThrowsSpecificCpp(Frame(src, sizeof src), communication_exception, @"Bad exception");
}

- (void)testReadFramePartial{
	UINT8 src[] = {0x10, 0x02, 1, 2, 3, 0x10, 0x17, 0x7F, 0xCC};
	Frame frame(src, sizeof src);
	STAssertTrue(frame.isValidCrc(), @"");
	STAssertTrue(frame.isPartial(), @"");
}

- (void)testReadFrameCrcInvalid{
	UINT8 src[] = {0x10, 0x02, 1, 2, 3, 0x10, 0x17, 0x7F, 0xC0};
	Frame frame(src, sizeof src);
	STAssertTrue(!frame.isValidCrc(), @"");
}

@end


#endif