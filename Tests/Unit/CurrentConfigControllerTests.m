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
#import "PFConfig.h"
#import "PFConfig_Private.h"
#import "PFCurrentConfigController.h"
#import "PFFileManager.h"
#import "PFTestCase.h"

@interface CurrentConfigControllerTests : PFTestCase

@end

@implementation CurrentConfigControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (NSDictionary *)testConfigDictionary {
    return @{ @"params" : @{@"testKey" : @"testValue"} };
}

- (PFFileManager *)mockedFileManagerWithConfigPath:(NSString *)path {
    id fileManager = PFPartialMock([[PFFileManager alloc] initWithApplicationIdentifier:OCMOCK_ANY
                                                             applicationGroupIdentifier:@"com.parse.test"]);

    OCMStub([fileManager parseDataItemPathForPathComponent:OCMOCK_ANY]).andReturn(path);

    return fileManager;
}

- (NSString *)configPathForSelector:(SEL)cmd {
    NSString *configPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(cmd)]
                            stringByAppendingPathExtension:@"config"];

    [[NSFileManager defaultManager] removeItemAtPath:configPath error:NULL];

    return configPath;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructor {
    id mockedFileManager = PFClassMock([PFFileManager class]);

    PFCurrentConfigController *controller = [[PFCurrentConfigController alloc] initWithFileManager:mockedFileManager];

    XCTAssertNotNil(controller);
    XCTAssertEqual(controller.fileManager, mockedFileManager);
}

- (void)testGetCurrentConfig {
    NSString *configPath = [self configPathForSelector:_cmd];

    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:configPath append:NO];
    [outputStream open];

    NSError *error = nil;
    [NSJSONSerialization writeJSONObject:[self testConfigDictionary]
                                toStream:outputStream
                                 options:0
                                   error:&error];

    [outputStream close];
    XCTAssertNil(error);

    PFFileManager *fileManager = [self mockedFileManagerWithConfigPath:configPath];
    PFCurrentConfigController *currentController = [PFCurrentConfigController controllerWithFileManager:fileManager];
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
    NSString *configPath = [self configPathForSelector:_cmd];
    PFConfig *testConfig = [[PFConfig alloc] initWithFetchedConfig:[self testConfigDictionary]];

    PFFileManager *fileManager = [self mockedFileManagerWithConfigPath:configPath];
    PFCurrentConfigController *currentController = [PFCurrentConfigController controllerWithFileManager:fileManager];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[currentController setCurrentConfigAsync:testConfig] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];

    NSData *data = [NSData dataWithContentsOfFile:configPath];
    XCTAssertNotNil(data);

    NSDictionary *contentsOfFile = [NSJSONSerialization JSONObjectWithData:data
                                                                   options:0
                                                                     error:NULL];
    XCTAssertEqualObjects(contentsOfFile, [self testConfigDictionary]);
}

- (void)testClearCurrentConfig {
    NSString *configPath = [self configPathForSelector:_cmd];
    PFConfig *testConfig = [[PFConfig alloc] initWithFetchedConfig:[self testConfigDictionary]];

    PFFileManager *fileManager = [self mockedFileManagerWithConfigPath:configPath];
    PFCurrentConfigController *currentController = [PFCurrentConfigController controllerWithFileManager:fileManager];
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Save"];

    [[currentController setCurrentConfigAsync:testConfig] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [saveExpectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];

    XCTestExpectation *clearExpectation = [self expectationWithDescription:@"Clear"];

    [[currentController clearCurrentConfigAsync] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse(task.faulted);
        [clearExpectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];

    NSData *data = [NSData dataWithContentsOfFile:configPath];
    XCTAssertNil(data);
}

- (void)testClearMemoryCachedCurrentConfig {
    NSString *configPath = [self configPathForSelector:_cmd];
    PFConfig *testConfig = [[PFConfig alloc] initWithFetchedConfig:[self testConfigDictionary]];

    PFFileManager *fileManager = [self mockedFileManagerWithConfigPath:configPath];
    PFCurrentConfigController *currentController = [PFCurrentConfigController controllerWithFileManager:fileManager];
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

    NSData *data = [NSData dataWithContentsOfFile:configPath];
    XCTAssertNotNil(data);

    // Ideally here we would check to ensure that we re-read from the path. However, you cannot re-stub
    // the same method using OCMock (Ugh), so for now just assume that it properly removed the current config.
}

@end
