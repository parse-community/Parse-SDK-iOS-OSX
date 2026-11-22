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
#import "PFCommandRunning.h"
#import "PFCoreManager.h"
#import "PFCurrentUserController.h"
#import "PFMockURLProtocol.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@protocol CloudCodeMockedObserver <NSObject>

- (void)callbackWithResult:(id)result error:(id)error;

@end

@interface CloudUnitTests : PFUnitTestCase

@end

@implementation CloudUnitTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    [Parse _currentManager].commandRunner.initialRetryDelay = 0.001;
}

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
    return [self cloudCodeControllerWithTask:task];
}

// Stubs the call without a cancellation token, which the class methods make
- (PFCloudCodeController *)cloudCodeControllerWithTask:(BFTask *)task {
    id controllerMock = PFClassMock([PFCloudCodeController class]);
    OCMStub([controllerMock callCloudCodeFunctionAsync:OCMOCK_ANY
                                        withParameters:OCMOCK_ANY
                                          sessionToken:OCMOCK_ANY]).andReturn(task);
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

- (void)mockRequestsForFunction:(NSString *)function withResponse:(PFMockURLResponseContructingBlock)constructingBlock {
    NSString *path = [@"/functions/" stringByAppendingString:function];
    [PFMockURLProtocol mockRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.HTTPMethod isEqualToString:@"POST"] && [request.URL.path hasSuffix:path];
    } withResponse:constructingBlock];
    [self addTeardownBlock:^{
        [PFMockURLProtocol removeAllMocking];
    }];
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

- (void)testCallFunctionPassesCurrentUserSessionToken {
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:@"r:yolo"]];
    id controllerMock = [self cloudCodeControllerWithResult:@"yarr" error:nil];
    [Parse _currentManager].coreManager.cloudCodeController = controllerMock;

    [[PFCloud callFunctionInBackground:@"yolo" withParameters:nil] waitUntilFinished];

    OCMVerify([controllerMock callCloudCodeFunctionAsync:OCMOCK_ANY
                                          withParameters:OCMOCK_ANY
                                            sessionToken:[OCMArg isEqual:@"r:yolo"]]);
}

- (void)testCallFunctionWithoutSessionTokenIfReadingItFails {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithError:error]];
    id controllerMock = [self cloudCodeControllerWithResult:@"yarr" error:nil];
    [Parse _currentManager].coreManager.cloudCodeController = controllerMock;

    BFTask *task = [PFCloud callFunctionInBackground:@"yolo" withParameters:nil];
    [task waitUntilFinished];

    XCTAssertEqualObjects(task.result, @"yarr");
    OCMVerify([controllerMock callCloudCodeFunctionAsync:[OCMArg isEqual:@"yolo"]
                                          withParameters:[OCMArg isNil]
                                            sessionToken:[OCMArg isNil]]);
}

- (void)testCallFunctionViaBlockPassesParameters {
    id controllerMock = [self cloudCodeControllerWithResult:@"yarr" error:nil];
    [Parse _currentManager].coreManager.cloudCodeController = controllerMock;

    NSDictionary *parameters = @{ @"a" : @1 };
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFCloud callFunctionInBackground:@"yolo" withParameters:parameters block:^(id result, NSError *error) {
        [expectation fulfill];
    }];
    [self waitForTestExpectations];

    OCMVerify([controllerMock callCloudCodeFunctionAsync:[OCMArg isEqual:@"yolo"]
                                          withParameters:[OCMArg isEqual:parameters]
                                            sessionToken:OCMOCK_ANY]);
}

- (void)testCallFunctionViaTargetSelectorPassesParameters {
    id controllerMock = [self cloudCodeControllerWithResult:@"yarr" error:nil];
    [Parse _currentManager].coreManager.cloudCodeController = controllerMock;
    id mock = PFProtocolMock(@protocol(CloudCodeMockedObserver));
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    OCMStub([mock callbackWithResult:OCMOCK_ANY error:OCMOCK_ANY]).andCall(expectation, @selector(fulfill));

    NSDictionary *parameters = @{ @"a" : @1 };
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:parameters
                               target:mock
                             selector:@selector(callbackWithResult:error:)];
