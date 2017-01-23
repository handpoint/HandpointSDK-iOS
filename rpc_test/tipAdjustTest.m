//
//  tipAdjustTest.m
//  headstart
//
//  Created by Matti on 03/11/16.
//  Copyright © 2016 zdv. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HapiRemoteService.h"

@interface tipAdjustTest : XCTestCase

@end

@implementation tipAdjustTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSetup {
    NSString* shared_secret = @"0102030405060708091011121314151617181920212223242526272829303132";

    BOOL result = setupHandpointApiConnection(shared_secret);
    XCTAssertTrue(result);
    
    result = setupHandpointApiConnection(nil);
    XCTAssertFalse(result);
    
    result = setupHandpointApiConnection(@"");
    XCTAssertFalse(result);
    
}

- (void)testHash {
    // test the hashing of the data, refactor to a function.
}


- (void)testTipAdjustcall {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Call a web methond and get an answer"];

    NSString* shared_secret = @"0102030405060708091011121314151617181920212223242526272829303132";
    BOOL result = setupHandpointApiConnection(shared_secret);
    XCTAssertTrue(result);
    
    NSString* transaction_id = @"d50af540-a1b0-11e6-85e6-07b2a5f091ec";

    result = tipAdjustment(transaction_id, 100, ^(TipAdjustmentStatus status)
                                {
                                    NSLog(@"tipAdjustment callback: %d", (int)status );
                                    XCTAssertTrue(result == TipAdjustmentAuthorised, @"The result of the call should be Authorized");
                                    [expectation fulfill];
                                }
    );
    XCTAssertTrue(result);
    [self waitForExpectationsWithTimeout:30.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

/*
- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
  }];
}
 */

@end
