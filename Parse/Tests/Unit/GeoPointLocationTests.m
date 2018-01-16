/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "CLLocationManager+TestAdditions.h"
#import "PFCoreManager.h"
#import "PFGeoPoint.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface GeoPointLocationTests : PFUnitTestCase

@end

@implementation GeoPointLocationTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    [CLLocationManager reset];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testGeoPointForCurrentLocation {
    [CLLocationManager setMockingEnabled:YES];

    __block NSInteger returnedGeoPoints = 0;
    // Simulate a delayed response from locationManager, make sure PFGeoPoints are
    // returned for all requests.
    [CLLocationManager setReturnLocation:NO];
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        XCTAssertEqualWithAccuracy(geoPoint.latitude, CL_DEFAULT_LATITUDE, 0.00001,
                                   @"Current location should have been set to fakeLocation");
        XCTAssertEqualWithAccuracy(geoPoint.longitude, CL_DEFAULT_LONGITUDE, 0.00001,
                                   @"Current location should have been set to fakeLocation");
        XCTAssertNil(error, @"No error should have been found");
        if (geoPoint) {
            returnedGeoPoints++;
        }
    }];
    [CLLocationManager setReturnLocation:YES];
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (geoPoint) {
            returnedGeoPoints++;
        }
    }];
    XCTAssertEqual(2, returnedGeoPoints, @"Both blocks should have been called");

    returnedGeoPoints = 0;
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (geoPoint) {
            returnedGeoPoints++;
        }
    }];
    XCTAssertEqual(1, returnedGeoPoints, @"Only the final block should have been called");
}

- (void)testGeoLocationManager {
    [CLLocationManager setMockingEnabled:YES];

    // Short-circuits the locationManager so it calls the delegate's -locationManager:didFailWithError:
    [CLLocationManager setWillFail:YES];
    __block NSInteger errorCount = 0;
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (error) {
            errorCount++;
        }
    }];
    XCTAssertEqual(1, errorCount, @"Failure is passed back as an error");

    [CLLocationManager setWillFail:NO];
    __block NSInteger geoPointCount = 0;
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (geoPoint) {
            geoPointCount++;
        }
    }];
    XCTAssertEqual(1, geoPointCount, @"CLLocationManager should be passing back locations");
}

- (void)testGeoPointForCurrentLocationNested {
    // Short-circuits the locationManager so it calls the delegate's -locationManager:didFailWithError:
    [CLLocationManager setWillFail:YES];
    __block NSInteger errorCount = 0;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
        if (error) {
            errorCount++;
            [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
                errorCount++;
                [expectation fulfill];
            }];
        }
    }];
    [self waitForTestExpectations];
    XCTAssertEqual(2, errorCount, @"Failure is passed back as an error");
}

- (void)testGeoPointForCurrentLocationFromBackgroundThread {
    [CLLocationManager setMockingEnabled:YES];
    [CLLocationManager setReturnLocation:YES];
    [CLLocationManager setWillFail:NO];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
            [expectation fulfill];
        }];
    });
    [self waitForTestExpectations];
}

@end
