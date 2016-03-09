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
#import "BFTask+Private.h"

@interface InstallationIdentifierUnitTests : PFTestCase

@end

@implementation InstallationIdentifierUnitTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)tearDown {
    [[Parse _currentManager] clearEventuallyQueue];
    [[[Parse _currentManager].installationIdentifierStore clearInstallationIdentifierAsync] waitForResult:nil];
    [Parse _clearCurrentManager];

    [super tearDown];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testNewInstallationIdentifierIsLowercase {
    [Parse setApplicationId:@"b" clientKey:@"c"];
    PFInstallationIdentifierStore *store = [Parse _currentManager].installationIdentifierStore;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store getInstallationIdentifierAsync] continueWithSuccessBlock:^id(BFTask<NSString *> *task) {
        NSString *installationId = task.result;
        XCTAssertNotNil(installationId);
        XCTAssertNotEqual(installationId.length, 0);
        XCTAssertEqualObjects(installationId, [installationId lowercaseString]);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCachedInstallationId {
    [Parse setApplicationId:@"b" clientKey:@"c"];
    PFInstallationIdentifierStore *store = [Parse _currentManager].installationIdentifierStore;

    [[store _clearCachedInstallationIdentifierAsync] waitForResult:nil];

    NSString *first = [[[store getInstallationIdentifierAsync] waitForResult:nil] copy];
    NSString *second = [[[store getInstallationIdentifierAsync] waitForResult:nil] copy];
    XCTAssertNotNil(first);
    XCTAssertNotNil(second);
    XCTAssertEqualObjects(first, second, @"installationId should be the same on different calls");

    [[store _clearCachedInstallationIdentifierAsync] waitForResult:nil];

    NSString *third = [[[store getInstallationIdentifierAsync] waitForResult:nil] copy];
    XCTAssertEqualObjects(first, third, @"installationId should be the same after clearing cache");

    [[store clearInstallationIdentifierAsync] waitForResult:nil];

    NSString *fourth = [[[store getInstallationIdentifierAsync] waitForResult:nil] copy];
    XCTAssertNotEqualObjects(first, fourth, @"clearing from disk should cause a new installationId");
}

- (void)testInstallationIdentifierThreadSafe {
    PFInstallationIdentifierStore *store = [Parse _currentManager].installationIdentifierStore;
    [[store clearInstallationIdentifierAsync] waitForResult:nil];
    dispatch_apply(100, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t iteration) {
        [store getInstallationIdentifierAsync];
        [store clearInstallationIdentifierAsync];
    });
}

@end
