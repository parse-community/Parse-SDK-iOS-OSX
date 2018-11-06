/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import CoreLocation.CLLocation;

#import "PFPolygon.h"
#import "PFEncoder.h"
#import "PFGeoPoint.h"
#import "PFPolygonPrivate.h"
#import "PFTestCase.h"
#import "PFObject.h"

@interface PolygonUnitTests : PFTestCase {
    NSArray *_testPoints;
}

@end

@implementation PolygonUnitTests

- (void)setUp {
    [super setUp];
    
    _testPoints = @[@[@0,@0],@[@0,@1],@[@1,@1],@[@1,@0]];
}

- (void)testPolygonFromCoordinates {
    PFPolygon *polygon = [PFPolygon polygonWithCoordinates:_testPoints];
    XCTAssertEqualObjects(polygon.coordinates, _testPoints);
}

- (void)testPolygonSaveToObject {
    PFPolygon *polygon = [PFPolygon polygonWithCoordinates:_testPoints];
    PFObject *object = [PFObject objectWithClassName:@"A"];
    object[@"bounds"] = polygon;
    XCTAssertEqualObjects(object[@"bounds"], polygon);
}

- (void)testPolygonDictionaryEncoding {
    PFPolygon *polygon = [PFPolygon polygonWithCoordinates:_testPoints];

    NSDictionary *dictionary = [polygon encodeIntoDictionary:nil];
    XCTAssertNotNil(dictionary);

    PFPolygon *polygonFromDictionary = [PFPolygon polygonWithDictionary:dictionary];
    XCTAssertEqualObjects(polygonFromDictionary, polygon);
    XCTAssertEqual(polygon.coordinates, polygonFromDictionary.coordinates);
}

- (void)testPolygonPFEncoding {
    PFPolygon *polygon = [PFPolygon polygonWithCoordinates:_testPoints];
    
    PFEncoder *encoder = [[PFEncoder alloc] init];
    NSDictionary *dictionary = [encoder encodeObject:polygon error:nil];
    XCTAssertNotNil(dictionary);
    
    PFPolygon *polygonFromDictionary = [PFPolygon polygonWithDictionary:dictionary];
    XCTAssertEqualObjects(polygonFromDictionary, polygon);
    XCTAssertEqual(polygon.coordinates, polygonFromDictionary.coordinates);
}

- (void)testPolygonExceptions {
    PFPolygon *polygon = [PFPolygon polygonWithCoordinates:_testPoints];
    NSArray *lessThan3 = @[@0, @0];
    NSArray *nonNumbers = @[@"str1", @"str2", @"str3"];
    PFAssertThrowsInvalidArgumentException([polygon setCoordinates:lessThan3]);
    PFAssertThrowsInvalidArgumentException([polygon setCoordinates:nonNumbers]);
}

- (void)testPolygonContainsPoint {
    PFPolygon *polygon = [PFPolygon polygonWithCoordinates:_testPoints];
    PFGeoPoint *inside = [PFGeoPoint geoPointWithLatitude:0.5 longitude:0.5];
    PFGeoPoint *outside = [PFGeoPoint geoPointWithLatitude:10 longitude:10];
    XCTAssertTrue([polygon containsPoint:inside]);
    XCTAssertFalse([polygon containsPoint:outside]);
}

- (void)testPolygonEquality {
    PFPolygon *polygonA = [PFPolygon polygonWithCoordinates:_testPoints];
    PFPolygon *polygonB = [PFPolygon polygonWithCoordinates:_testPoints];
    

    XCTAssertTrue([polygonA isEqual:polygonB]);
    XCTAssertTrue([polygonB isEqual:polygonA]);

    XCTAssertFalse([polygonA isEqual:@YES]);
    XCTAssertTrue([polygonA isEqual:polygonA]);
}

- (void)testNSCopying {
    PFPolygon *polygon = [PFPolygon polygonWithCoordinates:_testPoints];
    PFPolygon *polygonCopy = [polygon copy];
    XCTAssertEqualObjects(polygonCopy.coordinates, polygon.coordinates, @"Coordinates should be the same.");
}

- (void)testNSCoding {
    PFPolygon *polygon = [PFPolygon polygonWithCoordinates:_testPoints];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:polygon];
    XCTAssertTrue([data length] > 0, @"Encoded data should not be empty");

    PFPolygon *decodedPolygon = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    XCTAssertEqualObjects(decodedPolygon.coordinates, polygon.coordinates, @"Coordinates should be the same.");
}

- (void)testPolygonDescription {
    PFPolygon *polygon = [PFPolygon polygonWithCoordinates:_testPoints];
    NSString *description = [polygon description];
    XCTAssertNotNil(description);

    polygon.coordinates = @[@[@10,@10], @[@10,@15], @[@15,@15], @[@15,@10], @[@10,@10]];
    XCTAssertNotNil([polygon description]);
    XCTAssertNotEqualObjects(description, [polygon description]);
}

@end
