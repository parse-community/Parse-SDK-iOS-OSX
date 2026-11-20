/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

@import Bolts;

#import "BFTask+Private.h"
#import "PFCloudCodeController.h"
#import "PFCoreManager.h"
#import "PFCurrentUserController.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@protocol CloudCodeMockedObserver <NSObject>

- (void)callbackWithResult:(id)result error:(id)error;

@end

@interface CloudUnitTests : PFUnitTestCase

@end

@implementation CloudUnitTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFCloudCodeController *)cloudCodeControllerWithResult:(id)result error:(NSError *)error {
    BFTask *task = nil;
    if (error) {
        task = [BFTask taskWithError:error];
    } else {
        task = [BFTask taskWithResult:result];
    }

    id controllerMock = PFClassMock([PFCloudCodeController class]);
    OCMStub([controllerMock callCloudCodeFunctionAsync:OCMOCK_ANY
                                        withParameters:OCMOCK_ANY
                                          sessionToken:OCMOCK_ANY]).andReturn(task);
    OCMStub([controllerMock callCloudCodeFunctionAsync:OCMOCK_ANY
                                        withParameters:OCMOCK_ANY
                                          sessionToken:OCMOCK_ANY
                                     cancellationToken:OCMOCK_ANY]).andReturn(task);
    return controllerMock;
}

