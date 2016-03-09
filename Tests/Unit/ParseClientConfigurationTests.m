/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Foundation;

#import "PFTestCase.h"
#import "ParseClientConfiguration.h"
#import "ParseClientConfiguration_Private.h"
#import "PFExtensionDataSharingTestHelper.h"

@interface ParseClientConfigurationTests : PFTestCase {
    PFExtensionDataSharingTestHelper *_testHelper;
}
@end

@implementation ParseClientConfigurationTests

- (void)setUp {
    [super setUp];

    _testHelper = [[PFExtensionDataSharingTestHelper alloc] init];
}

- (void)tearDown {
    _testHelper = nil;

    [super tearDown];
}

- (void)testConfigurationWithBlock {
    ParseClientConfiguration *configuration = [ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        configuration.applicationId = @"foo";
        configuration.clientKey = @"bar";
        configuration.server = @"http://localhost";
        configuration.localDatastoreEnabled = YES;
        configuration.networkRetryAttempts = 1337;
    }];

    XCTAssertEqualObjects(configuration.applicationId, @"foo");
    XCTAssertEqualObjects(configuration.clientKey, @"bar");
    XCTAssertEqualObjects(configuration.server, @"http://localhost");
    XCTAssertTrue(configuration.localDatastoreEnabled);
    XCTAssertEqual(configuration.networkRetryAttempts, 1337);
}

- (void)testEqual {
    ParseClientConfiguration *configurationA = [ParseClientConfiguration emptyConfiguration];
    ParseClientConfiguration *configurationB = [ParseClientConfiguration emptyConfiguration];
    XCTAssertEqualObjects(configurationA, configurationB);
    XCTAssertEqual(configurationA.hash, configurationB.hash);

    configurationA.applicationId = configurationB.applicationId = @"foo";
    XCTAssertEqualObjects(configurationA, configurationB);
    XCTAssertEqual(configurationA.hash, configurationB.hash);
    configurationB.applicationId = @"test";
    XCTAssertNotEqualObjects(configurationA, configurationB);
    configurationB.applicationId = configurationA.applicationId;

    configurationA.clientKey = configurationB.clientKey = @"bar";
    XCTAssertEqualObjects(configurationA, configurationB);
    XCTAssertEqual(configurationA.hash, configurationB.hash);
    configurationB.clientKey = @"test";
    XCTAssertNotEqualObjects(configurationA, configurationB);
    configurationB.clientKey = configurationA.clientKey;

    configurationA.server = configurationB.server = @"http://localhost";
    XCTAssertEqualObjects(configurationA, configurationB);
    XCTAssertEqual(configurationA.hash, configurationB.hash);
    configurationB.server = @"http://api.parse.com";
    XCTAssertNotEqualObjects(configurationA, configurationB);
    configurationB.server = configurationA.server;

    configurationA.localDatastoreEnabled = configurationB.localDatastoreEnabled = YES;
    XCTAssertEqualObjects(configurationA, configurationB);
    XCTAssertEqual(configurationA.hash, configurationB.hash);
    configurationB.localDatastoreEnabled = NO;
    XCTAssertNotEqualObjects(configurationA, configurationB);
    configurationB.localDatastoreEnabled = configurationA.localDatastoreEnabled;

    configurationA.networkRetryAttempts = configurationB.networkRetryAttempts = 1337;
    XCTAssertEqualObjects(configurationA, configurationB);
    XCTAssertEqual(configurationA.hash, configurationB.hash);
    configurationB.networkRetryAttempts = 7;
    XCTAssertNotEqualObjects(configurationA, configurationB);
}

- (void)testCopy {
    ParseClientConfiguration *configurationA = [ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        configuration.applicationId = @"foo";
        configuration.clientKey = @"bar";
        configuration.server = @"http://localhost";
        configuration.localDatastoreEnabled = YES;
        configuration.networkRetryAttempts = 1337;
    }];

    ParseClientConfiguration *configurationB = [configurationA copy];

    XCTAssertNotEqual(configurationA, configurationB);
    XCTAssertEqualObjects(configurationA, configurationB);

    configurationA.localDatastoreEnabled = NO;

    XCTAssertNotEqualObjects(configurationA, configurationB);

    XCTAssertEqualObjects(configurationB.applicationId, @"foo");
    XCTAssertEqualObjects(configurationB.clientKey, @"bar");
    XCTAssertEqualObjects(configurationB.server, @"http://localhost");
    XCTAssertTrue(configurationB.localDatastoreEnabled);
    XCTAssertEqual(configurationB.networkRetryAttempts, 1337);
}

- (void)testExtensionDataSharing {
    ParseClientConfiguration *configuration = [ParseClientConfiguration emptyConfiguration];

#if !PF_TARGET_OS_OSX
    // Innaccessible bundle identifiers should throw
    XCTAssertThrows(configuration.applicationGroupIdentifier = @"someBundleIdentifier");
#endif

    // Accessible bundle identifiers should not throw
    _testHelper.swizzledGroupContainerDirectoryPath = YES;
    XCTAssertNoThrow(configuration.applicationGroupIdentifier = @"someBundleIdentifier");

    // In non-extension environment, setting containing identifier should throw.
    XCTAssertThrows(configuration.containingApplicationBundleIdentifier = @"someContainer");

    _testHelper.runningInExtensionEnvironment = YES;

    // In extension environment this should succeed.
    XCTAssertNoThrow(configuration.containingApplicationBundleIdentifier = @"someContainer");
}

- (void)testServerValidation {
    [ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration>  _Nonnull configuration) {
        configuration.applicationId = @"a";
        configuration.clientKey = @"b";

        PFAssertThrowsInvalidArgumentException(configuration.server = @"");
        PFAssertThrowsInvalidArgumentException(configuration.server = @"Yolo Yarr");
    }];
}

@end
