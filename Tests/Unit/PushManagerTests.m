/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFCommandRunning.h"
#import "PFCurrentInstallationController.h"
#import "PFPushChannelsController.h"
#import "PFPushController.h"
#import "PFPushManager.h"
#import "PFTestCase.h"

@interface PushManagerTests : PFTestCase

@end

@implementation PushManagerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFCommandRunnerProvider>)mockedCommonDataSource {
    id<PFCommandRunnerProvider> dataSource = PFStrictProtocolMock(@protocol(PFCommandRunnerProvider));
    id commandRunnerMock = PFStrictProtocolMock(@protocol(PFCommandRunning));
    OCMStub(dataSource.commandRunner).andReturn(commandRunnerMock);
    return dataSource;
}

- (id<PFCurrentInstallationControllerProvider>)mockedCoreDataSource {
    id<PFCurrentInstallationControllerProvider> dataSource = PFProtocolMock(@protocol(PFCurrentInstallationControllerProvider));
    id installationControllerMock = PFClassMock([PFCurrentInstallationController class]);
    OCMStub(dataSource.currentInstallationController).andReturn(installationControllerMock);
    return dataSource;
}

- (PFPushManager *)samplePushManager {
    id<PFCommandRunnerProvider> commonDataSource = [self mockedCommonDataSource];
    id<PFCurrentInstallationControllerProvider> coreDataSource = [self mockedCoreDataSource];
    return [PFPushManager managerWithCommonDataSource:commonDataSource coreDataSource:coreDataSource];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id<PFCommandRunnerProvider> commonDataSource = [self mockedCommonDataSource];
    id<PFCurrentInstallationControllerProvider> coreDataSource = [self mockedCoreDataSource];

    PFPushManager *manager = [[PFPushManager alloc] initWithCommonDataSource:commonDataSource
                                                              coreDataSource:coreDataSource];
    XCTAssertNotNil(manager);
    XCTAssertEqual((id)manager.commonDataSource, commonDataSource);
    XCTAssertEqual((id)manager.coreDataSource, coreDataSource);

    manager = [PFPushManager managerWithCommonDataSource:commonDataSource
                                          coreDataSource:coreDataSource];
    XCTAssertNotNil(manager);
    XCTAssertEqual((id)manager.commonDataSource, commonDataSource);
    XCTAssertEqual((id)manager.coreDataSource, coreDataSource);
}

- (void)testPushController {
    PFPushManager *manager = [self samplePushManager];
    XCTAssertNotNil(manager.pushController);

    PFPushController *controller = [PFPushController controllerWithCommandRunner:manager.commonDataSource.commandRunner];
    manager.pushController = controller;
    XCTAssertEqual(manager.pushController, controller);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    manager.pushController = nil;
    XCTAssertNotNil(manager.pushController); // The method reloads push controller if not available
#pragma clang diagnostic pop
}

- (void)testChannelsController {
    PFPushManager *manager = [self samplePushManager];
    XCTAssertNotNil(manager.pushController);

    PFPushChannelsController *controller = [PFPushChannelsController controllerWithDataSource:manager.coreDataSource];
    manager.channelsController = controller;
    XCTAssertEqual(manager.channelsController, controller);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    manager.channelsController = nil;
    XCTAssertNotNil(manager.channelsController); // The method reloads channels controller if not available
#pragma clang diagnostic pop
}

@end
