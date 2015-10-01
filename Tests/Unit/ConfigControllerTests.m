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
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFConfig.h"
#import "PFConfigController.h"
#import "PFFileManager.h"
#import "PFTestCase.h"

@interface ConfigControllerTests : PFTestCase

@end

@implementation ConfigControllerTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructor {
    id mockedFileManager = PFClassMock([PFFileManager class]);
    id mockedCommandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));

    PFConfigController *controller = [[PFConfigController alloc] initWithFileManager:mockedFileManager
                                                                       commandRunner:mockedCommandRunner];

    XCTAssertNotNil(controller);
    XCTAssertEqual(mockedFileManager, controller.fileManager);
    XCTAssertEqual(mockedCommandRunner, controller.commandRunner);
}

- (void)testCurrentConfigController {
    id fileManager = PFClassMock([PFFileManager class]);
    id commandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));

    PFConfigController *configController = [[PFConfigController alloc] initWithFileManager:fileManager
                                                                             commandRunner:commandRunner];

    XCTAssertNotNil([configController currentConfigController]);
}

- (void)testFetch {
    id fileManager = PFClassMock([PFFileManager class]);;

    id commandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    [commandRunner mockCommandResult:@{ @"params" : @{@"testKey" : @"testValue"} }
              forCommandsPassingTest:^BOOL(id obj) {
                  return YES;
              }];

    PFConfigController *configController = [[PFConfigController alloc] initWithFileManager:fileManager
                                                                             commandRunner:commandRunner];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[configController fetchConfigAsyncWithSessionToken:@"token"] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.result);

        XCTAssertTrue([task.result isKindOfClass:[PFConfig class]]);
        XCTAssertEqualObjects(task.result[@"testKey"], @"testValue");

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

@end
