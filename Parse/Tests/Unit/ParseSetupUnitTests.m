/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCommandRunning.h"
#import "PFEventuallyQueue_Private.h"
#import "PFHTTPRequest.h"
#import "PFRESTCommand.h"
#import "PFTestCase.h"
#import "ParseManagerPrivate.h"
#import "Parse_Private.h"

static dispatch_time_t PFTimeFromNow(NSTimeInterval seconds) {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC));
}

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
#pragma mark - Helpers
///--------------------------------------

- (void)initializeParse {
    [self warmUpApplication];
    XCTestExpectation *expectation = [self expectationForNotification:PFParseInitializeDidCompleteNotification
                                                                object:nil
                                                               handler:nil];
    [Parse setApplicationId:@"a" clientKey:@"b"];
    [self waitForExpectations:@[ expectation ] timeout:30];
}

- (void)mockCommandRunnerFailingWithTemporaryErrorAndDo:(void (^)(void))block {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain
                                         code:NSURLErrorNotConnectedToInternet
                                     userInfo:@{ @"temporary" : @YES }];
    id commandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    OCMStub([commandRunner runCommandAsync:[OCMArg any] withOptions:0])
    .andReturn([BFTask taskWithError:error])
    .andDo(^(NSInvocation *invocation) {
        block();
    });
    [Parse _currentManager].commandRunner = commandRunner;
}

- (void)enqueueCommandInQueue:(PFEventuallyQueue *)queue {
    PFRESTCommand *command = [PFRESTCommand commandWithHTTPPath:@"classes/Yolo"
                                                     httpMethod:PFHTTPRequestMethodPOST
                                                     parameters:@{}
                                                   sessionToken:nil
                                                          error:nil];
    [queue enqueueCommandInBackground:command];
}

- (dispatch_group_t)clearEventuallyQueueInBackground {
    ParseManager *manager = [Parse _currentManager];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        [manager clearEventuallyQueue];
    });
    return group;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testClearEventuallyQueueWaitsForRunningCommands {
    [Parse enableLocalDatastore];
    [self initializeParse];

    PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
    [queue pause];
    queue.connected = YES;

    // Block the next run of commands until it is released
    dispatch_semaphore_t runStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t runReleased = dispatch_semaphore_create(0);
    id queueMock = PFPartialMock(queue);
    OCMStub([queueMock _pendingCommandIdentifiers]).andReturn(@[]).andDo(^(NSInvocation *invocation) {
        dispatch_semaphore_signal(runStarted);
        dispatch_semaphore_wait(runReleased, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(runReleased);
    });
    [queue resume];
    XCTAssertEqual(dispatch_semaphore_wait(runStarted, PFTimeFromNow(10)), 0L);

    // Running commands may still access the local datastore, so clearing must wait for them
    dispatch_group_t clearing = [self clearEventuallyQueueInBackground];
    XCTAssertNotEqual(dispatch_group_wait(clearing, PFTimeFromNow(0.5)), 0L);

    dispatch_semaphore_signal(runReleased);
    XCTAssertEqual(dispatch_group_wait(clearing, PFTimeFromNow(10)), 0L);
}

- (void)testClearEventuallyQueueDoesNotRetryRunningCommand {
    [self initializeParse];

    PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
    [queue pause];
    queue.connected = YES;

    // Block the command until it is released, then fail it with an error that is retried
    dispatch_semaphore_t commandStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t commandReleased = dispatch_semaphore_create(0);
    [self mockCommandRunnerFailingWithTemporaryErrorAndDo:^{
        dispatch_semaphore_signal(commandStarted);
        dispatch_semaphore_wait(commandReleased, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(commandReleased);
    }];
    [queue resume];
    [self enqueueCommandInQueue:queue];
    XCTAssertEqual(dispatch_semaphore_wait(commandStarted, PFTimeFromNow(10)), 0L);

    dispatch_group_t clearing = [self clearEventuallyQueueInBackground];
    XCTAssertNotEqual(dispatch_group_wait(clearing, PFTimeFromNow(0.5)), 0L);

    // The command fails after clearing paused the queue, so the queue must not wait to retry it
    dispatch_semaphore_signal(commandReleased);
    XCTAssertEqual(dispatch_group_wait(clearing, PFTimeFromNow(10)), 0L);
}

- (void)testClearEventuallyQueueStopsWaitingToRetryCommand {
    [self initializeParse];

    PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
    [queue pause];
    queue.connected = YES;
    [self mockCommandRunnerFailingWithTemporaryErrorAndDo:^{}];

    // The run of commands reads the retry interval once it waits to retry a command
    dispatch_semaphore_t waitingToRetry = dispatch_semaphore_create(0);
    id queueMock = PFPartialMock(queue);
    OCMStub([queueMock retryInterval]).andDo(^(NSInvocation *invocation) {
        dispatch_semaphore_signal(waitingToRetry);
    }).andForwardToRealObject();
    [queue resume];
    [self enqueueCommandInQueue:queue];
    XCTAssertEqual(dispatch_semaphore_wait(waitingToRetry, PFTimeFromNow(10)), 0L);

    dispatch_group_t clearing = [self clearEventuallyQueueInBackground];
    XCTAssertEqual(dispatch_group_wait(clearing, PFTimeFromNow(10)), 0L);
}

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
