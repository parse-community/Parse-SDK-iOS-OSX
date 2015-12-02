/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import CoreLocation;
@import UIKit;

#import <OCMock/OCMock.h>

#import "PFLocationManager.h"
#import "PFUnitTestCase.h"

/**
 We do this because OCMock does not allow you to stub -respondsToSelector:, so we force it to bend to our will using a
 protocol mock.

 TODO: (richardross) Update this to use a traditional mock once OCMock supports it.
 */
@protocol PFTestCLLocationManagerInterfaceWithoutAlwaysAuth <NSObject>

@property (assign, nonatomic) id<CLLocationManagerDelegate> delegate;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end

@protocol PFTestCLLocationManagerInterfaceWithAlwaysAuth <PFTestCLLocationManagerInterfaceWithoutAlwaysAuth>

- (void)requestWhenInUseAuthorization;
- (void)requestAlwaysAuthorization;

@end

@interface LocationManagerMobileTests : PFUnitTestCase

@end

@implementation LocationManagerMobileTests

- (void)testAddBlockWithForegroundAuthorization {
    CLLocation *expectedLocation = [[CLLocation alloc] initWithLatitude:13.37 longitude:1337];

    id mockedApplication = PFStrictClassMock([UIApplication class]);
    id mockedBundle = PFStrictClassMock([NSBundle class]);
    id mockedSystemLocationManager = PFStrictProtocolMock(@protocol(PFTestCLLocationManagerInterfaceWithAlwaysAuth));

    __block __weak id<CLLocationManagerDelegate> delegate = nil;

    OCMStub([mockedSystemLocationManager setDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id argument = nil;
        [invocation getArgument:&argument atIndex:2];

        delegate = argument;
    });

    OCMExpect([mockedSystemLocationManager startUpdatingLocation]).andDo(^(NSInvocation *invoke) {
        [delegate locationManager:mockedSystemLocationManager didUpdateLocations:@[ expectedLocation ]];
    });

    OCMExpect([mockedSystemLocationManager stopUpdatingLocation]);
    OCMExpect([mockedSystemLocationManager requestWhenInUseAuthorization]);

    OCMStub([mockedApplication applicationState]).andReturn(UIApplicationStateActive);
    OCMStub([mockedBundle objectForInfoDictionaryKey:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isEqualToString:@"NSLocationWhenInUseUsageDescription"];
    }]]).andReturn(@"foreground");

    PFLocationManager *locationManager = [[PFLocationManager alloc] initWithSystemLocationManager:mockedSystemLocationManager
                                                                                      application:mockedApplication
                                                                                           bundle:mockedBundle];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [locationManager addBlockForCurrentLocation:^(CLLocation *location, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(location.coordinate.latitude, 13.37);
        XCTAssertEqual(location.coordinate.longitude, 1337);

        [expectation fulfill];
    }];

    [self waitForTestExpectations];

    OCMVerifyAll(mockedSystemLocationManager);
}

- (void)testAddBlockWithBackgroundAuthorization {
    CLLocation *expectedLocation = [[CLLocation alloc] initWithLatitude:13.37 longitude:1337];

    id mockedApplication = PFStrictClassMock([UIApplication class]);
    id mockedBundle = PFStrictClassMock([NSBundle class]);
    id mockedSystemLocationManager = PFStrictProtocolMock(@protocol(PFTestCLLocationManagerInterfaceWithAlwaysAuth));

    __block __weak id<CLLocationManagerDelegate> delegate = nil;

    OCMStub([mockedSystemLocationManager setDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id argument = nil;
        [invocation getArgument:&argument atIndex:2];

        delegate = argument;
    });

    OCMExpect([mockedSystemLocationManager startUpdatingLocation]).andDo(^(NSInvocation *invoke) {
        [delegate locationManager:mockedSystemLocationManager didUpdateLocations:@[ expectedLocation ]];
    });

    OCMExpect([mockedSystemLocationManager stopUpdatingLocation]);
    OCMExpect([mockedSystemLocationManager requestAlwaysAuthorization]);

    OCMStub([mockedApplication applicationState]).andReturn(UIApplicationStateActive);
    OCMStub([mockedBundle objectForInfoDictionaryKey:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isEqualToString:@"NSLocationWhenInUseUsageDescription"];
    }]]).andReturn(nil);

    PFLocationManager *locationManager = [[PFLocationManager alloc] initWithSystemLocationManager:mockedSystemLocationManager
                                                                                      application:mockedApplication
                                                                                           bundle:mockedBundle];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [locationManager addBlockForCurrentLocation:^(CLLocation *location, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(location.coordinate.latitude, 13.37);
        XCTAssertEqual(location.coordinate.longitude, 1337);

        [expectation fulfill];
    }];

    [self waitForTestExpectations];

    OCMVerifyAll(mockedSystemLocationManager);
}

@end
