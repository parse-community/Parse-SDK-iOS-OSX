/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Bolts.BFTask;

#import "PFExtensionDataSharingTestHelper.h"
#import "PFFileManager.h"
#import "PFInternalUtils.h"
#import "PFMultiProcessFileLock.h"
#import "PFTestCase.h"
#import "Parse_Private.h"

//TODO: (nlutsenko,richardross) These tests are extremely flaky, we should update and re-enable them.

@interface ExtensionDataSharingTests : PFTestCase {
    PFExtensionDataSharingTestHelper *_testHelper;
}

@end

@implementation ExtensionDataSharingTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    _testHelper = [[PFExtensionDataSharingTestHelper alloc] init];
}

- (void)tearDown {
    [[Parse _currentManager] clearEventuallyQueue];

    NSString *path = [[Parse _currentManager].fileManager parseLocalSandboxDataDirectoryPath];

    [Parse _clearCurrentManager];
    [Parse _resetDataSharingIdentifiers];

    // This allows us to delete files while respecting file locks.
    NSArray *removalTasks = @[
#if TARGET_OS_IPHONE
        // Doing this on OSX is BAD, as this returns ~/Library/Application Support. Trust me, you don't want to delete this.
        [PFFileManager removeItemAtPathAsync:[PFExtensionDataSharingTestHelper sharedTestDirectoryPath]],
#endif
        [PFFileManager removeItemAtPathAsync:path]
    ];
    [[BFTask taskForCompletionOfAllTasks:removalTasks] waitUntilFinished];


    _testHelper = nil;

    [super tearDown];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testEnablingDataSharingFromMainApp {
    _testHelper.swizzledGroupContainerDirectoryPath = YES;
    _testHelper.runningInExtensionEnvironment = NO;

    [Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"];
    [Parse _resetDataSharingIdentifiers];

    _testHelper.runningInExtensionEnvironment = YES;
    XCTAssertThrows([Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"]);

    // Just to make sure that initialization runs smoothly
    [Parse setApplicationId:[[NSUUID UUID] UUIDString] clientKey:[[NSUUID UUID] UUIDString]];
}

- (void)testEnablingDataSharingFromExtensions {
    _testHelper.swizzledGroupContainerDirectoryPath = YES;
    _testHelper.runningInExtensionEnvironment = YES;

    [Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"
                                     containingApplication:@"parentYolo"];
    [Parse _resetDataSharingIdentifiers];

    _testHelper.runningInExtensionEnvironment = NO;
    XCTAssertThrows([Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"
                                                    containingApplication:@"parentYolo"]);

    // Just to make sure that initialization runs smoothly
    [Parse setApplicationId:[[NSUUID UUID] UUIDString] clientKey:[[NSUUID UUID] UUIDString]];
}

- (void)testMainAppUsesSharedContainer {
    _testHelper.swizzledGroupContainerDirectoryPath = YES;
    _testHelper.runningInExtensionEnvironment = NO;

    [Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"];
    [Parse setApplicationId:[[NSUUID UUID] UUIDString] clientKey:@"b"];

    // Paths are different on iOS and OSX.
    NSString *containerPath = [PFExtensionDataSharingTestHelper sharedTestDirectoryPathForGroupIdentifier:@"yolo"];
    [self assertDirectory:containerPath hasContents:@{ @"Parse" : @{ [Parse getApplicationId] : @{ @"applicationId" : [NSNull null] } } } only:NO];
}

- (void)testExtensionUsesSharedContainer {
    _testHelper.swizzledGroupContainerDirectoryPath = YES;
    _testHelper.runningInExtensionEnvironment = YES;

    [Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"
                                     containingApplication:@"parentYolo"];
    [Parse setApplicationId:[[NSUUID UUID] UUIDString] clientKey:@"b"];

    // Paths are different on iOS and OSX.
    NSString *containerPath = [PFExtensionDataSharingTestHelper sharedTestDirectoryPathForGroupIdentifier:@"yolo"];
    [self assertDirectory:containerPath hasContents:@{ @"Parse" : @{ [Parse getApplicationId] : @{ @"applicationId" : [NSNull null] } } } only:NO];
}

- (void)testMigratingDataFromMainSandbox {
    NSString *containerPath = [PFExtensionDataSharingTestHelper sharedTestDirectoryPathForGroupIdentifier:@"yolo"];

    NSString *applicationId = [[NSUUID UUID] UUIDString];

    [Parse enableLocalDatastore];
    [Parse setApplicationId:applicationId clientKey:@"b"];

    PFObject *object = [PFObject objectWithClassName:@"TestObject"];
    object[@"yolo"] = @"yarr";
    XCTAssertTrue([object pin]);

    // We are using the same directory on OSX, so this check is irrelevant
#if TARGET_OS_IPHONE
    [self assertDirectoryDoesntExist:[containerPath stringByAppendingPathComponent:@"Parse"]];
#endif

    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];
    [Parse _resetDataSharingIdentifiers];

    _testHelper.swizzledGroupContainerDirectoryPath = YES;
    _testHelper.runningInExtensionEnvironment = NO;

    [Parse enableLocalDatastore];
    [Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"];
    [Parse setApplicationId:applicationId clientKey:@"b"];

    PFQuery *query = [[PFQuery queryWithClassName:@"TestObject"] fromLocalDatastore];

    NSError *error = nil;
    NSInteger count = [query countObjects:&error];
    XCTAssertNil(error, @"%@", error);
    XCTAssertEqual(1, count);

    [self assertDirectory:containerPath hasContents:@{ @"Parse" :
                                                           @{ applicationId :
                                                                  @{ @"applicationId" : [NSNull null],
                                                                     @"ParseOfflineStore" : [NSNull null]
                                                                     }
                                                              }
                                                       } only:NO];
}

- (void)testMigratingDataFromExtensionsSandbox {
    NSString *containerPath = [PFExtensionDataSharingTestHelper sharedTestDirectoryPathForGroupIdentifier:@"yolo"];

    NSString *applicationId = [[NSUUID UUID] UUIDString];

    [Parse enableLocalDatastore];
    [Parse setApplicationId:applicationId clientKey:@"b"];

    PFObject *object = [PFObject objectWithClassName:@"TestObject"];
    object[@"yolo"] = @"yarr";
    XCTAssertTrue([object pin]);

    // We are using the same directory on OSX, so this check is irrelevant
#if TARGET_OS_IPHONE
    [self assertDirectoryDoesntExist:[containerPath stringByAppendingPathComponent:@"Parse"]];
#endif

    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];
    [Parse _resetDataSharingIdentifiers];

    _testHelper.swizzledGroupContainerDirectoryPath = YES;
    _testHelper.runningInExtensionEnvironment = YES;

    [Parse enableLocalDatastore];
    [Parse enableDataSharingWithApplicationGroupIdentifier:@"yolo"
                                     containingApplication:@"parentYolo"];
    [Parse setApplicationId:applicationId clientKey:@"b"];

    PFQuery *query = [[PFQuery queryWithClassName:@"TestObject"] fromLocalDatastore];

    // We are using the same directory on OSX, but different folders on iOS.
    NSError *error = nil;
    NSInteger count = [query countObjects:&error];

    XCTAssertNil(error, @"%@", error);

#if TARGET_OS_IPHONE
    XCTAssertEqual(0, count);
#else
    XCTAssertEqual(1, count);
#endif

    [self assertDirectory:containerPath hasContents:@{ @"Parse" :
                                                           @{ applicationId :
                                                                  @{ @"applicationId" : [NSNull null],
                                                                     @"ParseOfflineStore" : [NSNull null]
                                                                     }
                                                              }
                                                       } only:NO];
}

@end
