/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "BFTask+Private.h"
#import "PFAnalyticsController.h"
#import "PFCommandResult.h"
#import "PFEventuallyQueue.h"
#import "PFRESTCommand.h"
#import "PFTestCase.h"

@interface AnalyticsControllerTests : PFTestCase

@end

@implementation AnalyticsControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFEventuallyQueueProvider>)dataSourceMock {
    id queueMock = PFStrictClassMock([PFEventuallyQueue class]);
    id dataSource = PFStrictProtocolMock(@protocol(PFEventuallyQueueProvider));
    OCMStub([dataSource eventuallyQueue]).andReturn(queueMock);
    return dataSource;
}

- (id<PFEventuallyQueueProvider>)dataSourceMockWithCommandResult:(PFCommandResult *)result {
    id dataSource = [self dataSourceMock];
    id queue = [dataSource eventuallyQueue];
    OCMStub([queue enqueueCommandInBackground:OCMOCK_ANY]).andReturn([BFTask taskWithResult:result]);
    return dataSource;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id dataSource = [self dataSourceMock];

    PFAnalyticsController *controller = [[PFAnalyticsController alloc] initWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);

    controller = [PFAnalyticsController controllerWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);
}

- (void)testTrackEventWithInvalidParameters {
    id dataSource = [self dataSourceMockWithCommandResult:nil];
    PFAnalyticsController *controller = [PFAnalyticsController controllerWithDataSource:dataSource];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:nil dimensions:nil sessionToken:nil]);
#pragma clang diagnostic pop

    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:@" " dimensions:nil sessionToken:nil]);
    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:@"\n" dimensions:nil sessionToken:nil]);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-literal-conversion"
    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:@"f"
                                                                    dimensions:@{ @2 : @"five" }
                                                                  sessionToken:nil]);
    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:@"f"
                                                                    dimensions:@{ @"num" : @5 }
                                                                  sessionToken:nil]);
#pragma clang diagnostic pop
}

- (void)testTrackEventParameters {
    id dataSource = [self dataSourceMock];
    id queue = [dataSource eventuallyQueue];
    OCMExpect([queue enqueueCommandInBackground:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertNotEqual([command.httpPath rangeOfString:@"boom"].location, NSNotFound);
        XCTAssertEqualObjects(command.parameters[@"dimensions"], @{ @"yarr" : @"yolo" });
        XCTAssertEqualObjects(command.sessionToken, @"argh");

        return YES;
    }]]);

    PFAnalyticsController *controller = [PFAnalyticsController controllerWithDataSource:dataSource];
    [[controller trackEventAsyncWithName:@"boom"
                              dimensions:@{ @"yarr" : @"yolo" }
                            sessionToken:@"argh"] waitUntilFinished];

    OCMVerifyAll(queue);
}

- (void)testTrackEventResult {
    PFCommandResult *result = [PFCommandResult commandResultWithResult:@{}
                                                          resultString:nil
                                                          httpResponse:nil];
    id dataSource = [self dataSourceMockWithCommandResult:result];
    PFAnalyticsController *controller = [PFAnalyticsController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller trackEventAsyncWithName:@"a"
                              dimensions:nil
                            sessionToken:nil] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testTrackAppOpenedParameters {
    id dataSource = [self dataSourceMock];
    id queue = [dataSource eventuallyQueue];
    OCMExpect([queue enqueueCommandInBackground:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertNotEqual([command.httpPath rangeOfString:@"AppOpened"].location, NSNotFound);
        XCTAssertNotNil(command.parameters[@"push_hash"]);
        XCTAssertEqualObjects(command.sessionToken, @"argh");

        return YES;
    }]]);

    PFAnalyticsController *controller = [PFAnalyticsController controllerWithDataSource:dataSource];
    [[controller trackAppOpenedEventAsyncWithRemoteNotificationPayload:@{ @"aps" : @{@"alert" : @"yolo"} }
                                                          sessionToken:@"argh"] waitUntilFinished];

    OCMVerifyAll(queue);
}

- (void)testTrackAppOpenedResult {
    PFCommandResult *result = [PFCommandResult commandResultWithResult:@{}
                                                          resultString:nil
                                                          httpResponse:nil];
    id dataSource = [self dataSourceMockWithCommandResult:result];
    PFAnalyticsController *controller = [PFAnalyticsController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller trackAppOpenedEventAsyncWithRemoteNotificationPayload:nil
                                                          sessionToken:nil] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

@end
