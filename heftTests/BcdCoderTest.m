//
//  BcdCoderTest.m
//  headstart
//

#import "BCDCoderTest.h"
#import "../heft/Shared/BCDCoder.h"

@implementation BCDCoderTest

- (void)testBcdCoderEncodeGeneral{
	char src[] = "01234567";
	const UINT8 standard[] = {0x01, 0x23, 0x45, 0x67};
	UINT8 buf[sizeof standard] = {0};
	BCDCoder::Encode(src, buf, sizeof buf);
	STAssertEquals(memcmp(buf, standard, sizeof standard), 0, @"");
}

- (void)testBcdCoderEncodeNonDigits{
	char src[] = "012AWMX7";
	const UINT8 standard[] = {0x01, 0x21, 0x7D, 0x87};
	UINT8 buf[sizeof standard] = {0};
	BCDCoder::Encode(src, buf, sizeof buf);
	STAssertEquals(memcmp(buf, standard, sizeof standard), 0, @"");
}

- (void)testBcdCoderEncodeZeroLengthData{
	char src[] = "01234567";
	const UINT8 standard[sizeof src] = {0};
	UINT8 buf[sizeof standard] = {0};
	BCDCoder::Encode(src, buf, 0);
	STAssertEquals(memcmp(buf, standard, sizeof standard), 0, @"");
}

- (void)testBcdCoderEncodeNullData{
	char src[] = "01234567";
	//UINT8 standard[] = {0x01, 0x23, 0x45, 0x67};
	//UINT8 buf[sizeof standard] = {0};
	BCDCoder::Encode(src, 0, 0);
	//BOOST_CHECK(memcmp(buf, standard, sizeof standard) == 0);
}

/*- (void)testBcdCoderEncodeOddDataSize{
	char src[7] = {0, 1, 2, 3, 4, 5, 6};
	const UINT8 standard[] = {0x01, 0x23, 0x45, 0x60};
	UINT8 buf[sizeof standard] = {0};
	BCDCoder::Encode(src, buf, sizeof buf);
	STAssertTrue(memcmp(buf, standard, sizeof standard) == 0,@"");
}*/

- (void)testBcdCoderDecodeGeneral{
	UINT8 buf[] = {0x01, 0x23, 0x45, 0x67};
	string result = BCDCoder::Decode(buf, sizeof buf);
  	STAssertEqualObjects(@(result.c_str()), @"01234567", @"");
   	STAssertEquals((int)(result.length() & 1), 0, @"");
}

- (void)testBcdCoderDecodeZeroLengthData{
	UINT8 buf[] = {0, 1, 2, 3, 4, 5, 6, 7};
	string result = BCDCoder::Decode(buf, 0);
	STAssertTrue(result.empty(), @"");
}

- (void)testBcdCoderDecodeNullData{
	string result = BCDCoder::Decode(0, 0);
	STAssertTrue(result.empty(), @"");
}

@end
