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

#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFMacros.h"
#import "PFMutablePushState.h"
#import "PFPushController.h"
#import "PFRESTPushCommand.h"
#import "PFTestCase.h"

@interface PushControllerTests : PFTestCase

@end

@implementation PushControllerTests

- (void)testConstructor {
    id commandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));

    PFPushController *pushController = [[PFPushController alloc] initWithCommandRunner:commandRunner];
    XCTAssertNotNil(pushController);
    XCTAssertEqual(pushController.commandRunner, commandRunner);

    pushController = [PFPushController controllerWithCommandRunner:commandRunner];
    XCTAssertNotNil(pushController);
    XCTAssertEqual(pushController.commandRunner, commandRunner);
}

- (void)testSendPushNotificationAsync {
    id commandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    PFPushController *pushController = [[PFPushController alloc] initWithCommandRunner:commandRunner];

    PFMutablePushState *pushState = [[PFMutablePushState alloc] init];
    pushState.payload = @{ @"theKey": @"theValue" };

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    PFCommandResult *result = [[PFCommandResult alloc] initWithResult:@{ }
                                                         resultString:nil
                                                         httpResponse:nil];
    BFTask *mockedTask = [BFTask taskWithResult:result];


    OCMStub([[commandRunner ignoringNonObjectArgs] runCommandAsync:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFAssertIsKindOfClass(obj, PFRESTPushCommand);

        PFRESTPushCommand *command = obj;
        XCTAssertEqualObjects(command.httpPath, @"push");
        XCTAssertEqualObjects(command.httpMethod, @"POST");
        XCTAssertEqualObjects(command.parameters[@"data"], pushState.payload);

        return YES;
    }] withOptions:0]).andReturn(mockedTask);

    [[pushController sendPushNotificationAsyncWithState:pushState
                                           sessionToken:@"token"] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

@end
