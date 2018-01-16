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

#import "PFAnalyticsController.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface AnalyticsUnitTests : PFUnitTestCase

@end

@implementation AnalyticsUnitTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testTrackEvent {
    id controllerMock = PFClassMock([PFAnalyticsController class]);
    [Parse _currentManager].analyticsController = controllerMock;

    [[PFAnalytics trackEvent:@"yolo"] waitUntilFinished];
    OCMVerify([controllerMock trackEventAsyncWithName:[OCMArg isEqual:@"yolo"]
                                           dimensions:[OCMArg isNil]
                                         sessionToken:[OCMArg isNil]]);
}

- (void)testTrackEventViaBlock {
    id controllerMock = PFClassMock([PFAnalyticsController class]);
    [Parse _currentManager].analyticsController = controllerMock;

    BFTask *task = [BFTask taskWithResult:@YES];
    OCMStub([controllerMock trackEventAsyncWithName:[OCMArg isEqual:@"yolo1"]
                                         dimensions:[OCMArg isNil]
                                       sessionToken:[OCMArg isNil]]).andReturn(task);
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFAnalytics trackEventInBackground:@"yolo1" block:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testTrackEventWithDimensionsViaTask {
    id controllerMock = PFClassMock([PFAnalyticsController class]);
    [Parse _currentManager].analyticsController = controllerMock;

    NSDictionary *dimensions = @{ @"a" : @"b" };
    [[PFAnalytics trackEvent:@"yolo" dimensions:dimensions] waitUntilFinished];
    OCMVerify([controllerMock trackEventAsyncWithName:[OCMArg isEqual:@"yolo"]
                                           dimensions:[OCMArg isEqual:dimensions]
                                         sessionToken:[OCMArg isNil]]);
}

- (void)testTrackEventWithDimensionsViaBlock {
    id controllerMock = PFClassMock([PFAnalyticsController class]);
    [Parse _currentManager].analyticsController = controllerMock;

    BFTask *task = [BFTask taskWithResult:@YES];
    OCMStub([controllerMock trackEventAsyncWithName:[OCMArg isEqual:@"yolo1"]
                                         dimensions:[OCMArg isEqual:@{ @"c" : @"d" }]
                                       sessionToken:[OCMArg isNil]]).andReturn(task);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFAnalytics trackEventInBackground:@"yolo1" dimensions:@{ @"c" : @"d" } block:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testTrackEventNameValidation {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEvent:nil]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEventInBackground:nil block:nil]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEvent:nil dimensions:nil]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEventInBackground:nil dimensions:nil block:nil]);
#pragma clang diagnostic pop
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEvent:@" "]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEventInBackground:@" " block:nil]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEvent:@" " dimensions:nil]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEventInBackground:@" " dimensions:nil block:nil]);

    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEvent:@"\n"]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEventInBackground:@"\n" block:nil]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEvent:@"\n" dimensions:nil]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEventInBackground:@"\n" dimensions:nil block:nil]);
}

- (void)testTrackEventDimensionsValidation {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-literal-conversion"
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEvent:@"a" dimensions:@{ @2 : @"yolo" }]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEvent:@"a" dimensions:@{ @"yolo" : @2 }]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEventInBackground:@"a"
                                                                    dimensions:@{ @"yolo" : @2 }
                                                                         block:nil]);
    PFAssertThrowsInvalidArgumentException([PFAnalytics trackEventInBackground:@"a"
                                                                    dimensions:@{ @2 : @"yolo" }
                                                                         block:nil]);
#pragma clang diagnostic pop
}

- (void)testTrackAppOpenedWithLaunchOptionsViaTask {
    id controllerMock = PFClassMock([PFAnalyticsController class]);
    [Parse _currentManager].analyticsController = controllerMock;

    NSDictionary *notificationPayload = @{ @"aps" : @"yolo" };
#if TARGET_OS_IPHONE
    NSDictionary *launchOptions = @{ UIApplicationLaunchOptionsRemoteNotificationKey : notificationPayload };
#else
    NSDictionary *launchOptions = @{ NSApplicationLaunchUserNotificationKey : notificationPayload };
#endif

    [[PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions] waitUntilFinished];
    OCMVerify([controllerMock trackAppOpenedEventAsyncWithRemoteNotificationPayload:[OCMArg isEqual:notificationPayload]
                                                                       sessionToken:[OCMArg isNil]]);
}

- (void)testTrackAppOpenedWithLaunchOptionsViaBlock {
    id controllerMock = PFClassMock([PFAnalyticsController class]);
    [Parse _currentManager].analyticsController = controllerMock;

    NSDictionary *notificationPayload = @{ @"aps" : @"yolo" };
#if TARGET_OS_IPHONE
    NSDictionary *launchOptions = @{ UIApplicationLaunchOptionsRemoteNotificationKey : notificationPayload };
#else
    NSDictionary *launchOptions = @{ NSApplicationLaunchUserNotificationKey : notificationPayload };
#endif

    BFTask *task = [BFTask taskWithResult:@YES];
    OCMStub([controllerMock trackAppOpenedEventAsyncWithRemoteNotificationPayload:[OCMArg isEqual:notificationPayload]
                                                                     sessionToken:[OCMArg isNil]]).andReturn(task);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFAnalytics trackAppOpenedWithLaunchOptionsInBackground:launchOptions block:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testTrackAppOpenedWithRemoteNotificationPayloadViaTask {
    id controllerMock = PFClassMock([PFAnalyticsController class]);
    [Parse _currentManager].analyticsController = controllerMock;

    NSDictionary *payload = @{ @"aps" : @"yolo" };

    [[PFAnalytics trackAppOpenedWithRemoteNotificationPayload:payload] waitUntilFinished];
    OCMVerify([controllerMock trackAppOpenedEventAsyncWithRemoteNotificationPayload:[OCMArg isEqual:payload]
                                                                       sessionToken:[OCMArg isNil]]);
}

- (void)testTrackAppOpenedWithRemoteNotificationPayloadViaBlock {
    id controllerMock = PFClassMock([PFAnalyticsController class]);
    [Parse _currentManager].analyticsController = controllerMock;

    NSDictionary *payload = @{ @"aps" : @"yolo" };

    BFTask *task = [BFTask taskWithResult:@YES];
    OCMStub([controllerMock trackAppOpenedEventAsyncWithRemoteNotificationPayload:[OCMArg isEqual:payload]
                                                                     sessionToken:[OCMArg isNil]]).andReturn(task);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFAnalytics trackAppOpenedWithRemoteNotificationPayloadInBackground:payload block:^(BOOL succeeded, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

@end
