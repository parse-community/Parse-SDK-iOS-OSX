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
#import "OCMock+Parse.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFObjectPrivate.h"
#import "PFRESTCommand.h"
#import "PFSessionController.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface SessionControllerTests : PFUnitTestCase

@end

@implementation SessionControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFCommandRunnerProvider>)controllerDataSourceWithCommandResult:(PFCommandResult *)result error:(NSError *)error {
    id providerMock = PFProtocolMock(@protocol(PFCommandRunnerProvider));

    BFTask *task = nil;
    if (error) {
        task = [BFTask taskWithError:error];
    } else {
        task = [BFTask taskWithResult:result];
    }

    id runnerMock = PFStrictProtocolMock(@protocol(PFCommandRunning));
    OCMStub([[runnerMock ignoringNonObjectArgs] runCommandAsync:OCMOCK_ANY
                                                    withOptions:0]).andReturn(task);

    OCMStub([providerMock commandRunner]).andReturn(runnerMock);
    return providerMock;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id providerMock = [self controllerDataSourceWithCommandResult:nil error:nil];

    PFSessionController *controller = [[PFSessionController alloc] initWithDataSource:providerMock];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, providerMock);

    controller = [PFSessionController controllerWithDataSource:providerMock];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, providerMock);
}

- (void)testGetSessionParameters {
    id providerMock = [self controllerDataSourceWithCommandResult:nil error:nil];

    PFSessionController *controller = [PFSessionController controllerWithDataSource:providerMock];
    [[controller getCurrentSessionAsyncWithSessionToken:@"yolo"] waitUntilFinished];

    OCMVerify([[[providerMock ignoringNonObjectArgs] commandRunner] runCommandAsync:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertNotEqual([command.httpPath rangeOfString:@"sessions/me"].location, NSNotFound);
        XCTAssertEqualObjects(command.sessionToken, @"yolo");
        XCTAssertNil(command.parameters);

        return YES;
    }]
                                                                        withOptions:0
                                                                  cancellationToken:[OCMArg checkWithBlock:^BOOL(id obj) {
        XCTAssertNil(obj);
        return YES;
    }]]);
}

- (void)testGetSessionResult {
    PFCommandResult *result = [PFCommandResult commandResultWithResult:@{ @"objectId" : @"something",
                                                                          @"a" : @"El Capitan" }
                                                          resultString:nil
                                                          httpResponse:nil];
    id providerMock = [self controllerDataSourceWithCommandResult:result error:nil];

    PFSessionController *controller = [PFSessionController controllerWithDataSource:providerMock];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller getCurrentSessionAsyncWithSessionToken:@"yolo"] continueWithSuccessBlock:^id(BFTask *task) {
        PFSession *session = task.result;
        XCTAssertNotNil(session);
        PFAssertIsKindOfClass(session, [PFSession class]);
        XCTAssertNotNil(session.objectId);
        XCTAssertEqualObjects(session[@"a"], @"El Capitan");

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testGetSessionError {
    NSError *error = [NSError errorWithDomain:@"TestErrorDomain" code:100500 userInfo:nil];
    id providerMock = [self controllerDataSourceWithCommandResult:nil error:error];

    PFSessionController *controller = [PFSessionController controllerWithDataSource:providerMock];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller getCurrentSessionAsyncWithSessionToken:@"yolo"] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

@end
