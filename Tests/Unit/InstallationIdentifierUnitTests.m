/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFInstallationIdentifierStore_Private.h"
#import "PFTestCase.h"
#import "Parse_Private.h"

@interface InstallationIdentifierUnitTests : PFTestCase

@end

@implementation InstallationIdentifierUnitTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)tearDown {
    [[Parse _currentManager] clearEventuallyQueue];
    [[Parse _currentManager].installationIdentifierStore clearInstallationIdentifier];
    [Parse _clearCurrentManager];

    [super tearDown];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testNewInstallationIdentifierIsLowercase {
    [Parse setApplicationId:@"b" clientKey:@"c"];
    PFInstallationIdentifierStore *store = [Parse _currentManager].installationIdentifierStore;
    NSString *installationId = store.installationIdentifier;
    XCTAssertEqualObjects(installationId, [installationId lowercaseString]);
}

- (void)testCachedInstallationId {
    [Parse setApplicationId:@"b" clientKey:@"c"];
    PFInstallationIdentifierStore *store = [Parse _currentManager].installationIdentifierStore;

    [store _clearCachedInstallationIdentifier];
    NSString *first = [store.installationIdentifier copy];
    NSString *second = [store.installationIdentifier copy];
    XCTAssertEqualObjects(first, second, @"installationId should be the same on different calls");
    [store _clearCachedInstallationIdentifier];
    NSString *third = [store.installationIdentifier copy];
    XCTAssertEqualObjects(first, third, @"installationId should be the same after clearing cache");
    [store clearInstallationIdentifier];
    NSString *fourth = store.installationIdentifier;
    XCTAssertNotEqualObjects(first, fourth, @"clearing from disk should cause a new installationId");
}

@end
