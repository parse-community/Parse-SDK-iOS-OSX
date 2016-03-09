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

#import "PFCurrentInstallationController.h"
#import "PFInstallation.h"
#import "PFMacros.h"
#import "PFPushChannelsController.h"
#import "PFTestCase.h"

@interface PushChannelsControllerTests : PFTestCase

@end

@implementation PushChannelsControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFCurrentInstallationControllerProvider>)mockedDataSource {
    id<PFCurrentInstallationControllerProvider> dataSource = PFStrictProtocolMock(@protocol(PFCurrentInstallationControllerProvider));

    PFCurrentInstallationController *controller = PFStrictClassMock([PFCurrentInstallationController class]);
    OCMStub(dataSource.currentInstallationController).andReturn(controller);

    return dataSource;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id dataSource = [self mockedDataSource];

    PFPushChannelsController *controller = [[PFPushChannelsController alloc] initWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);

    controller = [PFPushChannelsController controllerWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);
}

- (void)testGetSubscribedChannels {
    id<PFCurrentInstallationControllerProvider> dataSource = [self mockedDataSource];
    PFCurrentInstallationController *installationController = dataSource.currentInstallationController;

    BFTask *emptyTask = [BFTask taskWithResult:nil];

    PFInstallation *installation = PFStrictClassMock([PFInstallation class]);
    OCMStub(installation.objectId).andReturn(@"yarr");
    OCMStub(installation.deviceToken).andReturn(@"yolo");
    [OCMStub(installation.channels) andReturn:@[ @"a", @"a", @"b" ]];
    OCMStub([installation fetchInBackground]).andReturn(emptyTask);

    BFTask *task = [BFTask taskWithResult:installation];
    OCMStub([installationController getCurrentObjectAsync]).andReturn(task);

    PFPushChannelsController *controller = [PFPushChannelsController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller getSubscribedChannelsAsync] continueWithSuccessBlock:^id(BFTask *task) {
        NSSet *result = task.result;
        XCTAssertNotNil(result);
        XCTAssertEqualObjects(result, (PF_SET(@"a", @"b")));

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testGetSubscribedChannelsWithUnsavedInstallation {
    id<PFCurrentInstallationControllerProvider> dataSource = [self mockedDataSource];
    PFCurrentInstallationController *installationController = dataSource.currentInstallationController;

    BFTask *emptyTask = [BFTask taskWithResult:nil];

    PFInstallation *installation = PFStrictClassMock([PFInstallation class]);
    OCMStub(installation.objectId).andReturn(nil);
    OCMStub(installation.deviceToken).andReturn(@"yolo");
    [OCMStub(installation.channels) andReturn:@[ @"a", @"a", @"b" ]];
    OCMStub([installation saveInBackground]).andReturn(emptyTask);

    BFTask *task = [BFTask taskWithResult:installation];
    OCMStub([installationController getCurrentObjectAsync]).andReturn(task);

    PFPushChannelsController *controller = [PFPushChannelsController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller getSubscribedChannelsAsync] continueWithSuccessBlock:^id(BFTask *task) {
        NSSet *result = task.result;
        XCTAssertNotNil(result);
        XCTAssertEqualObjects(result, (PF_SET(@"a", @"b")));

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testGetSubscribedChannelsNoDeviceToken {
    id<PFCurrentInstallationControllerProvider> dataSource = [self mockedDataSource];
    PFCurrentInstallationController *installationController = dataSource.currentInstallationController;

    PFInstallation *installation = PFStrictClassMock([PFInstallation class]);
    OCMStub(installation.objectId).andReturn(@"yarr");
    OCMStub(installation.deviceToken).andReturn(nil);

    BFTask *task = [BFTask taskWithResult:installation];
    OCMStub([installationController getCurrentObjectAsync]).andReturn(task);

    PFPushChannelsController *controller = [PFPushChannelsController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller getSubscribedChannelsAsync] continueWithBlock:^id(BFTask *task) {
        NSError *error = task.error;
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
        XCTAssertEqual(error.code, kPFErrorPushMisconfigured);

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testSubscribeToChannel {
    id<PFCurrentInstallationControllerProvider> dataSource = [self mockedDataSource];
    PFCurrentInstallationController *installationController = dataSource.currentInstallationController;

    BFTask *emptyTask = [BFTask taskWithResult:@YES];

    PFInstallation *installation = PFStrictClassMock([PFInstallation class]);
    OCMStub(installation.objectId).andReturn(@"yarr");
    OCMStub(installation.deviceToken).andReturn(@"yolo");
    [OCMStub(installation.channels) andReturn:@[ @"a", @"a", @"b" ]];
    OCMStub([installation isDirtyForKey:@"channels"]).andReturn(NO);
    OCMExpect([installation addUniqueObject:@"c" forKey:@"channels"]);
    OCMStub([installation saveInBackground]).andReturn(emptyTask);

    BFTask *task = [BFTask taskWithResult:installation];
    OCMStub([installationController getCurrentObjectAsync]).andReturn(task);

    PFPushChannelsController *controller = [PFPushChannelsController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller subscribeToChannelAsyncWithName:@"c"] continueWithSuccessBlock:^id(BFTask *task) {
        NSNumber *result = task.result;
        XCTAssertNotNil(result);
        XCTAssertEqualObjects(result, @YES);

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll((id)installation);
}

- (void)testSubscribeToExistingChannel {
    id<PFCurrentInstallationControllerProvider> dataSource = [self mockedDataSource];
    PFCurrentInstallationController *installationController = dataSource.currentInstallationController;

    PFInstallation *installation = PFStrictClassMock([PFInstallation class]);
    OCMStub(installation.objectId).andReturn(@"yarr");
    OCMStub(installation.deviceToken).andReturn(@"yolo");
    [OCMStub(installation.channels) andReturn:@[ @"a", @"a", @"b" ]];
    OCMStub([installation isDirtyForKey:@"channels"]).andReturn(NO);

    BFTask *task = [BFTask taskWithResult:installation];
    OCMStub([installationController getCurrentObjectAsync]).andReturn(task);

    PFPushChannelsController *controller = [PFPushChannelsController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller subscribeToChannelAsyncWithName:@"a"] continueWithSuccessBlock:^id(BFTask *task) {
        NSNumber *result = task.result;
        XCTAssertNotNil(result);
        XCTAssertEqualObjects(result, @YES);

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testUnsubscribeFromChannel {
    id<PFCurrentInstallationControllerProvider> dataSource = [self mockedDataSource];
    PFCurrentInstallationController *installationController = dataSource.currentInstallationController;

    BFTask *emptyTask = [BFTask taskWithResult:@YES];

    PFInstallation *installation = PFStrictClassMock([PFInstallation class]);
    OCMStub(installation.deviceToken).andReturn(@"yolo");
    [OCMStub(installation.channels) andReturn:@[ @"a", @"a", @"b" ]];
    OCMExpect([installation removeObject:@"a" forKey:@"channels"]);
    OCMStub([installation saveInBackground]).andReturn(emptyTask);

    BFTask *task = [BFTask taskWithResult:installation];
    OCMStub([installationController getCurrentObjectAsync]).andReturn(task);

    PFPushChannelsController *controller = [PFPushChannelsController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller unsubscribeFromChannelAsyncWithName:@"a"] continueWithSuccessBlock:^id(BFTask *task) {
        NSNumber *result = task.result;
        XCTAssertNotNil(result);
        XCTAssertEqualObjects(result, @YES);

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll((id)installation);
}

- (void)testUnsubscribeFromNotSubscribedChannel {
    id<PFCurrentInstallationControllerProvider> dataSource = [self mockedDataSource];
    PFCurrentInstallationController *installationController = dataSource.currentInstallationController;

    BFTask *emptyTask = [BFTask taskWithResult:@YES];

    PFInstallation *installation = PFStrictClassMock([PFInstallation class]);
    OCMStub(installation.deviceToken).andReturn(@"yolo");
    [OCMStub(installation.channels) andReturn:@[ @"a", @"a", @"b" ]];
    OCMStub([installation isDirtyForKey:@"channels"]).andReturn(NO);
    OCMStub([installation saveInBackground]).andReturn(emptyTask);

    BFTask *task = [BFTask taskWithResult:installation];
    OCMStub([installationController getCurrentObjectAsync]).andReturn(task);

    PFPushChannelsController *controller = [PFPushChannelsController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller unsubscribeFromChannelAsyncWithName:@"c"] continueWithSuccessBlock:^id(BFTask *task) {
        NSNumber *result = task.result;
        XCTAssertNotNil(result);
        XCTAssertEqualObjects(result, @YES);

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

@end
