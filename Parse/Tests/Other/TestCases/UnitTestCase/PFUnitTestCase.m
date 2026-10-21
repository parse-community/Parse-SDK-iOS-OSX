/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUnitTestCase.h"

#import "PFApplication.h"
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

    // On a freshly booted iOS 27 simulator, PFApplication's first read of the app icon badge number on the main queue takes minutes
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [PFApplication currentApplication];
        XCTestExpectation *badgeRead = [self expectationWithDescription:@"Read app icon badge number"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [badgeRead fulfill];
        });
        [self waitForExpectations:@[badgeRead] timeout:600];
    });

    self.applicationId = [[NSUUID UUID] UUIDString];
    self.clientKey = [[NSUUID UUID] UUIDString];

    XCTestExpectation *expect = [self expectationForNotification:PFParseInitializeDidCompleteNotification object:nil handler:^BOOL(NSNotification * _Nonnull notification) {
        return YES;
    }];
    
    [Parse setApplicationId:self.applicationId clientKey:self.clientKey];
    
    [self waitForExpectations:@[expect] timeout:30];
}

- (void)tearDown {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];

    [super tearDown];
}

@end