- (void)mockCloudCodeControllerWithTask:(BFTask *)task
                            callHandler:(void (^)(NSString *function,
                                                  NSDictionary *parameters,
                                                  NSString *sessionToken,
                                                  BFCancellationToken *cancellationToken))callHandler {
    id controllerMock = PFClassMock([PFCloudCodeController class]);
    [[OCMStub([controllerMock callCloudCodeFunctionAsync:OCMOCK_ANY
                                          withParameters:OCMOCK_ANY
                                            sessionToken:OCMOCK_ANY
                                       cancellationToken:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        if (!callHandler) {
            return;
        }
        __unsafe_unretained NSString *function = nil;
        __unsafe_unretained NSDictionary *parameters = nil;
        __unsafe_unretained NSString *sessionToken = nil;
        __unsafe_unretained BFCancellationToken *cancellationToken = nil;
        [invocation getArgument:&function atIndex:2];
        [invocation getArgument:&parameters atIndex:3];
        [invocation getArgument:&sessionToken atIndex:4];
        [invocation getArgument:&cancellationToken atIndex:5];
        callHandler(function, parameters, sessionToken, cancellationToken);
    }] andReturn:task];
    [Parse _currentManager].coreManager.cloudCodeController = controllerMock;
}

- (void)mockCurrentUserSessionTokenWithTask:(BFTask *)task {
    id currentUserController = PFPartialMock([Parse _currentManager].coreManager.currentUserController);
    OCMStub([currentUserController getCurrentUserSessionTokenAsync]).andReturn(task);
}

- (void)waitForMainQueue {
    XCTestExpectation *expectation = [self expectationWithDescription:@"main queue"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    [self waitForTestExpectations];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testCallFunction {
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:@{ @"a" : @"b" }
                                                                                            error:nil];
    id result = [PFCloud callFunction:@"a" withParameters:nil];
    XCTAssertEqualObjects(result, @{ @"a" : @"b" });

    NSError *error = nil;
    result = [PFCloud callFunction:@"a" withParameters:nil error:&error];
    XCTAssertEqualObjects(result, @{ @"a" : @"b" });
    XCTAssertNil(error);
}

- (void)testCallFunctionError {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:nil error:error];

    id result = [PFCloud callFunction:@"a" withParameters:nil];
    XCTAssertNil(result);

    NSError *cloudError = nil;
    result = [PFCloud callFunction:@"a" withParameters:nil error:&cloudError];
    XCTAssertEqualObjects(error, cloudError);
    XCTAssertNil(result);
}

- (void)testCallFunctionViaTask {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:result error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo" withParameters:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionViaBlock {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:result error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFCloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id cloudResult, NSError *error) {
        XCTAssertEqualObjects(cloudResult, result);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionViaTargetSelector {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:result error:nil];

    id mock = PFProtocolMock(@protocol(CloudCodeMockedObserver));

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    OCMStub([mock callbackWithResult:[OCMArg isEqual:result]
                               error:[OCMArg isNil]]).andCall(expectation, @selector(fulfill));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                               target:mock
                             selector:@selector(callbackWithResult:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testCallFunctionErrorViaTask {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:nil error:error];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo" withParameters:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, error);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionErrorViaBlock {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:nil error:error];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFCloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id result, NSError *cloudError) {
        XCTAssertNil(result);
        XCTAssertEqualObjects(error, cloudError);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionErrorViaTargetSelector {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:nil error:error];

    id mock = PFProtocolMock(@protocol(CloudCodeMockedObserver));

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    OCMStub([mock callbackWithResult:[OCMArg isNil]
                               error:[OCMArg isEqual:error]]).andCall(expectation, @selector(fulfill));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                               target:mock
                             selector:@selector(callbackWithResult:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testCallFunctionParameters {
    id controllerMock = PFClassMock([PFCloudCodeController class]);
    [Parse _currentManager].coreManager.cloudCodeController = controllerMock;

    NSDictionary *parameters = @{ @"a" : @{@"b" : @YES} };
    [PFCloud callFunction:@"yolo" withParameters:parameters];

    OCMVerify([controllerMock callCloudCodeFunctionAsync:[OCMArg isEqual:@"yolo"]
                                          withParameters:[OCMArg isEqual:parameters]
                                            sessionToken:[OCMArg isNil]]);
}

///--------------------------------------
#pragma mark - Cancellation
///--------------------------------------

- (void)testCallFunctionWithNilCancellationToken {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:result error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo" withParameters:nil cancellationToken:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionViaBlockWithNilCancellationToken {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:result error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                    cancellationToken:nil
                                block:^(id cloudResult, NSError *error) {
        XCTAssertEqualObjects(cloudResult, result);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionWithCancellationTokenReturnsResult {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [self mockCloudCodeControllerWithTask:[BFTask taskWithResult:result] callHandler:nil];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo"
                        withParameters:nil
                     cancellationToken:cancellationTokenSource.token] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, result);
        XCTAssertFalse(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionWithCancellationTokenReturnsError {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [self mockCloudCodeControllerWithTask:[BFTask taskWithError:error] callHandler:nil];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo"
                        withParameters:nil
                     cancellationToken:cancellationTokenSource.token] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, error);
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionWithCancellationTokenReturnsCancelledRequest {
    [self mockCloudCodeControllerWithTask:[BFTask cancelledTask] callHandler:nil];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo"
                        withParameters:nil
                     cancellationToken:cancellationTokenSource.token] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionCancellationCancelsRequest {
    NSDictionary *parameters = @{ @"a" : @{@"b" : @YES} };
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    XCTestExpectation *requestExpectation = [self currentSelectorTestExpectation];
    __block BFCancellationToken *requestCancellationToken = nil;
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *requestParameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        XCTAssertEqualObjects(function, @"yolo");
        XCTAssertEqualObjects(requestParameters, parameters);
        XCTAssertNil(sessionToken);
        requestCancellationToken = cancellationToken;
        [requestExpectation fulfill];
    }];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];

    [PFCloud callFunctionInBackground:@"yolo" withParameters:parameters cancellationToken:cancellationTokenSource.token];
    [self waitForTestExpectations];
    XCTAssertNotNil(requestCancellationToken);
    XCTAssertFalse(requestCancellationToken.cancellationRequested);
    [cancellationTokenSource cancel];

    XCTAssertTrue(requestCancellationToken.cancellationRequested);
}

- (void)testCallFunctionWithCancelledTokenSendsNoRequest {
    // A completed session token task lets a request start synchronously
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    __block BOOL requested = NO;
    [self mockCloudCodeControllerWithTask:[BFTask taskWithResult:@"a"]
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        requested = YES;
    }];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    [cancellationTokenSource cancel];

    BFTask *task = [PFCloud callFunctionInBackground:@"yolo"
                                      withParameters:nil
                                   cancellationToken:cancellationTokenSource.token];

    XCTAssertTrue(task.cancelled);
    XCTAssertFalse(requested);
}

- (void)testCallFunctionCancelledWhileRunningIsCancelledWithoutResponse {
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"request"];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestExpectation fulfill];
    }];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    BFTask *task = [PFCloud callFunctionInBackground:@"yolo"
                                      withParameters:nil
                                   cancellationToken:cancellationTokenSource.token];
    [self waitForTestExpectations];

    [cancellationTokenSource cancel];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [task continueWithBlock:^id(BFTask *cancelledTask) {
        XCTAssertTrue(cancelledTask.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionCancelledOnMainThreadDoesNotCompleteTaskOnMainThread {
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"request"];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestExpectation fulfill];
    }];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    BFTask *task = [PFCloud callFunctionInBackground:@"yolo"
                                      withParameters:nil
                                   cancellationToken:cancellationTokenSource.token];
    [self waitForTestExpectations];

    // Continuations that run on the cancelling thread could deadlock or block it
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    __block BOOL completedOnMainThread = NO;
    [task continueWithBlock:^id(BFTask *cancelledTask) {
        completedOnMainThread = [NSThread isMainThread];
        [expectation fulfill];
        return nil;
    }];
    [cancellationTokenSource cancel];
    [self waitForTestExpectations];

    XCTAssertFalse(completedOnMainThread);
}

