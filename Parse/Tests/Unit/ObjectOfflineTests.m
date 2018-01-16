/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

@import Bolts.BFTask;

#import "PFObject.h"
#import "PFOfflineStore.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface ObjectOfflineTests : PFUnitTestCase

@end

@implementation ObjectOfflineTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id)mockedOfflineStore {
    id store = PFStrictClassMock([PFOfflineStore class]);
    [Parse _currentManager].offlineStore = store;
    return store;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testFetchFromLocalDatastore {
    id store = [self mockedOfflineStore];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];

    [OCMExpect([store fetchObjectLocallyAsync:object]) andReturn:[BFTask taskWithResult:nil]];
    XCTAssertNoThrow([object fetchFromLocalDatastore]);

    OCMVerifyAll(store);
}

- (void)testFetchFromLocalDatastoreWithError {
    id store = [self mockedOfflineStore];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];

    NSError *expectedError = [NSError errorWithDomain:@"YoloTest" code:100500 userInfo:nil];
    [OCMExpect([store fetchObjectLocallyAsync:object]) andReturn:[BFTask taskWithError:expectedError]];

    NSError *error = nil;
    XCTAssertNoThrow([object fetchFromLocalDatastore:&error]);
    XCTAssertEqualObjects(error, expectedError);

    OCMVerifyAll(store);
}

- (void)testFetchFromLocalDatastoreViaTask {
    id store = [self mockedOfflineStore];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    [OCMExpect([store fetchObjectLocallyAsync:object]) andReturn:[BFTask taskWithResult:object]];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[object fetchFromLocalDatastoreInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, object);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(store);
}

- (void)testFetchFromLocalDatastoreViaBlock {
    id store = [self mockedOfflineStore];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    [OCMExpect([store fetchObjectLocallyAsync:object]) andReturn:[BFTask taskWithResult:object]];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [object fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject *resultObject, NSError *error) {
        XCTAssertEqual(resultObject, object);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(store);
}

@end
