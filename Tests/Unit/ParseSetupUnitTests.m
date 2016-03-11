/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestCase.h"
#import "Parse_Private.h"

@interface ParseSetupUnitTests : PFTestCase

@end

@implementation ParseSetupUnitTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)tearDown {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];

    [super tearDown];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testLDSEnabledWithoutInitializer {
    XCTAssertFalse([Parse isLocalDatastoreEnabled]);
    [Parse enableLocalDatastore];

    XCTAssertTrue([Parse isLocalDatastoreEnabled]);
    [Parse setApplicationId:@"a" clientKey:@"b"];

    XCTAssertTrue([Parse isLocalDatastoreEnabled]);
}

- (void)testInitializeWithLDSAfterInitializeShouldThrowException {
    [Parse setApplicationId:@"a" clientKey:@"b"];
    PFAssertThrowsInconsistencyException([Parse enableLocalDatastore]);
}

- (void)testInitializeWithNilApplicationIdShouldThrowException {
    NSString *yolo = nil;
    PFAssertThrowsInvalidArgumentException([Parse setApplicationId:yolo clientKey:yolo]);
    PFAssertThrowsInvalidArgumentException([Parse setApplicationId:yolo clientKey:@"a"]);
    PFAssertThrowsInvalidArgumentException([Parse setApplicationId:@"a" clientKey:yolo]);
}

@end
