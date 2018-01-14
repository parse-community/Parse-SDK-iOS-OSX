/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUnitTestCase.h"

#import "PFObjectSubclassingController.h"
#import "Parse_Private.h"

@interface PFUnitTestCase ()

@property (nonatomic, copy, readwrite) NSString *applicationId;
@property (nonatomic, copy, readwrite) NSString *clientKey;

@end

@implementation PFUnitTestCase

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    self.applicationId = [[NSUUID UUID] UUIDString];
    self.clientKey = [[NSUUID UUID] UUIDString];

    [Parse setApplicationId:self.applicationId clientKey:self.clientKey];

    // NOTE: (richardross) This may seem crazy, but this is to solve an issue with OCMock's mocking, which isn't thread
    // Safe. +[Parse setApplicationId: clientKey:] launches a background task that uses several class methods that are
    // mocked throughout our unit tests, and this ensures that that task has completed before we continue.
    [[Parse _currentManager] clearEventuallyQueue];
}

- (void)tearDown {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];

    [super tearDown];
}

@end
