/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Bolts.BFTask;

#import "OCMock+Parse.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFCurrentUserController.h"
#import "PFHTTPRequest.h"
#import "PFObjectControlling.h"
#import "PFRESTUserCommand.h"
#import "PFUnitTestCase.h"
#import "PFUser.h"
#import "PFUserController.h"

@interface UserControllerTests : PFUnitTestCase

@end

@implementation UserControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id)mockedCommonDataSource {
    id dataSource = PFStrictProtocolMock(@protocol(PFCommandRunnerProvider));
    id commandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    OCMStub([dataSource commandRunner]).andReturn(commandRunner);
    return dataSource;
}

- (id)mockedCoreDataSource {
    id dataSource = PFStrictProtocolMock(@protocol(PFCurrentUserControllerProvider));
    id currentUserController = PFStrictClassMock([PFCurrentUserController class]);
    OCMStub([dataSource currentUserController]).andReturn(currentUserController);
    return dataSource;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id commonDataSource = [self mockedCommonDataSource];
    id coreDataSource = [self mockedCoreDataSource];

    PFUserController *controller = [[PFUserController alloc] initWithCommonDataSource:commonDataSource
                                                                       coreDataSource:coreDataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.commonDataSource, commonDataSource);
    XCTAssertEqual((id)controller.coreDataSource, coreDataSource);

    controller = [PFUserController controllerWithCommonDataSource:commonDataSource coreDataSource:coreDataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.commonDataSource, commonDataSource);
    XCTAssertEqual((id)controller.coreDataSource, coreDataSource);
}

- (void)testLogInCurrentUserWithSessionToken {
    id commonDataSource = [self mockedCommonDataSource];
    id coreDataSource = [self mockedCoreDataSource];
    id commandRunner = [commonDataSource commandRunner];

    id commandResult = @{ @"objectId" : @"a",
                          @"yarr" : @1 };
    [commandRunner mockCommandResult:commandResult forCommandsPassingTest:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
        XCTAssertNotEqual([command.httpPath rangeOfString:@"users/me"].location, NSNotFound);
        XCTAssertEqualObjects(command.sessionToken, @"yarr");
        XCTAssertNil(command.parameters);

        return YES;
    }];

    __block PFUser *savedUser = nil;

    id currentUserController = [coreDataSource currentUserController];
    [OCMExpect([currentUserController saveCurrentObjectAsync:[OCMArg checkWithBlock:^BOOL(id obj) {
        savedUser = obj;
        return (savedUser != nil);
    }]]) andReturn:[BFTask taskWithResult:nil]];

    PFUserController *controller = [PFUserController controllerWithCommonDataSource:commonDataSource
                                                                     coreDataSource:coreDataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller logInCurrentUserAsyncWithSessionToken:@"yarr"] continueWithBlock:^id(BFTask *task) {
        PFUser *user = task.result;
        XCTAssertNotNil(user);
        XCTAssertEqualObjects(user.objectId, @"a");
        XCTAssertEqualObjects(user[@"yarr"], @1);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(currentUserController);
}