- (void)testCallFunctionCancellationCancelsAllCallsWithSameToken {
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    XCTestExpectation *requestsExpectation = [self expectationWithDescription:@"requests"];
    requestsExpectation.expectedFulfillmentCount = 2;
    NSMutableArray<BFCancellationToken *> *requestCancellationTokens = [NSMutableArray array];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        @synchronized(requestCancellationTokens) {
            [requestCancellationTokens addObject:cancellationToken];
        }
        [requestsExpectation fulfill];
    }];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    NSArray<BFTask *> *tasks = @[
        [PFCloud callFunctionInBackground:@"yolo" withParameters:nil cancellationToken:cancellationTokenSource.token],
        [PFCloud callFunctionInBackground:@"yolo" withParameters:nil cancellationToken:cancellationTokenSource.token]
    ];
    [self waitForTestExpectations];

    [cancellationTokenSource cancel];

    XCTAssertEqual(requestCancellationTokens.count, 2);
    for (BFCancellationToken *requestCancellationToken in requestCancellationTokens) {
        XCTAssertTrue(requestCancellationToken.cancellationRequested);
    }
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[BFTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id(BFTask *task) {
        for (BFTask *cancelledTask in tasks) {
            XCTAssertTrue(cancelledTask.cancelled);
        }
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCancellationTokenSourceUsedForManyCallsCanBeDisposed {
    [self mockCloudCodeControllerWithTask:[BFTask taskWithResult:@"a"] callHandler:nil];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    NSMutableArray<BFTask *> *tasks = [NSMutableArray array];
    // Bolts throws when disposing a token with more than 128 observers
    for (int i = 0; i < 200; i++) {
        [tasks addObject:[PFCloud callFunctionInBackground:@"yolo"
                                            withParameters:nil
                                         cancellationToken:cancellationTokenSource.token]];
    }
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[BFTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id(BFTask *task) {
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTAssertNoThrow([cancellationTokenSource dispose]);
}

- (void)testCallFunctionViaBlockWithCancellationToken {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [self mockCloudCodeControllerWithTask:[BFTask taskWithResult:result] callHandler:nil];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                    cancellationToken:cancellationTokenSource.token
                                block:^(id cloudResult, NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        XCTAssertEqualObjects(cloudResult, result);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionViaBlockCancelledWhileRunningDoesNotCallBlock {
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    XCTestExpectation *requestExpectation = [self currentSelectorTestExpectation];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestExpectation fulfill];
    }];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    __block BOOL blockCalled = NO;
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                    cancellationToken:cancellationTokenSource.token
                                block:^(id result, NSError *error) {
        blockCalled = YES;
    }];
    [self waitForTestExpectations];

    [cancellationTokenSource cancel];
    requestTaskCompletionSource.result = @"a";
    [self waitForMainQueue];

    XCTAssertFalse(blockCalled);
}

- (void)testCallFunctionViaBlockCancelledOnMainThreadBeforeBlockIsCalledDoesNotCallBlock {
    BFTaskCompletionSource *sessionTokenTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [self mockCurrentUserSessionTokenWithTask:sessionTokenTaskCompletionSource.task];
    [self mockCloudCodeControllerWithTask:[BFTask taskWithResult:@"a"] callHandler:nil];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    __block BOOL blockCalled = NO;
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                    cancellationToken:cancellationTokenSource.token
                                block:^(id result, NSError *error) {
        blockCalled = YES;
    }];

    // Complete the call on a background thread while the main thread waits, so that the block is queued on the main thread
    [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        sessionTokenTaskCompletionSource.result = nil;
        return nil;
    }] waitUntilFinished];
    [cancellationTokenSource cancel];
    [self waitForMainQueue];

    XCTAssertFalse(blockCalled);
}