#pragma clang diagnostic pop
    [self waitForTestExpectations];

    OCMVerify([controllerMock callCloudCodeFunctionAsync:[OCMArg isEqual:@"yolo"]
                                          withParameters:[OCMArg isEqual:parameters]
                                            sessionToken:OCMOCK_ANY]);
}

- (void)testCallFunctionViaBlockCallsBlockOnMainThread {
    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithTask:taskCompletionSource.task];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    // Calls and completes the function on a background thread, so that the block has to be dispatched to the main thread
    [[BFExecutor defaultPriorityBackgroundExecutor] execute:^{
        [PFCloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id result, NSError *error) {
            XCTAssertTrue([NSThread isMainThread]);
            XCTAssertEqualObjects(result, @"yarr");
            [expectation fulfill];
        }];
        taskCompletionSource.result = @"yarr";
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionViaTargetSelectorCallsTargetOnMainThread {
    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithTask:taskCompletionSource.task];
    id mock = PFProtocolMock(@protocol(CloudCodeMockedObserver));
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    OCMStub([mock callbackWithResult:[OCMArg isEqual:@"yarr"] error:[OCMArg isNil]]).andDo(^(NSInvocation *invocation) {
        XCTAssertTrue([NSThread isMainThread]);
        [expectation fulfill];
    });

    // Calls and completes the function on a background thread, so that the target has to be called on the main thread
    [[BFExecutor defaultPriorityBackgroundExecutor] execute:^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [PFCloud callFunctionInBackground:@"yolo"
                           withParameters:nil
                                   target:mock
                                 selector:@selector(callbackWithResult:error:)];
#pragma clang diagnostic pop
        taskCompletionSource.result = @"yarr";
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionViaBlockDoesNotCallBlockIfCancelled {
    // Reads the session token synchronously, so that the call has completed when the main queue is drained
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    id controllerMock = [self cloudCodeControllerWithTask:[BFTask cancelledTask]];
    [Parse _currentManager].coreManager.cloudCodeController = controllerMock;

    __block BOOL blockCalled = NO;
    [PFCloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id result, NSError *error) {
        blockCalled = YES;
    }];
    [self waitForMainQueue];

    OCMVerify([controllerMock callCloudCodeFunctionAsync:OCMOCK_ANY
                                          withParameters:OCMOCK_ANY
                                            sessionToken:OCMOCK_ANY]);
    XCTAssertFalse(blockCalled);
}

- (void)testCallFunctionViaBlockWithoutBlockCallsFunction {
    // Reads the session token synchronously, so that the call has been made when the method returns
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    id controllerMock = [self cloudCodeControllerWithResult:@"yarr" error:nil];
    [Parse _currentManager].coreManager.cloudCodeController = controllerMock;

    NSDictionary *parameters = @{ @"a" : @1 };
    [PFCloud callFunctionInBackground:@"yolo" withParameters:parameters block:nil];

    OCMVerify([controllerMock callCloudCodeFunctionAsync:[OCMArg isEqual:@"yolo"]
                                          withParameters:[OCMArg isEqual:parameters]
                                            sessionToken:[OCMArg isNil]]);
}

- (void)testCallFunctionRetriesFailedRequest {
    __block NSUInteger requestCount = 0;
    [self mockRequestsForFunction:@"yolo" withResponse:^PFMockURLResponse *(NSURLRequest *request) {
        requestCount++;
        if (requestCount == 1) {
            return [PFMockURLResponse responseWithString:@"{ \"error\": \"yarr\", \"code\": 1 }" statusCode:500 delay:0.0];
        }
        return [PFMockURLResponse responseWithString:@"{ \"result\": \"yolo\" }" statusCode:200 delay:0.0];
    }];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo" withParameters:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @"yolo");
        XCTAssertNil(task.error);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTAssertEqual(requestCount, 2);
}

- (void)testCallFunctionReturnsCloudCodeError {
    [self mockRequestsForFunction:@"yolo" withResponse:^PFMockURLResponse *(NSURLRequest *request) {
        return [PFMockURLResponse responseWithString:@"{ \"error\": \"yarr\", \"code\": 141 }" statusCode:400 delay:0.0];
    }];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo" withParameters:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        XCTAssertEqualObjects(task.error.domain, PFParseErrorDomain);
        XCTAssertEqual(task.error.code, kPFScriptError);
        XCTAssertEqualObjects(task.error.userInfo[@"error"], @"yarr");
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

///--------------------------------------
#pragma mark - Cancellation
///--------------------------------------

- (void)testInstanceCallFunctionReturnsResult {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [self mockCloudCodeControllerWithTask:[BFTask taskWithResult:result] callHandler:nil];
    PFCloud *cloud = [[PFCloud alloc] init];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[cloud callFunctionInBackground:@"yolo" withParameters:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, result);
        XCTAssertFalse(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testInstanceCallFunctionReturnsError {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [self mockCloudCodeControllerWithTask:[BFTask taskWithError:error] callHandler:nil];
    PFCloud *cloud = [[PFCloud alloc] init];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[cloud callFunctionInBackground:@"yolo" withParameters:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, error);
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testInstanceCallFunctionReturnsCancelledRequest {
    [self mockCloudCodeControllerWithTask:[BFTask cancelledTask] callHandler:nil];
    PFCloud *cloud = [[PFCloud alloc] init];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[cloud callFunctionInBackground:@"yolo" withParameters:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testInstanceCallFunctionViaBlock {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [self mockCloudCodeControllerWithTask:[BFTask taskWithResult:result] callHandler:nil];
    PFCloud *cloud = [[PFCloud alloc] init];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [cloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id cloudResult, NSError *error) {
        XCTAssertTrue([NSThread isMainThread]);
        XCTAssertEqualObjects(cloudResult, result);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testCancelCancelsRequest {
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
    PFCloud *cloud = [[PFCloud alloc] init];

    [cloud callFunctionInBackground:@"yolo" withParameters:parameters];
    [self waitForTestExpectations];
    XCTAssertNotNil(requestCancellationToken);
    XCTAssertFalse(requestCancellationToken.cancellationRequested);
    [cloud cancel];

    XCTAssertTrue(requestCancellationToken.cancellationRequested);
}

- (void)testCancelCancelsTaskWithoutWaitingForResponse {
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"request"];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestExpectation fulfill];
    }];
    PFCloud *cloud = [[PFCloud alloc] init];
    BFTask *task = [cloud callFunctionInBackground:@"yolo" withParameters:nil];
    [self waitForTestExpectations];

    [cloud cancel];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [task continueWithBlock:^id(BFTask *cancelledTask) {
        XCTAssertTrue(cancelledTask.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCancelOnMainThreadDoesNotCompleteTaskOnMainThread {
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    XCTestExpectation *requestExpectation = [self expectationWithDescription:@"request"];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestExpectation fulfill];
    }];
    PFCloud *cloud = [[PFCloud alloc] init];
    BFTask *task = [cloud callFunctionInBackground:@"yolo" withParameters:nil];
    [self waitForTestExpectations];

    // Continuations that run on the cancelling thread could deadlock or block it
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    __block BOOL completedOnMainThread = NO;
    [task continueWithBlock:^id(BFTask *cancelledTask) {
        completedOnMainThread = [NSThread isMainThread];
        [expectation fulfill];
        return nil;
    }];
    [cloud cancel];
    [self waitForTestExpectations];

    XCTAssertFalse(completedOnMainThread);
}

- (void)testCancelCancelsAllCallsOfInstance {
    // A completed session token task lets the requests start synchronously
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    NSMutableArray<BFCancellationToken *> *requestCancellationTokens = [NSMutableArray array];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestCancellationTokens addObject:cancellationToken];
    }];
    PFCloud *cloud = [[PFCloud alloc] init];
    NSArray<BFTask *> *tasks = @[
        [cloud callFunctionInBackground:@"yolo" withParameters:nil],
        [cloud callFunctionInBackground:@"yolo" withParameters:nil]
    ];
    XCTAssertEqual(requestCancellationTokens.count, 2);

    [cloud cancel];

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

- (void)testCancelDoesNotCancelCallsOfOtherInstances {
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    NSMutableArray<BFCancellationToken *> *requestCancellationTokens = [NSMutableArray array];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestCancellationTokens addObject:cancellationToken];
    }];
    PFCloud *cloud = [[PFCloud alloc] init];
    PFCloud *otherCloud = [[PFCloud alloc] init];
    [cloud callFunctionInBackground:@"yolo" withParameters:nil];
    [otherCloud callFunctionInBackground:@"yolo" withParameters:nil];
    XCTAssertEqual(requestCancellationTokens.count, 2);

    [cloud cancel];

    XCTAssertTrue(requestCancellationTokens.firstObject.cancellationRequested);
    XCTAssertFalse(requestCancellationTokens.lastObject.cancellationRequested);
}

- (void)testCancelDoesNotCancelLaterCalls {
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    NSMutableArray<BFCancellationToken *> *requestCancellationTokens = [NSMutableArray array];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestCancellationTokens addObject:cancellationToken];
    }];
    PFCloud *cloud = [[PFCloud alloc] init];
    [cloud callFunctionInBackground:@"yolo" withParameters:nil];

    [cloud cancel];
    [cloud callFunctionInBackground:@"yolo" withParameters:nil];

    XCTAssertEqual(requestCancellationTokens.count, 2);
    XCTAssertTrue(requestCancellationTokens.firstObject.cancellationRequested);
    XCTAssertFalse(requestCancellationTokens.lastObject.cancellationRequested);
}

