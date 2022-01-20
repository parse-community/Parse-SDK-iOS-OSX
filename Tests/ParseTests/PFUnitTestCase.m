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

    XCTestExpectation *expect = [self expectationForNotification:PFParseInitializeDidCompleteNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    [Parse setApplicationId:self.applicationId clientKey:self.clientKey];
    
    [self waitForExpectations:@[expect] timeout:2];
}

- (void)tearDown {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];

    [super tearDown];
}

@end
