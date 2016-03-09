/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import CoreLocation;

#import <OCMock/OCMock.h>

#import "PFLocationManager.h"
#import "PFTestCase.h"
#import "PFTestSwizzlingUtilities.h"

@protocol PFTestCLLocationManager <NSObject>

@property (assign, nonatomic) id<CLLocationManagerDelegate> delegate;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;

@end

@interface LocationManagerTests : PFTestCase
@end

@implementation LocationManagerTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    PFLocationManager *locationManager = [[PFLocationManager alloc] init];
    XCTAssertNotNil(locationManager);

    id mockedSystemLocationManager = PFStrictClassMock([CLLocationManager class]);
    OCMStub([mockedSystemLocationManager setDelegate:OCMOCK_ANY]);
    locationManager = [[PFLocationManager alloc] initWithSystemLocationManager:mockedSystemLocationManager];

    XCTAssertNotNil(locationManager);

#if TARGET_OS_IPHONE

    id mockedBundle = PFStrictClassMock([NSBundle class]);
    id mockedApplication = PFStrictClassMock([UIApplication class]);

    locationManager = [[PFLocationManager alloc] initWithSystemLocationManager:mockedSystemLocationManager
                                                                   application:mockedApplication
                                                                        bundle:mockedBundle];

    XCTAssertNotNil(locationManager);

#endif
}

- (void)testAddBlockWithoutAnyAutorization {
    CLLocation *expectedLocation = [[CLLocation alloc] initWithLatitude:13.37 longitude:1337];

    id mockedSystemLocationManager = PFStrictProtocolMock(@protocol(PFTestCLLocationManager));
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

    PFLocationManager *locationManager = [[PFLocationManager alloc] initWithSystemLocationManager:mockedSystemLocationManager];

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

- (void)testFailWithError {
    NSError *expectedError = [NSError errorWithDomain:PFParseErrorDomain code:13337 userInfo:nil];
    id mockedSystemLocationManager = PFStrictProtocolMock(@protocol(PFTestCLLocationManager));
    __block __weak id<CLLocationManagerDelegate> delegate = nil;

    OCMStub([mockedSystemLocationManager setDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id argument = nil;
        [invocation getArgument:&argument atIndex:2];

        delegate = argument;
    });

    OCMExpect([mockedSystemLocationManager startUpdatingLocation]).andDo(^(NSInvocation *invoke) {
        [delegate locationManager:mockedSystemLocationManager didFailWithError:expectedError];
    });

    OCMExpect([mockedSystemLocationManager stopUpdatingLocation]);

    PFLocationManager *locationManager = [[PFLocationManager alloc] initWithSystemLocationManager:mockedSystemLocationManager];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [locationManager addBlockForCurrentLocation:^(CLLocation *location, NSError *error) {
        XCTAssertEqualObjects(error, expectedError);

        [expectation fulfill];
    }];

    [self waitForTestExpectations];

    OCMVerifyAll(mockedSystemLocationManager);
}

@end
