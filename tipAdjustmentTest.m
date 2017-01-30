//
//  tipAdjustmentTest.m
//  headstart
//
//  Created by Matti on 03/11/16.
//  Copyright © 2016 zdv. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HapiRemoteService.h"

@interface tipAdjustmentTest : XCTestCase

@end

@implementation tipAdjustmentTest

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];

    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)testSetup {
    BOOL result = setupRemoteConnectionWithCardreader();
    XCTAssertTrue(result);
}

- (void)testTipAdjust {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    // BOOL result = tipAdjustment
    XCTAssert(FALSE);
}

@end
