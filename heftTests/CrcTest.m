//
//  CrcTests.m
//  headstart
//

#import "CrcTest.h"
#import "../heft/Shared/Crc.h"

@implementation CrcTest

- (void)testCrcGeneral{
	UINT8 dataForCrc[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
	USHORT crc = CalcCRC(dataForCrc, sizeof dataForCrc, 100);
	STAssertEquals(crc, (USHORT)0x47b2, @"");
}

- (void)testCrcOddDataSize{
	UINT8 dataForCrc[] = {1, 2, 3, 4, 5, 6, 7, 8, 9};
	USHORT crc = CalcCRC(dataForCrc, sizeof dataForCrc, 100);
	STAssertEquals(crc, (USHORT)0xa1ad, @"");
}

- (void)testCrcZeroSeed{
	UINT8 dataForCrc[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
	USHORT crc = CalcCRC(dataForCrc, sizeof dataForCrc);
	STAssertEquals(crc, (USHORT)0x2378, @"");
}

- (void)testCrcZeroLengthData{
	UINT8 dataForCrc[1];
	const int ciSeed = 100;
	USHORT crc = CalcCRC(dataForCrc, 0, ciSeed);
	STAssertEquals(crc, (USHORT)ciSeed, @"");
}

- (void)testCrcNullData{
	const int ciSeed = 100;
	USHORT crc = CalcCRC(0, 0, ciSeed);
	STAssertEquals(crc, (USHORT)ciSeed, @"");
}

@end
