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

#import "OCMock+Parse.h"
#import "PFCloudCodeController.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFRESTCommand.h"
#import "PFTestCase.h"

@interface CloudCodeControllerTests : PFTestCase

@end

@implementation CloudCodeControllerTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id runnerMock = PFStrictProtocolMock(@protocol(PFCommandRunning));

    PFCloudCodeController *controller = [[PFCloudCodeController alloc] initWithCommandRunner:runnerMock];
    XCTAssertNotNil(controller);
    XCTAssertEqual(controller.commandRunner, runnerMock);

    controller = [PFCloudCodeController controllerWithCommandRunner:runnerMock];
    XCTAssertNotNil(controller);
    XCTAssertEqual(controller.commandRunner, runnerMock);
}

- (void)testCallCloudFunctionParameters {
    id runner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    [runner mockCommandResult:nil forCommandsPassingTest:^BOOL(id obj) {
        PFRESTCommand *command = obj;

        XCTAssertNotEqual([command.httpPath rangeOfString:@"yarr"].location, NSNotFound);
        XCTAssertEqualObjects(command.sessionToken, @"yolo");
        XCTAssertEqualObjects(command.parameters[@"a"], @1);

        return YES;
    }];

    PFCloudCodeController *controller = [[PFCloudCodeController alloc] initWithCommandRunner:runner];
    [[controller callCloudCodeFunctionAsync:@"yarr"
                             withParameters:@{ @"a" : @1 }
                               sessionToken:@"yolo"] waitUntilFinished];

    OCMVerifyAll(runner);
}

- (void)testCallCloudFunctionNilResult {
    id runner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    [runner mockCommandResult:nil forCommandsPassingTest:^BOOL(id obj) {
        return obj != nil;
    }];

    PFCloudCodeController *controller = [[PFCloudCodeController alloc] initWithCommandRunner:runner];

    XCTestExpectation *nilResultExpectation = [self currentSelectorTestExpectation];
    [[controller callCloudCodeFunctionAsync:@"a"
                             withParameters:nil
                               sessionToken:@"c"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [nilResultExpectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallCloudFunctionResult {
    id runner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    [runner mockCommandResult:@{ @"result" : @"yarr" } forCommandsPassingTest:^BOOL(id obj) {
        return YES;
    }];
    PFCloudCodeController *controller = [[PFCloudCodeController alloc] initWithCommandRunner:runner];

    XCTestExpectation *resultExpectation = [self expectationWithDescription:@"proper result"];
    [[controller callCloudCodeFunctionAsync:@"a"
                             withParameters:nil
                               sessionToken:@"b"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.result);
        XCTAssertEqualObjects(task.result, @"yarr");
        [resultExpectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

@end