- (void)testCancelDoesNotCancelCompletedCalls {
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    __block BFCancellationToken *requestCancellationToken = nil;
    [self mockCloudCodeControllerWithTask:[BFTask taskWithResult:@"a"]
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        requestCancellationToken = cancellationToken;
    }];
    PFCloud *cloud = [[PFCloud alloc] init];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [cloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id result, NSError *error) {
        [expectation fulfill];
    }];
    [self waitForTestExpectations];

    [cloud cancel];

    XCTAssertNotNil(requestCancellationToken);
    XCTAssertFalse(requestCancellationToken.cancellationRequested);
}

- (void)testCallFunctionOfReleasedInstanceCallsBlock {
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task callHandler:nil];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    __weak PFCloud *weakCloud = nil;
    @autoreleasepool {
        PFCloud *cloud = [[PFCloud alloc] init];
        weakCloud = cloud;
        [cloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id result, NSError *error) {
            XCTAssertEqualObjects(result, @"a");
            [expectation fulfill];
        }];
    }

    // Running calls don't keep the instance alive
    XCTAssertNil(weakCloud);
    requestTaskCompletionSource.result = @"a";
    [self waitForTestExpectations];
}

- (void)testCancelWhileRunningDoesNotCallBlock {
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    XCTestExpectation *requestExpectation = [self currentSelectorTestExpectation];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestExpectation fulfill];
    }];
    PFCloud *cloud = [[PFCloud alloc] init];
    __block BOOL blockCalled = NO;
    [cloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id result, NSError *error) {
        blockCalled = YES;
    }];
    [self waitForTestExpectations];

    [cloud cancel];
    requestTaskCompletionSource.result = @"a";
    [self waitForMainQueue];

    XCTAssertFalse(blockCalled);
}

