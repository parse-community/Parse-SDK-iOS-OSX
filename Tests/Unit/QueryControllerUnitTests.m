/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

@import Bolts.BFCancellationTokenSource;

#import "BFTask+Private.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFMutableQueryState.h"
#import "PFObject.h"
#import "PFQueryController.h"
#import "PFTestCase.h"

@interface QueryControllerUnitTests : PFTestCase

@end

@implementation QueryControllerUnitTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFCommandRunnerProvider>)mockedCommonDataSource {
    id<PFCommandRunnerProvider> dataSource = PFStrictProtocolMock(@protocol(PFCommandRunnerProvider));

    id runner = PFStrictProtocolMock(@protocol(PFCommandRunning));

    PFCommandResult *result = [PFCommandResult commandResultWithResult:@{ @"results" : @[ @{@"className" : @"Yolo",
                                                                                            @"name" : @"yarr",
                                                                                            @"objectId" : @"abc",
                                                                                            @"job" : @"pirate"} ],
                                                                          @"count" : @5 }
                                                          resultString:nil
                                                          httpResponse:nil];
    BFTask *task = [BFTask taskWithResult:result];
    OCMStub([[runner ignoringNonObjectArgs] runCommandAsync:OCMOCK_ANY
                                                withOptions:0
                                          cancellationToken:OCMOCK_ANY]).andReturn(task);

    OCMStub(dataSource.commandRunner).andReturn(runner);

    return dataSource;
}

- (PFQueryState *)sampleQueryState {
    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"Yolo"];
    [queryState setEqualityConditionWithObject:@"yarr" forKey:@"name"];
    [queryState selectKeys:@[ @"name" ]];
    return [queryState copy];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id<PFCommandRunnerProvider> dataSource = [self mockedCommonDataSource];

    PFQueryController *controller = [[PFQueryController alloc] initWithCommonDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.commonDataSource, dataSource);

    controller = [PFQueryController controllerWithCommonDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.commonDataSource, dataSource);
}

- (void)testFindObjectsResult {
    PFQueryController *controller = [PFQueryController controllerWithCommonDataSource:[self mockedCommonDataSource]];
    PFQueryState *state = [self sampleQueryState];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        NSArray *objects = task.result;
        XCTAssertNotNil(objects);
        XCTAssertEqual(objects.count, 1);

        PFObject *object = [objects lastObject];
        XCTAssertNotNil(object);
        XCTAssertEqualObjects(object.parseClassName, @"Yolo");
        XCTAssertEqualObjects(object.objectId, @"abc");
        XCTAssertEqualObjects(object[@"name"], @"yarr");

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsCancellation {
    PFQueryController *controller = [PFQueryController controllerWithCommonDataSource:[self mockedCommonDataSource]];
    PFQueryState *state = [self sampleQueryState];

    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    [cancellationTokenSource cancel];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:cancellationTokenSource.token
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCountObjectsResult {
    PFQueryController *controller = [PFQueryController controllerWithCommonDataSource:[self mockedCommonDataSource]];
    PFQueryState *state = [self sampleQueryState];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller countObjectsAsyncForQueryState:state
                          withCancellationToken:nil
                                           user:nil] continueWithBlock:^id(BFTask *task) {
        NSNumber *count = task.result;
        XCTAssertNotNil(count);
        XCTAssertEqual([count intValue], 5);

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCountObjectsCancellation {
    PFQueryController *controller = [PFQueryController controllerWithCommonDataSource:[self mockedCommonDataSource]];
    PFQueryState *state = [self sampleQueryState];

    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    [cancellationTokenSource cancel];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller countObjectsAsyncForQueryState:state
                          withCancellationToken:cancellationTokenSource.token
                                           user:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCacheKey {
    PFQueryState *state = [self sampleQueryState];
    PFQueryController *controller = [PFQueryController controllerWithCommonDataSource:[self mockedCommonDataSource]];

    XCTAssertNil([controller cacheKeyForQueryState:state sessionToken:@"a"]);
    XCTAssertNil([controller cacheKeyForQueryState:state sessionToken:nil]);
}

- (void)testHasCachedResult {
    PFQueryState *state = [self sampleQueryState];
    PFQueryController *controller = [PFQueryController controllerWithCommonDataSource:[self mockedCommonDataSource]];

    XCTAssertFalse([controller hasCachedResultForQueryState:state sessionToken:@"a"]);
    XCTAssertFalse([controller hasCachedResultForQueryState:state sessionToken:nil]);
}

- (void)testClearCachedResult {
    PFQueryState *state = [self sampleQueryState];
    PFQueryController *controller = [PFQueryController controllerWithCommonDataSource:[self mockedCommonDataSource]];

    // It should do nothing - so just test it doesn't crash.
    [controller clearCachedResultForQueryState:state sessionToken:@"a"];
    [controller clearCachedResultForQueryState:state sessionToken:nil];
}

- (void)testClearAllCachedResults {
    PFQueryController *controller = [PFQueryController controllerWithCommonDataSource:[self mockedCommonDataSource]];

    // It should do nothing - so just test it doesn't crash.
    [controller clearAllCachedResults];
}

@end