- (void)testLogInCurrentUserWithSessionTokenNullResult {
    id commonDataSource = [self mockedCommonDataSource];
    id coreDataSource = [self mockedCoreDataSource];
    id commandRunner = [commonDataSource commandRunner];
    [commandRunner mockCommandResult:[NSNull null] forCommandsPassingTest:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
        XCTAssertNotEqual([command.httpPath rangeOfString:@"users/me"].location, NSNotFound);
        XCTAssertEqualObjects(command.sessionToken, @"yarr");
        XCTAssertNil(command.parameters);

        return YES;
    }];

    PFUserController *controller = [PFUserController controllerWithCommonDataSource:commonDataSource
                                                                     coreDataSource:coreDataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller logInCurrentUserAsyncWithSessionToken:@"yarr"] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.faulted);
        NSError *error = task.error;
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
        XCTAssertEqual(error.code, kPFErrorObjectNotFound);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testLogInCurrentUserWithUsernamePassword {
    id commonDataSource = [self mockedCommonDataSource];
    id coreDataSource = [self mockedCoreDataSource];
    id commandRunner = [commonDataSource commandRunner];

    id commandResult = @{ @"objectId" : @"a",
                          @"yarr" : @1 };
    [commandRunner mockCommandResult:commandResult forCommandsPassingTest:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
        XCTAssertNotEqual([command.httpPath rangeOfString:@"login"].location, NSNotFound);
        XCTAssertNil(command.sessionToken);
        XCTAssertEqualObjects(command.parameters, (@{ @"username" : @"yolo" , @"password" : @"yarr" }));
        XCTAssertEqualObjects(command.additionalRequestHeaders, @{ @"X-Parse-Revocable-Session" : @"1" });

        return YES;
    }];

    __block PFUser *savedUser = nil;

    id currentUserController = [coreDataSource currentUserController];
    [OCMExpect([currentUserController saveCurrentObjectAsync:[OCMArg checkWithBlock:^BOOL(id obj) {
        savedUser = obj;
        return (savedUser != nil);
    }]]) andReturn:[BFTask taskWithResult:nil]];

    PFUserController *controller = [PFUserController controllerWithCommonDataSource:commonDataSource
                                                                     coreDataSource:coreDataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller logInCurrentUserAsyncWithUsername:@"yolo"
                                          password:@"yarr"
                                  revocableSession:YES] continueWithBlock:^id(BFTask *task) {
        PFUser *user = task.result;
        XCTAssertNotNil(user);
        XCTAssertEqualObjects(user.objectId, @"a");
        XCTAssertEqualObjects(user[@"yarr"], @1);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(currentUserController);
}

- (void)testLogInCurrentUserWithUsernamePasswordNullResult {
    id commonDataSource = [self mockedCommonDataSource];
    id coreDataSource = [self mockedCoreDataSource];
    id commandRunner = [commonDataSource commandRunner];
    [commandRunner mockCommandResult:[NSNull null] forCommandsPassingTest:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
        XCTAssertNotEqual([command.httpPath rangeOfString:@"login"].location, NSNotFound);
        XCTAssertNil(command.sessionToken);
        XCTAssertEqualObjects(command.parameters, (@{ @"username" : @"yolo" , @"password" : @"yarr" }));

        return YES;
    }];

    PFUserController *controller = [PFUserController controllerWithCommonDataSource:commonDataSource
                                                                     coreDataSource:coreDataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller logInCurrentUserAsyncWithUsername:@"yolo"
                                          password:@"yarr"
                                  revocableSession:NO] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.faulted);
        NSError *error = task.error;
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
        XCTAssertEqual(error.code, kPFErrorObjectNotFound);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(commandRunner);
}

- (void)testRequestPasswordReset {
    id commonDataSource = [self mockedCommonDataSource];
    id coreDataSource = [self mockedCoreDataSource];
    id commandRunner = [commonDataSource commandRunner];
    [commandRunner mockCommandResult:@{ @"a" : @"b" } forCommandsPassingTest:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
        XCTAssertNotEqual([command.httpPath rangeOfString:@"requestPasswordReset"].location, NSNotFound);
        XCTAssertNil(command.sessionToken);
        XCTAssertEqualObjects(command.parameters[@"email"], @"yarr@yolo.com");

        return YES;
    }];

    PFUserController *controller = [PFUserController controllerWithCommonDataSource:commonDataSource
                                                                     coreDataSource:coreDataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller requestPasswordResetAsyncForEmail:@"yarr@yolo.com"] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        XCTAssertFalse(task.cancelled);
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(commandRunner);
}

- (void)testLogOutAsync {
    id commonDataSource = [self mockedCommonDataSource];
    id coreDataSource = [self mockedCoreDataSource];
    id commandRunner = [commonDataSource commandRunner];
    [commandRunner mockCommandResult:@{ @"a" : @"b" } forCommandsPassingTest:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
        XCTAssertNotEqual([command.httpPath rangeOfString:@"logout"].location, NSNotFound);
        XCTAssertEqualObjects(command.sessionToken, @"yolo");

        return YES;
    }];

    PFUserController *controller = [PFUserController controllerWithCommonDataSource:commonDataSource
                                                                     coreDataSource:coreDataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller logOutUserAsyncWithSessionToken:@"yolo"] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        XCTAssertFalse(task.cancelled);
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(commandRunner);
}

@end
