/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFCoreManager.h"
#import "PFObjectPrivate.h"
#import "PFPinningObjectStore.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface ObjectPinTests : PFUnitTestCase

@end

@implementation ObjectPinTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id)mockPinObjects:(NSArray *)objects withPinName:(NSString *)pinName error:(NSError *)error {
    PFPinningObjectStore *store = PFStrictClassMock([PFPinningObjectStore class]);
    [Parse _currentManager].coreManager.pinningObjectStore = store;

    BFTask *task = (error ? [BFTask taskWithError:error] : [BFTask taskWithResult:@YES]);
    OCMExpect([store pinObjectsAsync:objects
                         withPinName:pinName
                     includeChildren:YES]).andReturn(task);

    return store;
}

- (id)mockUnpinObjects:(NSArray *)objects withPinName:(NSString *)pinName error:(NSError *)error {
    PFPinningObjectStore *store = PFStrictClassMock([PFPinningObjectStore class]);
    [Parse _currentManager].coreManager.pinningObjectStore = store;

    BFTask *task = (error ? [BFTask taskWithError:error] : [BFTask taskWithResult:@YES]);
    OCMExpect([store unpinObjectsAsync:objects withPinName:pinName]).andReturn(task);

    return store;
}

- (id)mockUnpinAllObjectsWithPinName:(NSString *)pinName error:(NSError *)error {
    PFPinningObjectStore *store = PFStrictClassMock([PFPinningObjectStore class]);
    [Parse _currentManager].coreManager.pinningObjectStore = store;

    BFTask *task = (error ? [BFTask taskWithError:error] : [BFTask taskWithResult:@YES]);
    OCMExpect([store unpinAllObjectsAsyncWithPinName:pinName]).andReturn(task);

    return store;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

#pragma mark Pinning

- (void)testPinObject {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockPinObjects:@[ object ] withPinName:PFObjectDefaultPin error:nil];

    XCTAssertTrue([object pin]);
    OCMVerifyAll(mock);
}

