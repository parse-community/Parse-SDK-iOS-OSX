/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFExtensionDataSharingTestHelper.h"
#import "PFFileManager.h"
#import "PFInternalUtils.h"
#import "PFTestCase.h"
#import "Parse_Private.h"

//TODO: (nlutsenko,richardross) These tests are extremely flaky, we should update and re-enable them.

@interface ExtensionDataSharingMobileTests : PFTestCase {
    PFExtensionDataSharingTestHelper *_testHelper;
}

@end

@implementation ExtensionDataSharingMobileTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    _testHelper = [[PFExtensionDataSharingTestHelper alloc] init];

    [[Parse _currentManager].offlineStore clearDatabase];
    [Parse _clearCurrentManager];
}

- (void)tearDown {
    [[Parse _currentManager] clearEventuallyQueue];
    [[Parse _currentManager].offlineStore clearDatabase];
    [Parse _currentManager].offlineStore = nil;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:[PFExtensionDataSharingTestHelper sharedTestDirectoryPath] error:nil];
    [fileManager removeItemAtPath:[[Parse _currentManager].fileManager parseDefaultDataDirectoryPath] error:nil];
    [fileManager removeItemAtPath:[[Parse _currentManager].fileManager parseLocalSandboxDataDirectoryPath] error:nil];

    [Parse _clearCurrentManager];
    [Parse _resetDataSharingIdentifiers];

    _testHelper = nil;

    [super tearDown];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testEnablingDataSharingWithoutAppGroupContainer {
    _testHelper.swizzledGroupContainerDirectoryPath = NO;

    XCTAssertThrows([Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"]);

    _testHelper.runningInExtensionEnvironment = YES;

    XCTAssertThrows([Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"
                                                     containingApplication:@"parentYolo"]);
}

@end
