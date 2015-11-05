/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDecoder.h"
#import "PFFieldOperation.h"
#import "PFFile.h"
#import "PFGeoPoint.h"
#import "PFObjectPrivate.h"
#import "PFRelationPrivate.h"
#import "PFTestCase.h"

@interface DecoderTests : PFTestCase

@end

@implementation DecoderTests

- (void)testConstructors {
    PFDecoder *decoder = [[PFDecoder alloc] init];
    XCTAssertNotNil(decoder);
}

- (void)testDefaultObjectDecoder {
    PFDecoder *decoder = [PFDecoder objectDecoder];
    XCTAssertNotNil(decoder);
    XCTAssertEqual(decoder, [PFDecoder objectDecoder]);
}

- (void)testDecodingFieldOperations {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"key" : @{@"__op" : @"Increment",
                                                                @"amount" : @100500} }];
    XCTAssertNotNil(decoded);

    PFIncrementOperation *operation = decoded[@"key"];
    XCTAssertNotNil(operation);
    PFAssertIsKindOfClass(operation, [PFIncrementOperation class]);
    XCTAssertEqualObjects(operation.amount, @100500);
}

- (void)testDecodingDates {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"date" : @{@"__type" : @"Date",
                                                                 @"iso" : @"1970-01-01T00:00:01.000Z"} }];
    XCTAssertNotNil(decoded);

    NSDate *date = decoded[@"date"];
    XCTAssertNotNil(date);
    PFAssertIsKindOfClass(date, [NSDate class]);
    XCTAssertEqualObjects(date, [NSDate dateWithTimeIntervalSince1970:1.0]);
}

- (void)testDecodingBytes {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"data" : @{@"__type" : @"Bytes",
                                                                 @"base64" : @"eW9sbw=="} }];
    XCTAssertNotNil(decoded);

    NSData *data = decoded[@"data"];
    XCTAssertNotNil(data);
    PFAssertIsKindOfClass(data, [NSData class]);

    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(string, @"yolo");
}

- (void)testDecodingGeoPoints {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"geoPoint" : @{@"__type" : @"GeoPoint",
                                                                     @"latitude" : @10,
                                                                     @"longitude" : @20} }];
    XCTAssertNotNil(decoded);

    PFGeoPoint *geoPoint = decoded[@"geoPoint"];
    XCTAssertNotNil(geoPoint);
    PFAssertIsKindOfClass(geoPoint, [PFGeoPoint class]);

    XCTAssertEqualObjects(geoPoint, [PFGeoPoint geoPointWithLatitude:10.0 longitude:20.0]);
}

- (void)testDecodingRelations {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    NSDictionary *decoded = [decoder decodeObject:@{ @"relation" : @{@"__type" : @"Relation",
                                                                     @"className" : @"Yolo",
                                                                     @"objects" : @[ object ]}
                                                     }];
    XCTAssertNotNil(decoded);

    PFRelation *relation = decoded[@"relation"];
    XCTAssertNotNil(relation);
    PFAssertIsKindOfClass(relation, [PFRelation class]);

    XCTAssertEqualObjects(relation.targetClass, @"Yolo");
    XCTAssertTrue([relation _hasKnownObject:object]);
}

- (void)testDecodingFiles {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"file" : @{@"__type" : @"File",
                                                                 @"name" : @"yolo.png",
                                                                 @"url" : @"http://yarr.com/yolo.png"} }];
    XCTAssertNotNil(decoded);

    PFFile *file = decoded[@"file"];
    XCTAssertNotNil(file);
    PFAssertIsKindOfClass(file, [PFFile class]);

    XCTAssertEqualObjects(file.name, @"yolo.png");
    XCTAssertEqualObjects(file.url, @"http://yarr.com/yolo.png");
}

- (void)testDecodingPointers {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"pointer1" : @{@"__type" : @"Pointer",
                                                                     @"className" : @"Yolo",
                                                                     @"objectId" : @"123"},
                                                     @"pointer2" : @{@"__type" : @"Pointer",
                                                                     @"className" : @"Yolo1",
                                                                     @"localId" : @"456"} }];
    XCTAssertNotNil(decoded);

    PFObject *object = decoded[@"pointer1"];
    XCTAssertNotNil(object);
    PFAssertIsKindOfClass(object, [PFObject class]);

    XCTAssertEqualObjects(object.parseClassName, @"Yolo");
    XCTAssertEqualObjects(object.objectId, @"123");

    PFObject *localObject = decoded[@"pointer2"];
    XCTAssertNotNil(localObject);
    PFAssertIsKindOfClass(localObject, [PFObject class]);

    XCTAssertEqualObjects(localObject.parseClassName, @"Yolo1");
    XCTAssertNil(localObject.objectId);
    XCTAssertEqualObjects([localObject getOrCreateLocalId], @"456");
}

- (void)testDecodingObjects {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"object" : @{@"__type" : @"Object",
                                                                   @"className" : @"Yolo",
                                                                   @"objectId" : @"123"} }];
    XCTAssertNotNil(decoded);

    PFObject *object = decoded[@"object"];
    XCTAssertNotNil(object);
    PFAssertIsKindOfClass(object, [PFObject class]);

    XCTAssertEqualObjects(object.parseClassName, @"Yolo");
    XCTAssertEqualObjects(object.objectId, @"123");
}

