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

#import "PFConfigController.h"
#import "PFConfig_Private.h"
#import "PFCoreManager.h"
#import "PFCurrentConfigController.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface ConfigUnitTests : PFUnitTestCase

@property (nonatomic, strong) PFConfigController *mockedConfigController;

@end

@implementation ConfigUnitTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    [Parse _currentManager].coreManager.configController = self.mockedConfigController;
}

- (void)tearDown {
    self.mockedConfigController = nil;

    [super tearDown];
}

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFConfigController *)mockedConfigController {
    if (_mockedConfigController == nil) {
        _mockedConfigController = PFStrictClassMock([PFConfigController class]);

        BFTask *mockedTask = [BFTask taskWithResult:[self sampleConfig]];
        OCMStub([_mockedConfigController fetchConfigAsyncWithSessionToken:nil]).andReturn(mockedTask);

        PFCurrentConfigController *mockedCurrentController = PFStrictClassMock([PFCurrentConfigController class]);
        OCMStub([_mockedConfigController currentConfigController]).andReturn(mockedCurrentController);
        OCMStub([mockedCurrentController getCurrentConfigAsync]).andReturn(mockedTask);
    }

    return _mockedConfigController;
}

- (PFConfig *)sampleConfig {
    return [[PFConfig alloc] initWithFetchedConfig:@{ @"params": @{ @"testKey": @"testValue" } }];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testCurrentConfig {
    PFConfig *config = [PFConfig currentConfig];

    XCTAssertEqualObjects(config[@"testKey"], @"testValue");
    XCTAssertEqualObjects([config objectForKey:@"testKey"], @"testValue");
}

- (void)testGetConfig {
    PFConfig *config = [PFConfig getConfig];

    XCTAssertEqualObjects(config[@"testKey"], @"testValue");
    XCTAssertEqualObjects(config, [self sampleConfig]);
}

- (void)testGetConfigInBackground {
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *config, NSError *error) {
        XCTAssertNotNil(config);

        XCTAssertEqualObjects(config[@"testKey"], @"testValue");
        XCTAssertEqualObjects(config, [self sampleConfig]);

        [expectation fulfill];
    }];

    [self waitForTestExpectations];
}

- (void)testEquality {
    PFConfig *config = [self sampleConfig];

    PFConfig *currentConfig = [PFConfig currentConfig];
    PFConfig *thirdConfig = [[PFConfig alloc] init];

    XCTAssertEqual([config hash], [currentConfig hash]);
    XCTAssertNotEqual([config hash], [thirdConfig hash]);

    XCTAssertEqualObjects(config, currentConfig);
    XCTAssertNotEqualObjects(config, thirdConfig);
    XCTAssertNotEqualObjects(config, @"Hello World!");
}

@end