- (void)testCancelOnMainThreadBeforeBlockIsCalledDoesNotCallBlock {
    BFTaskCompletionSource *sessionTokenTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [self mockCurrentUserSessionTokenWithTask:sessionTokenTaskCompletionSource.task];
    __block BOOL requested = NO;
    [self mockCloudCodeControllerWithTask:[BFTask taskWithResult:@"a"]
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        requested = YES;
    }];
    PFCloud *cloud = [[PFCloud alloc] init];
    __block BOOL blockCalled = NO;
    [cloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id result, NSError *error) {
        blockCalled = YES;
    }];

    // Complete the call on a background thread while the main thread waits, so that the block is queued on the main thread
    [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        sessionTokenTaskCompletionSource.result = nil;
        return nil;
    }] waitUntilFinished];
    XCTAssertTrue(requested);
    [cloud cancel];
    [self waitForMainQueue];

    XCTAssertFalse(blockCalled);
}

- (void)testCancelWhileAnotherThreadCancelsReturnsOnceAllCallsAreCancelled {
    [self mockCurrentUserSessionTokenWithTask:[BFTask taskWithResult:nil]];
    BFTaskCompletionSource *requestTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    NSMutableArray<BFCancellationToken *> *requestCancellationTokens = [NSMutableArray array];
    [self mockCloudCodeControllerWithTask:requestTaskCompletionSource.task
                              callHandler:^(NSString *function,
                                            NSDictionary *parameters,
                                            NSString *sessionToken,
                                            BFCancellationToken *cancellationToken) {
        [requestCancellationTokens addObject:cancellationToken];
    }];
    PFCloud *cloud = [[PFCloud alloc] init];
    [cloud callFunctionInBackground:@"yolo" withParameters:nil];
    [cloud callFunctionInBackground:@"yolo" withParameters:nil];
    XCTAssertEqual(requestCancellationTokens.count, 2);
    // Holds up the first cancel after it has cancelled one of the calls
    dispatch_semaphore_t firstCancelHeld = dispatch_semaphore_create(0);
    dispatch_semaphore_t firstCancelResumed = dispatch_semaphore_create(0);
    __block BOOL firstCancelWasHeld = NO;
    for (BFCancellationToken *requestCancellationToken in requestCancellationTokens) {
        [requestCancellationToken registerCancellationObserverWithBlock:^{
            BOOL holdUp = NO;
            @synchronized(requestCancellationTokens) {
                holdUp = !firstCancelWasHeld;
                firstCancelWasHeld = YES;
            }
            if (holdUp) {
                dispatch_semaphore_signal(firstCancelHeld);
                dispatch_semaphore_wait(firstCancelResumed, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
            }
        }];
    }

    BFTask *firstCancelTask = [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        [cloud cancel];
        return nil;
    }];
    XCTAssertEqual(dispatch_semaphore_wait(firstCancelHeld, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)), 0);
    dispatch_semaphore_t secondCancelStarted = dispatch_semaphore_create(0);
    dispatch_semaphore_t secondCancelReturned = dispatch_semaphore_create(0);
    __block BOOL allCallsCancelledWhenSecondCancelReturned = NO;
    BFTask *secondCancelTask = [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        dispatch_semaphore_signal(secondCancelStarted);
        [cloud cancel];
        allCallsCancelledWhenSecondCancelReturned = (requestCancellationTokens.firstObject.cancellationRequested &&
                                                     requestCancellationTokens.lastObject.cancellationRequested);
        dispatch_semaphore_signal(secondCancelReturned);
        return nil;
    }];
    XCTAssertEqual(dispatch_semaphore_wait(secondCancelStarted, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)), 0);
    // The second cancel doesn't return while the first is held up
    XCTAssertNotEqual(dispatch_semaphore_wait(secondCancelReturned, dispatch_time(DISPATCH_TIME_NOW, 200 * NSEC_PER_MSEC)), 0);
    dispatch_semaphore_signal(firstCancelResumed);
    [firstCancelTask waitUntilFinished];
    [secondCancelTask waitUntilFinished];

    XCTAssertTrue(allCallsCancelledWhenSecondCancelReturned);
}

@end