- (void)testDecodingObjectsWithDates {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"object" : @{@"__type" : @"Object",
                                                                   @"className" : @"Yolo",
                                                                   @"objectId" : @"123",
                                                                   @"updatedAt" : @"1970-01-01T00:00:01.000Z",
                                                                   @"createdAt" : @"1970-01-01T00:00:02.000Z"} }];
    PFObject *object = decoded[@"object"];

    XCTAssertEqualObjects(object.updatedAt, [NSDate dateWithTimeIntervalSince1970:1.0]);
    XCTAssertEqualObjects(object.createdAt, [NSDate dateWithTimeIntervalSince1970:2.0]);

    decoded = [decoder decodeObject:@{ @"object" : @{@"__type" : @"Object",
                                                     @"className" : @"Yolo",
                                                     @"objectId" : @"123",
                                                     @"updatedAt" : @{@"__type" : @"Date",
                                                                      @"iso" : @"1970-01-01T00:00:01.000Z"},
                                                     @"createdAt" : @{@"__type" : @"Date",
                                                                      @"iso" : @"1970-01-01T00:00:02.000Z"}} }];
    object = decoded[@"object"];
    XCTAssertEqualObjects(object.updatedAt, [NSDate dateWithTimeIntervalSince1970:1.0]);
    XCTAssertEqualObjects(object.createdAt, [NSDate dateWithTimeIntervalSince1970:2.0]);
}

- (void)testDecodingUnknownType {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"yarr" : @{@"__type" : @"Yolo",
                                                                 @"name" : @"Yolo!"} }];
    XCTAssertNotNil(decoded);

    NSDictionary *dictionary = decoded[@"yarr"];
    XCTAssertNotNil(dictionary);
    PFAssertIsKindOfClass(dictionary, [NSDictionary class]);

    XCTAssertEqualObjects(dictionary[@"name"], @"Yolo!");
}

- (void)testDecodingArrays {
    PFDecoder *decoder = [[PFDecoder alloc] init];

    NSDictionary *decoded = [decoder decodeObject:@{ @"array" : @[ @1, @{@"a" : @"b"} ] }];
    XCTAssertNotNil(decoded);

    NSArray *array = decoded[@"array"];
    XCTAssertNotNil(array);
    PFAssertIsKindOfClass(array, [NSArray class]);

    XCTAssertEqualObjects(array[0], @1);
    XCTAssertEqualObjects(array[1], @{ @"a" : @"b" });
}

///--------------------------------------
#pragma mark - OfflineDecoder Tests
///--------------------------------------

- (void)testOfflineDecoderConstructors {
    PFOfflineDecoder *decoder = [PFOfflineDecoder decoderWithOfflineObjects:@{ @"yolo11" : [PFObject objectWithClassName:@"Yolo"] }];
    XCTAssertNotNil(decoder);
}

- (void)testOfflineDecoderDecoding {
    NSDictionary *offlineObjects = @{ @"yolo11" : [BFTask taskWithResult:[PFObject objectWithClassName:@"Yolo"]] };
    PFOfflineDecoder *decoder = [PFOfflineDecoder decoderWithOfflineObjects:offlineObjects];

    NSArray *decoded = [decoder decodeObject:@[ @{ @"__type" : @"OfflineObject",
                                                   @"uuid" : @"yolo11"
                                                   },
                                                @{ @"__type" : @"Object",
                                                   @"className" : @"Yarr"
                                                   } ]];
    XCTAssertNotNil(decoded);

    PFObject *offlineObject = decoded[0];
    XCTAssertNotNil(offlineObject);
    XCTAssertEqual(offlineObject, [offlineObjects[@"yolo11"] result]);

    PFObject *object = decoded[1];
    XCTAssertNotNil(object);
    XCTAssertNotEqual(object, offlineObject);
    XCTAssertEqualObjects(object.parseClassName, @"Yarr");
}

///--------------------------------------
#pragma mark - KnownParseObjectDecoder Tests
///--------------------------------------

- (void)testKnownParseObjectDecoderConstructors {
    PFKnownParseObjectDecoder *decoder = [PFKnownParseObjectDecoder decoderWithFetchedObjects:@{ @"a" : [PFObject objectWithClassName:@"Yolo"] }];
    XCTAssertNotNil(decoder);
}

- (void)testKnownParseObjectDecoderDecoding {
    NSDictionary *objects = @{ @"a" : [PFObject objectWithClassName:@"Yolo"] };
    PFKnownParseObjectDecoder *decoder = [PFKnownParseObjectDecoder decoderWithFetchedObjects:objects];

    NSArray *decoded = [decoder decodeObject:@[ @{ @"__type" : @"Pointer",
                                                   @"className" : @"Yolo",
                                                   @"objectId" : @"a" },
                                                @{ @"__type" : @"Pointer",
                                                   @"className" : @"Yarr",
                                                   @"objectId" : @"b" } ]];
    XCTAssertNotNil(decoded);

    PFObject *knownObject = decoded[0];
    XCTAssertEqual(knownObject, objects[@"a"]);

    PFObject *object = decoded[1];
    XCTAssertNotEqual(knownObject, object);
    XCTAssertEqualObjects(object.objectId, @"b");
}

@end