- (void)testCallFunctionViaBlockCancelledOnMainThreadWhileAnotherThreadCancelsDoesNotCallBlock {
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task callHandler:nil];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    // Registered before the call, so that it holds up the other thread before the call is cancelled
    dispatch_semaphore_t otherThreadCancelling = dispatch_semaphore_create(0);
    dispatch_semaphore_t otherThreadResumed = dispatch_semaphore_create(0);
    [cancellationTokenSource.token registerCancellationObserverWithBlock:^{
        dispatch_semaphore_signal(otherThreadCancelling);
        dispatch_semaphore_wait(otherThreadResumed, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
    }];
    __block BOOL blockCalled = NO;
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                    cancellationToken:cancellationTokenSource.token
                                block:^(id result, NSError *error) {
        blockCalled = YES;
    }];

    // Complete the call on a background thread while the main thread waits, so that the block is queued on the main thread
    [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        requestTaskCompletionSource.result = @"a";
        return nil;
    }] waitUntilFinished];
    BFTask *otherThreadTask = [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        [cancellationTokenSource cancel];
        return nil;
    }];
    XCTAssertEqual(dispatch_semaphore_wait(otherThreadCancelling, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)), 0);
    // Returns at once, as the other thread has already requested cancellation
    [cancellationTokenSource cancel];
    [self waitForMainQueue];
    dispatch_semaphore_signal(otherThreadResumed);
    [otherThreadTask waitUntilFinished];

    XCTAssertFalse(blockCalled);
}

- (void)testCallFunctionViaBlockCancelledAndDisposedBeforeBlockIsCalledDoesNotCallBlock {
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task callHandler:nil];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    __block BOOL blockCalled = NO;
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                    cancellationToken:cancellationTokenSource.token
                                block:^(id result, NSError *error) {
        blockCalled = YES;
    }];

    // Complete the call on a background thread while the main thread waits, so that the block is queued on the main thread
    [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        requestTaskCompletionSource.result = @"a";
        return nil;
    }] waitUntilFinished];
    [cancellationTokenSource cancel];
    [cancellationTokenSource dispose];
    [self waitForMainQueue];

    XCTAssertFalse(blockCalled);
}

- (void)testCallFunctionViaBlockWithDisposedCancellationTokenSourceCallsBlock {
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task callHandler:nil];
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                    cancellationToken:cancellationTokenSource.token
                                block:^(id result, NSError *error) {
        XCTAssertEqualObjects(result, @"a");
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [cancellationTokenSource dispose];
    requestTaskCompletionSource.result = @"a";
    [self waitForTestExpectations];
}

@end
