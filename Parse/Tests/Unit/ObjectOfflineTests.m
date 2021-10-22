/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Bolts.BFTask;

#import "PFObject.h"
#import "PFOfflineStore.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface ObjectOfflineTests : PFUnitTestCase

@end

@interface MockedOfflineStore : NSObject

@property (nonatomic, strong) id toReturn;
@property (nonatomic, assign) BOOL wasCalled;

-(BFTask *)fetchObjectLocallyAsync:(PFObject *) object;

@end

@implementation MockedOfflineStore
- (BFTask *)fetchObjectLocallyAsync: object {
    [self setWasCalled:YES];
    return  _toReturn;
}
@end



@implementation ObjectOfflineTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id)mockedOfflineStore {
    id store = [MockedOfflineStore new];
    [Parse _currentManager].offlineStore = store;
    return store;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testFetchFromLocalDatastore {
    id store = [self mockedOfflineStore];
    
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    [store setToReturn:[BFTask taskWithResult:nil]];
    XCTAssertNoThrow([object fetchFromLocalDatastore]);

    XCTAssert([store wasCalled]);
}

- (void)testFetchFromLocalDatastoreWithError {
    id store = [self mockedOfflineStore];
    
    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    NSError *expectedError = [NSError errorWithDomain:@"YoloTest" code:100500 userInfo:nil];
    
    [store setToReturn:[BFTask taskWithError:expectedError]];

    NSError *error = nil;
    XCTAssertNoThrow([object fetchFromLocalDatastore:&error]);
    XCTAssertEqualObjects(error, expectedError);

    XCTAssert([store wasCalled]);
}

- (void)testFetchFromLocalDatastoreViaTask {
    id store = [self mockedOfflineStore];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    [store setToReturn:[BFTask taskWithResult:object]];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[object fetchFromLocalDatastoreInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, object);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTAssert([store wasCalled]);
}

- (void)testFetchFromLocalDatastoreViaBlock {
    
    XCTExpectFailureWithOptions(@"Suspected issue with async tests and OCMock", XCTExpectedFailureOptions.nonStrictOptions);
    
    id store = [self mockedOfflineStore];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    [store setToReturn:[BFTask taskWithResult:object]];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [object fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject *resultObject, NSError *error) {
        XCTAssertEqual(resultObject, object);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];

    XCTAssert([store wasCalled]);
}

@end


