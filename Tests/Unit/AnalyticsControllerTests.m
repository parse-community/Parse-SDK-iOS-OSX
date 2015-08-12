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

- (PFEventuallyQueue *)eventuallyQueueMockWithCommandResult:(PFCommandResult *)result {
    BFTask *task = [BFTask taskWithResult:result];

    id queueMock = PFClassMock([PFEventuallyQueue class]);
    OCMStub([queueMock enqueueCommandInBackground:OCMOCK_ANY]).andReturn(task);
    return queueMock;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    PFEventuallyQueue *queue = [self eventuallyQueueMockWithCommandResult:nil];

    PFAnalyticsController *controller = [[PFAnalyticsController alloc] initWithEventuallyQueue:queue];
    XCTAssertNotNil(controller);
    XCTAssertEqual(controller.eventuallyQueue, queue);

    controller = [PFAnalyticsController controllerWithEventuallyQueue:queue];
    XCTAssertNotNil(controller);
    XCTAssertEqual(controller.eventuallyQueue, queue);
}

- (void)testTrackEventWithInvalidParameters {
    PFEventuallyQueue *queue = [self eventuallyQueueMockWithCommandResult:nil];
    PFAnalyticsController *controller = [PFAnalyticsController controllerWithEventuallyQueue:queue];

    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:nil dimensions:nil sessionToken:nil]);
    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:@" " dimensions:nil sessionToken:nil]);
    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:@"\n" dimensions:nil sessionToken:nil]);
    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:@"f"
                                                                    dimensions:@{ @2: @"five" }
                                                                  sessionToken:nil]);
    PFAssertThrowsInvalidArgumentException([controller trackEventAsyncWithName:@"f"
                                                                    dimensions:@{ @"num" : @5 }
                                                                  sessionToken:nil]);
}

- (void)testTrackEventParameters {
    id queue = PFStrictClassMock([PFEventuallyQueue class]);
    OCMExpect([queue enqueueCommandInBackground:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertNotEqual([command.httpPath rangeOfString:@"boom"].location, NSNotFound);
        XCTAssertEqualObjects(command.parameters[@"dimensions"], @{ @"yarr" : @"yolo" });
        XCTAssertEqualObjects(command.sessionToken, @"argh");

        return YES;
    }]]);

    PFAnalyticsController *controller = [PFAnalyticsController controllerWithEventuallyQueue:queue];
    [[controller trackEventAsyncWithName:@"boom"
                              dimensions:@{ @"yarr" : @"yolo" }
                            sessionToken:@"argh"] waitUntilFinished];

    OCMVerifyAll(queue);
}

- (void)testTrackEventResult {
    PFCommandResult *result = [PFCommandResult commandResultWithResult:@{}
                                                          resultString:nil
                                                          httpResponse:nil];
    PFEventuallyQueue *queue = [self eventuallyQueueMockWithCommandResult:result];
    PFAnalyticsController *controller = [PFAnalyticsController controllerWithEventuallyQueue:queue];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller trackEventAsyncWithName:@"a"
                             dimensions:nil
                           sessionToken:nil] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testTrackAppOpenedParameters {
    id queue = PFStrictClassMock([PFEventuallyQueue class]);
    OCMExpect([queue enqueueCommandInBackground:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertNotEqual([command.httpPath rangeOfString:@"AppOpened"].location, NSNotFound);
        XCTAssertNotNil(command.parameters[@"push_hash"]);
        XCTAssertEqualObjects(command.sessionToken, @"argh");

        return YES;
    }]]);

    PFAnalyticsController *controller = [PFAnalyticsController controllerWithEventuallyQueue:queue];
    [[controller trackAppOpenedEventAsyncWithRemoteNotificationPayload:@{ @"aps" : @{ @"alert" : @"yolo" } }
                                                         sessionToken:@"argh"] waitUntilFinished];

    OCMVerifyAll(queue);
}

- (void)testTrackAppOpenedResult {
    PFCommandResult *result = [PFCommandResult commandResultWithResult:@{}
                                                          resultString:nil
                                                          httpResponse:nil];
    PFEventuallyQueue *queue = [self eventuallyQueueMockWithCommandResult:result];
    PFAnalyticsController *controller = [PFAnalyticsController controllerWithEventuallyQueue:queue];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller trackAppOpenedEventAsyncWithRemoteNotificationPayload:nil
                                                          sessionToken:nil] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @YES);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

@end