- (void)testPinObjectWithError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockPinObjects:@[ object ] withPinName:PFObjectDefaultPin error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([object pin:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testPinObjectViaTask {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockPinObjects:@[ object ] withPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[object pinInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testPinObjectViaBlock {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockPinObjects:@[ object ] withPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [object pinInBackgroundWithBlock:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testPinObjectWithName {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockPinObjects:@[ object ] withPinName:@"Pirates" error:nil];

    XCTAssertTrue([object pinWithName:@"Pirates"]);
    OCMVerifyAll(mock);
}

- (void)testPinObjectWithNameError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockPinObjects:@[ object ] withPinName:@"Pirates" error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([object pinWithName:@"Pirates" error:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testPinObjectWithNameViaTask {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockPinObjects:@[ object ] withPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[object pinInBackgroundWithName:@"Pirates"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testPinObjectWithNameViaBlock {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockPinObjects:@[ object ] withPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [object pinInBackgroundWithName:@"Pirates" block:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

#pragma mark Pinning Many Objects

- (void)testPinAll {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockPinObjects:objects withPinName:PFObjectDefaultPin error:nil];

    XCTAssertTrue([PFObject pinAll:objects]);
    OCMVerifyAll(mock);
}

- (void)testPinAllWithError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];

    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockPinObjects:objects withPinName:PFObjectDefaultPin error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([PFObject pinAll:objects error:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testPinAllViaTask {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockPinObjects:objects withPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFObject pinAllInBackground:objects] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testPinAllViaBlock {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockPinObjects:objects withPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFObject pinAllInBackground:objects block:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testPinAllWithName {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockPinObjects:objects withPinName:@"Pirates" error:nil];

    XCTAssertTrue([PFObject pinAll:objects withName:@"Pirates"]);
    OCMVerifyAll(mock);
}

- (void)testPinAllWithNameError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];

    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockPinObjects:objects withPinName:@"Pirates" error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([PFObject pinAll:objects withName:@"Pirates" error:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testPinAllWithNameViaTask {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockPinObjects:objects withPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFObject pinAllInBackground:objects withName:@"Pirates"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testPinAllWithNameViaBlock {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockPinObjects:objects withPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFObject pinAllInBackground:objects withName:@"Pirates" block:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

#pragma mark Unpinning

- (void)testUnpinObject {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockUnpinObjects:@[ object ] withPinName:PFObjectDefaultPin error:nil];

    XCTAssertTrue([object unpin]);
    OCMVerifyAll(mock);
}

- (void)testUnpinObjectWithError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockUnpinObjects:@[ object ] withPinName:PFObjectDefaultPin error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([object unpin:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testUnpinObjectViaTask {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockUnpinObjects:@[ object ] withPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[object unpinInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinObjectViaBlock {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockUnpinObjects:@[ object ] withPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [object unpinInBackgroundWithBlock:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinObjectWithName {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockUnpinObjects:@[ object ] withPinName:@"Pirates" error:nil];

    XCTAssertTrue([object unpinWithName:@"Pirates"]);
    OCMVerifyAll(mock);
}

- (void)testUnpinObjectWithNameError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockUnpinObjects:@[ object ] withPinName:@"Pirates" error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([object unpinWithName:@"Pirates" error:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testUnpinObjectWithNameViaTask {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockUnpinObjects:@[ object ] withPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[object unpinInBackgroundWithName:@"Pirates"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinObjectWithNameViaBlock {
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    id mock = [self mockUnpinObjects:@[ object ] withPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [object unpinInBackgroundWithName:@"Pirates" block:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

#pragma mark Unpinning Many Objects

- (void)testUnpinAll {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockUnpinObjects:objects withPinName:PFObjectDefaultPin error:nil];

    XCTAssertTrue([PFObject unpinAll:objects]);
    OCMVerifyAll(mock);
}

- (void)testUnpinAllWithError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];

    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockUnpinObjects:objects withPinName:PFObjectDefaultPin error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([PFObject unpinAll:objects error:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testUnpinAllViaTask {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockUnpinObjects:objects withPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFObject unpinAllInBackground:objects] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinAllWithBlock {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockUnpinObjects:objects withPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFObject unpinAllInBackground:objects block:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinAllWithName {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockUnpinObjects:objects withPinName:@"Pirates" error:nil];

    XCTAssertTrue([PFObject unpinAll:objects withName:@"Pirates"]);
    OCMVerifyAll(mock);
}

- (void)testUnpinAllWithNameError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];

    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockUnpinObjects:objects withPinName:@"Pirates" error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([PFObject unpinAll:objects withName:@"Pirates" error:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testUnpinAllWithNameViaTask {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockUnpinObjects:objects withPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFObject unpinAllInBackground:objects withName:@"Pirates"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinAllWithNameViaBlock {
    NSArray *objects = @[ [PFObject objectWithClassName:@"Yarr"] ];
    id mock = [self mockUnpinObjects:objects withPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFObject unpinAllInBackground:objects withName:@"Pirates" block:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinAllObjects {
    id mock = [self mockUnpinAllObjectsWithPinName:PFObjectDefaultPin error:nil];
    XCTAssertTrue([PFObject unpinAllObjects]);
    OCMVerifyAll(mock);
}

- (void)testUnpinAllObjectsWithError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];
    id mock = [self mockUnpinAllObjectsWithPinName:PFObjectDefaultPin error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([PFObject unpinAllObjects:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testUnpinAllObjectsViaTask {
    id mock = [self mockUnpinAllObjectsWithPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFObject unpinAllObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinAllObjectsViaBlock {
    id mock = [self mockUnpinAllObjectsWithPinName:PFObjectDefaultPin error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFObject unpinAllObjectsInBackgroundWithBlock:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinAllObjectsWithName {
    id mock = [self mockUnpinAllObjectsWithPinName:@"Pirates" error:nil];
    XCTAssertTrue([PFObject unpinAllObjectsWithName:@"Pirates"]);
    OCMVerifyAll(mock);
}

- (void)testUnpinAllObjectsWithNameError {
    NSError *expectedError = [NSError errorWithDomain:@"Yolo!" code:100500 userInfo:nil];
    id mock = [self mockUnpinAllObjectsWithPinName:@"Pirates" error:expectedError];

    NSError *error = nil;
    XCTAssertFalse([PFObject unpinAllObjectsWithName:@"Pirates" error:&error]);
    XCTAssertEqualObjects(error, expectedError);
    OCMVerifyAll(mock);
}

- (void)testUnpinAllObjectsWithNameViaTask {
    id mock = [self mockUnpinAllObjectsWithPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFObject unpinAllObjectsInBackgroundWithName:@"Pirates"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

- (void)testUnpinAllObjectsWithNameViaBlock {
    id mock = [self mockUnpinAllObjectsWithPinName:@"Pirates" error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFObject unpinAllObjectsInBackgroundWithName:@"Pirates" block:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(mock);
}

@end
