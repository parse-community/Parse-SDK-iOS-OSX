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

#import "BFTask+Private.h"
#import "PFCommandResult.h"
#import "PFConfig.h"
#import "PFConfig_Private.h"
#import "PFCurrentConfigController.h"
#import "PFPersistenceController.h"
#import "PFTestCase.h"
#import "PFJSONSerialization.h"

@interface CurrentConfigControllerTests : PFTestCase

@end

@implementation CurrentConfigControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (NSDictionary *)testConfigDictionary {
    return @{ @"params" : @{@"testKey" : @"testValue"} };
}

- (PFPersistenceController *)mockedPersistenceController {
    id controller = PFStrictClassMock([PFPersistenceController class]);
    id group = PFStrictProtocolMock(@protocol(PFPersistenceGroup));
    OCMStub([controller getPersistenceGroupAsync]).andReturn([BFTask taskWithResult:group]);
    return controller;
}

- (PFPersistenceController *)mockedPersistenceControllerWithConfigDictionary:(NSDictionary *)dictionary {
    id controller = [self mockedPersistenceController];
    id group = [[controller getPersistenceGroupAsync] waitForResult:nil];
    NSData *jsonData = [PFJSONSerialization dataFromJSONObject:dictionary];
    BFTask *task = [BFTask taskWithResult:jsonData];
    OCMStub([group getDataAsyncForKey:@"config"]).andReturn(task);
    return controller;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructor {
    id dataSource = PFStrictProtocolMock(@protocol(PFPersistenceControllerProvider));

    PFCurrentConfigController *controller = [[PFCurrentConfigController alloc] initWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);

    controller = [PFCurrentConfigController controllerWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);
}

- (void)testGetCurrentConfig {
    id dataSource = PFStrictProtocolMock(@protocol(PFPersistenceControllerProvider));
    PFPersistenceController *controller = [self mockedPersistenceControllerWithConfigDictionary:[self testConfigDictionary]];
    OCMStub([dataSource persistenceController]).andReturn(controller);

    PFCurrentConfigController *currentController = [PFCurrentConfigController controllerWithDataSource:dataSource];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[currentController getCurrentConfigAsync] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.result);
        XCTAssertTrue([task.result isKindOfClass:[PFConfig class]]);
        XCTAssertEqualObjects(task.result[@"testKey"], @"testValue");

        [expectation fulfill];
        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testSetCurrentConfig {
    id dataSource = PFStrictProtocolMock(@protocol(PFPersistenceControllerProvider));
    PFPersistenceController *controller = [self mockedPersistenceController];
    OCMStub([dataSource persistenceController]).andReturn(controller);

    PFConfig *testConfig = [[PFConfig alloc] initWithFetchedConfig:[self testConfigDictionary]];
    PFCurrentConfigController *currentController = [PFCurrentConfigController controllerWithDataSource:dataSource];

    id group = [[controller getPersistenceGroupAsync] waitForResult:nil];
    OCMExpect([group setDataAsync:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSDictionary *dictionary = [PFJSONSerialization JSONObjectFromData:obj];
        return [dictionary isEqual:[self testConfigDictionary]];
    }] forKey:@"config"]).andReturn([BFTask taskWithResult:nil]);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[currentController setCurrentConfigAsync:testConfig] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [expectation fulfill];

        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(group);
}

- (void)testClearCurrentConfig {
    id dataSource = PFStrictProtocolMock(@protocol(PFPersistenceControllerProvider));
    PFPersistenceController *controller = [self mockedPersistenceController];
    OCMStub([dataSource persistenceController]).andReturn(controller);

    PFConfig *testConfig = [[PFConfig alloc] initWithFetchedConfig:[self testConfigDictionary]];

    PFCurrentConfigController *currentController = [PFCurrentConfigController controllerWithDataSource:dataSource];

    id group = [[controller getPersistenceGroupAsync] waitForResult:nil];
    OCMExpect([group setDataAsync:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSDictionary *dictionary = [PFJSONSerialization JSONObjectFromData:obj];
        return [dictionary isEqual:[self testConfigDictionary]];
    }] forKey:@"config"]).andReturn([BFTask taskWithResult:nil]);

    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Save"];
    [[currentController setCurrentConfigAsync:testConfig] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [saveExpectation fulfill];

        return nil;
    }];
    [self waitForTestExpectations];

    OCMExpect([group removeDataAsyncForKey:@"config"]).andReturn([BFTask taskWithResult:nil]);

    XCTestExpectation *clearExpectation = [self expectationWithDescription:@"Clear"];
    [[currentController clearCurrentConfigAsync] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [clearExpectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(group);
}

- (void)testClearMemoryCachedCurrentConfig {
    id dataSource = PFStrictProtocolMock(@protocol(PFPersistenceControllerProvider));
    PFPersistenceController *controller = [self mockedPersistenceController];
    OCMStub([dataSource persistenceController]).andReturn(controller);

    PFConfig *testConfig = [[PFConfig alloc] initWithFetchedConfig:[self testConfigDictionary]];

    PFCurrentConfigController *currentController = [PFCurrentConfigController controllerWithDataSource:dataSource];

    id group = [[controller getPersistenceGroupAsync] waitForResult:nil];
    OCMExpect([group setDataAsync:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSDictionary *dictionary = [PFJSONSerialization JSONObjectFromData:obj];
        return [dictionary isEqual:[self testConfigDictionary]];
    }] forKey:@"config"]).andReturn([BFTask taskWithResult:nil]);

    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Save"];
    [[currentController setCurrentConfigAsync:testConfig] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [saveExpectation fulfill];

        return nil;
    }];
    [self waitForTestExpectations];

    XCTestExpectation *clearExpectation = [self expectationWithDescription:@"Clear"];
    [[currentController clearMemoryCachedCurrentConfigAsync] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [clearExpectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];

    OCMVerifyAll(group);
}

@end
