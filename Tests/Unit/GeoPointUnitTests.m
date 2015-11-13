/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import CoreLocation.CLLocation;

#import "PFGeoPoint.h"
#import "PFGeoPointPrivate.h"
#import "PFTestCase.h"

@interface GeoPointUnitTests : PFTestCase

@end

@implementation GeoPointUnitTests

- (void)testDefaults {
    PFGeoPoint *point = [PFGeoPoint geoPoint];

    // Check default values
    XCTAssertEqualWithAccuracy(point.latitude, 0.0, 0.00001, @"Latitude should be 0.0");
    XCTAssertEqualWithAccuracy(point.longitude, 0.0, 0.00001, @"Longitude should be 0.0");
}

- (void)testGeoPointFromLocation {
    CLLocation *location = [[CLLocation alloc] initWithLatitude:10.0 longitude:20.0];

    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLocation:location];
    XCTAssertEqual(geoPoint.latitude, location.coordinate.latitude);
    XCTAssertEqual(geoPoint.longitude, location.coordinate.longitude);

    geoPoint = [PFGeoPoint geoPointWithLocation:nil];
    XCTAssertEqual(geoPoint.latitude, 0);
    XCTAssertEqual(geoPoint.longitude, 0);
}

- (void)testGeoPointDictionaryEncoding {
    PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:10 longitude:20];

    NSDictionary *dictionary = [point encodeIntoDictionary];
    XCTAssertNotNil(dictionary);

    PFGeoPoint *pointFromDictionary = [PFGeoPoint geoPointWithDictionary:dictionary];
    XCTAssertEqualObjects(pointFromDictionary, point);
    XCTAssertEqual(point.latitude, pointFromDictionary.latitude);
    XCTAssertEqual(point.longitude, pointFromDictionary.longitude);
}

- (void)testGeoExceptions {
    PFGeoPoint *point = [PFGeoPoint geoPointWithLatitude:34.0 longitude:24.0];

    // Setter exceptions
    PFAssertThrowsInvalidArgumentException([point setLatitude:90.001]);
    PFAssertThrowsInvalidArgumentException([point setLatitude:-90.001]);
    PFAssertThrowsInvalidArgumentException([point setLongitude:180.001]);
    PFAssertThrowsInvalidArgumentException([point setLongitude:-180.001]);
}

- (void)testGeoPointEquality {
    PFGeoPoint *pointA = [PFGeoPoint geoPointWithLatitude:10.2 longitude:11.3];
    PFGeoPoint *pointB = [PFGeoPoint geoPointWithLatitude:10.2 longitude:11.3];

    XCTAssertTrue([pointA isEqual:pointB]);
    XCTAssertTrue([pointB isEqual:pointA]);

    XCTAssertFalse([pointA isEqual:@YES]);
    XCTAssertTrue([pointA isEqual:pointA]);
}

- (void)testGeoPointHash {
    PFGeoPoint *pointA = [PFGeoPoint geoPointWithLatitude:10.2 longitude:11.3];
    PFGeoPoint *pointB = [PFGeoPoint geoPointWithLatitude:10.2 longitude:11.3];
    XCTAssertEqual([pointA hash], [pointB hash]);
}

