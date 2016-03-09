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
    id dataSource = PFStrictProtocolMock(@protocol(PFCommandRunnerProvider));

    PFCloudCodeController *controller = [[PFCloudCodeController alloc] initWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual(controller.dataSource, dataSource);

    controller = [PFCloudCodeController controllerWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual(controller.dataSource, dataSource);
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
    id dataSource = PFStrictProtocolMock(@protocol(PFCommandRunnerProvider));
    OCMStub([dataSource commandRunner]).andReturn(runner);

    PFCloudCodeController *controller = [[PFCloudCodeController alloc] initWithDataSource:dataSource];
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
    id dataSource = PFStrictProtocolMock(@protocol(PFCommandRunnerProvider));
    OCMStub([dataSource commandRunner]).andReturn(runner);

    PFCloudCodeController *controller = [PFCloudCodeController controllerWithDataSource:dataSource];

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
    id dataSource = PFStrictProtocolMock(@protocol(PFCommandRunnerProvider));
    OCMStub([dataSource commandRunner]).andReturn(runner);

    PFCloudCodeController *controller = [PFCloudCodeController controllerWithDataSource:dataSource];

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