- (void)testGeoUtilityDistance {
    double D2R = M_PI / 180.0;
    PFGeoPoint *pointA = [PFGeoPoint geoPoint];
    PFGeoPoint *pointB = [PFGeoPoint geoPoint];

    // Zero
    XCTAssertEqualWithAccuracy([pointA distanceInRadiansTo:pointB], 0.0, 0.000001,
                               @"Origin points with non-zero distance.");
    XCTAssertEqualWithAccuracy([pointB distanceInRadiansTo:pointA], 0.0, 0.000001,
                               @"Origin points with non-zero distance.");
    // Wrap Long
    [pointA setLongitude:179.0];
    [pointB setLongitude:-179.0];
    XCTAssertEqualWithAccuracy([pointA distanceInRadiansTo:pointB], 2.0 * D2R, 0.000001,
                               @"Long wrap angular distance error.");
    XCTAssertEqualWithAccuracy([pointB distanceInRadiansTo:pointA], 2.0 * D2R, 0.000001,
                               @"Long wrap angular distance error.");

    // North South Lat
    [pointA setLatitude:89.0];
    [pointA setLongitude:0.0];
    [pointB setLatitude:-89.0];
    [pointB setLongitude:0.0];

    XCTAssertEqualWithAccuracy([pointA distanceInRadiansTo:pointB], 178.0 * D2R, 0.000001,
                               @"NS pole wrap error");
    XCTAssertEqualWithAccuracy([pointB distanceInRadiansTo:pointA], 178.0 * D2R, 0.000001,
                               @"NS pole wrap error");

    // Long wrap Lat
    [pointA setLatitude:89.0];
    [pointA setLongitude:0.0];
    [pointB setLatitude:-89.0];
    [pointB setLongitude:179.9999];

    XCTAssertEqualWithAccuracy([pointA distanceInRadiansTo:pointB], 180 * D2R, 0.00001,
                               @"Lat wrap error.");
    XCTAssertEqualWithAccuracy([pointB distanceInRadiansTo:pointA], 180 * D2R, 0.00001,
                               @"Lat wrap error.");

    [pointA setLatitude:79.0];
    [pointA setLongitude:90.0];
    [pointB setLatitude:-79.0];
    [pointB setLongitude:-90.0];

    XCTAssertEqualWithAccuracy([pointA distanceInRadiansTo:pointB], 180.0 * D2R, 0.00001,
                               @"Lat long wrap");
    XCTAssertEqualWithAccuracy([pointB distanceInRadiansTo:pointA], 180.0 * D2R, 0.00001,
                               @"Lat long wrap");

    // Wrap near pole - somewhat ill conditioned case due to pole proximity
    [pointA setLatitude:85.0];
    [pointA setLongitude:90.0];
    [pointB setLatitude:85.0];
    [pointB setLongitude:-90.0];

    XCTAssertEqualWithAccuracy([pointA distanceInRadiansTo:pointB], 10.0 * D2R, 0.00001,
                               @"Pole proximity fail");
    XCTAssertEqualWithAccuracy([pointB distanceInRadiansTo:pointA], 10.0 * D2R, 0.00001,
                               @"Pole proximity fail");

    // Reference cities
    // Sydney Australia
    [pointA setLatitude:-34.0];
    [pointA setLongitude:151.0];

    // Buenos Aires
    [pointB setLatitude:-34.5];
    [pointB setLongitude:-58.35];

    XCTAssertEqualWithAccuracy([pointA distanceInRadiansTo:pointB], 1.85, 0.01,
                               @"Sydney to Buenos Aires Fail");
    XCTAssertEqualWithAccuracy([pointB distanceInRadiansTo:pointA], 1.85, 0.01,
                               @"Sydney to Buenos Aires Fail");

    // [SAC]  38.52  -121.50  Sacramento,CA
    PFGeoPoint *sacramento = [PFGeoPoint geoPointWithLatitude:38.52 longitude:-121.50];

    // [HNL]  21.35  -157.93  Honolulu Int,HI
    PFGeoPoint *honolulu = [PFGeoPoint geoPointWithLatitude:21.35 longitude:-157.93];

    // [51Q]  37.75  -122.68  San Francisco,CA
    PFGeoPoint *sanfran = [PFGeoPoint geoPointWithLatitude:37.75 longitude:-122.68];

    // Vorkuta 67.509619,64.085999
    PFGeoPoint *vorkuta = [PFGeoPoint geoPointWithLatitude:67.509619 longitude:64.085999];

    // London
    PFGeoPoint *london = [PFGeoPoint geoPointWithLatitude:51.501904 longitude:-0.115356];

    // Northampton
    PFGeoPoint *northampton = [PFGeoPoint geoPointWithLatitude:52.241256 longitude:-0.895386];

    // Powell St BART station
    PFGeoPoint *powell = [PFGeoPoint geoPointWithLatitude:37.78507 longitude:-122.407007];

    // Apple store
    PFGeoPoint *astore = [PFGeoPoint geoPointWithLatitude:37.785809 longitude:-122.406363];

    // Self
    XCTAssertEqualWithAccuracy([honolulu distanceInKilometersTo:honolulu], 0.0, 0.000001, @"Self distance");

    // SAC to HNL
    XCTAssertEqualWithAccuracy([sacramento distanceInKilometersTo:honolulu], 3964.8, 10.0, @"SAC to HNL");
    XCTAssertEqualWithAccuracy([sacramento distanceInMilesTo:honolulu], 2463.6, 10.0, @"SAC to HNL");

    // Semi-local
    XCTAssertEqualWithAccuracy([london distanceInKilometersTo:northampton], 98.4, 1.0, @"London Northampton");
    XCTAssertEqualWithAccuracy([london distanceInMilesTo:northampton], 61.2, 1.0, @"London Northampton");

    XCTAssertEqualWithAccuracy([london distanceInKilometersTo:northampton], 98.4, 1.0, @"London Northampton");
    XCTAssertEqualWithAccuracy([london distanceInMilesTo:northampton], 61.2, 1.0, @"London Northampton");

    XCTAssertEqualWithAccuracy([sacramento distanceInKilometersTo:sanfran], 134.5, 2.0, @"Sacramento San Fran");
    XCTAssertEqualWithAccuracy([sacramento distanceInMilesTo:sanfran], 84.8, 2.0, @"Sacramento San Fran");

    // Very local
    XCTAssertEqualWithAccuracy([powell distanceInKilometersTo:astore], 0.1, 0.05, @"Powell station and Apple store");

    // Far (for error tolerance's sake)
    XCTAssertEqualWithAccuracy([sacramento distanceInKilometersTo:vorkuta], 8303.8, 100.0, @"Sacramento to Vorkuta");
    XCTAssertEqualWithAccuracy([sacramento distanceInMilesTo:vorkuta], 5159.7, 100.0, @"Sacramento to Vorkuta");
}

- (void)testNSCopying {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:10.0 longitude:20.0];
    PFGeoPoint *geoPointCopy = [geoPoint copy];

    XCTAssertEqual(geoPointCopy.latitude, geoPoint.latitude, @"Latitude should be the same.");
    XCTAssertEqual(geoPointCopy.longitude, geoPoint.longitude, @"Longitude should be the same.");
}

- (void)testNSCoding {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:10.0 longitude:20.0];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:geoPoint];
    XCTAssertTrue([data length] > 0, @"Encoded data should not be empty");

    PFGeoPoint *decodedGeoPoint = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertEqual(decodedGeoPoint.latitude, geoPoint.latitude, @"Latitude should be the same.");
    XCTAssertEqual(decodedGeoPoint.longitude, geoPoint.longitude, @"Longitude should be the same.");
}

- (void)testGeoPointDescription {
    PFGeoPoint *point = [PFGeoPoint geoPoint];
    XCTAssertNotNil([point description]);

    point = [PFGeoPoint geoPointWithLatitude:10 longitude:20];
    NSString *description = [point description];
    XCTAssertNotNil(description);

    point.latitude = 20;
    XCTAssertNotNil([point description]);
    XCTAssertNotEqualObjects(description, [point description]);
}

- (void)testGeoPointForCurrentLocation {
    // Make sure we don't crash on nil block
    [PFGeoPoint geoPointForCurrentLocationInBackground:nil];
}

@end
