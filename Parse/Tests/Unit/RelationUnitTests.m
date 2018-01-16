/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

@import Darwin.libkern.OSAtomic;

#import "PFDecoder.h"
#import "PFQueryPrivate.h"
#import "PFRelation.h"
#import "PFRelationPrivate.h"
#import "PFUnitTestCase.h"

@interface RelationUnitTests : PFUnitTestCase

@end

@implementation RelationUnitTests

- (void)testConstructors {
    PFRelation *relation = [[PFRelation alloc] init];
    XCTAssertNotNil(relation);
    XCTAssertNil(relation.targetClass);

    id mockedObject = PFStrictClassMock([PFObject class]);
    OCMStub([mockedObject parseClassName]).andReturn(@"SomeClass");
    OCMStub([mockedObject objectId]).andReturn(@"objectId");

    relation = [PFRelation relationForObject:mockedObject forKey:@"key"];

    XCTAssertNotNil(relation);
    XCTAssertNil(relation.targetClass);

    XCTAssertNoThrow([relation ensureParentIs:mockedObject andKeyIs:@"key"]);

    relation = [PFRelation relationWithTargetClass:@"targetClass"];
    XCTAssertNotNil(relation);
    XCTAssertEqualObjects(relation.targetClass, @"targetClass");
}

- (void)testQuery {
    PFRelation *testRelation = nil;

    @autoreleasepool {
        PFObject *parentObject = [[PFObject alloc] initWithClassName:@"SomeClass"];
        parentObject.objectId = @"objectId";

        testRelation = [PFRelation relationForObject:parentObject forKey:@"aKey"];
        testRelation.targetClass = @"TargetClass";

        PFQuery *query = testRelation.query;
        PFQuery *expectedQuery = [PFQuery queryWithClassName:@"TargetClass"];
        [expectedQuery whereRelatedToObject:parentObject fromKey:@"aKey"];

        XCTAssertEqualObjects(expectedQuery.state, query.state);

        query = nil;
        expectedQuery = nil;
        parentObject = nil;
    }

    OSMemoryBarrier();

    @autoreleasepool {
        PFQuery *query = testRelation.query;

        XCTAssertEqualObjects(query.state.conditions[@"$relatedTo"][@"key"], @"aKey");
        XCTAssertEqualObjects([query.state.conditions[@"$relatedTo"][@"object"] parseClassName], @"SomeClass");
        XCTAssertEqualObjects([query.state.conditions[@"$relatedTo"][@"object"] objectId], @"objectId");

        testRelation.targetClass = nil;
        query = testRelation.query;

        XCTAssertEqualObjects(query.state.conditions[@"$relatedTo"][@"key"], @"aKey");
        XCTAssertEqualObjects([query.state.conditions[@"$relatedTo"][@"object"] parseClassName], @"SomeClass");
        XCTAssertEqualObjects([query.state.conditions[@"$relatedTo"][@"object"] objectId], @"objectId");;
    }
}

- (void)testAddObject {
    PFRelation *relation = [PFRelation relationWithTargetClass:@"TargetClass"];

    id mockedObject = PFClassMock([PFObject class]);
    OCMStub([mockedObject parseClassName]).andReturn(@"TargetClass");

    [relation addObject:mockedObject];

    XCTAssertTrue([relation _hasKnownObject:mockedObject]);
}

- (void)testRemoveObject {
    PFRelation *relation = [PFRelation relationWithTargetClass:@"TargetClass"];

    id mockedObject = PFClassMock([PFObject class]);
    OCMStub([mockedObject parseClassName]).andReturn(@"TargetClass");

    [relation addObject:mockedObject];
    [relation removeObject:mockedObject];

    XCTAssertFalse([relation _hasKnownObject:mockedObject]);
}

- (void)testKnownObjects {
    PFRelation *relation = [[PFRelation alloc] init];

    id mockedObject1 = PFStrictClassMock([PFObject class]);
    id mockedObject2 = PFStrictClassMock([PFObject class]);

    OCMStub([mockedObject1 parseClassName]).andReturn(@"TargetClass1");
    OCMStub([mockedObject2 parseClassName]).andReturn(@"TargetClass2");

    [relation addObject:mockedObject1];

    XCTAssertTrue([relation _hasKnownObject:mockedObject1]);
    XCTAssertFalse([relation _hasKnownObject:mockedObject2]);

    XCTAssertEqualObjects(relation.targetClass, @"TargetClass1");

    [relation _addKnownObject:mockedObject2];
    [relation _removeKnownObject:mockedObject1];

    XCTAssertFalse([relation _hasKnownObject:mockedObject1]);
    XCTAssertTrue([relation _hasKnownObject:mockedObject2]);

    XCTAssertEqualObjects(relation.targetClass, @"TargetClass1");
}

- (void)testEncode {
    id mockedObject = PFStrictClassMock([PFObject class]);
    OCMStub([mockedObject parseClassName]).andReturn(@"SomeClass");
    OCMStub([mockedObject objectId]).andReturn(@"objectId");

    PFRelation *relation = [[PFRelation alloc] init];
    relation.targetClass = @"TargetClass";

    [relation _addKnownObject:mockedObject];

    NSDictionary *encoded = [relation encodeIntoDictionary];
    XCTAssertEqual(1, [encoded[@"objects"] count]);
    XCTAssertNotNil(encoded);
}

- (void)testDecode {
    NSDictionary *toDecode = @{
        @"__type": @"Relation",
        @"className": @"TargetClass",
            @"objects":
            @[
                @{
                    @"__type": @"Pointer",
                    @"className": @"SomeClass",
                    @"objectId": @"objectId",
                }
            ]
        };

    PFRelation *decoded = [PFRelation relationFromDictionary:toDecode withDecoder:[PFDecoder objectDecoder]];
    XCTAssertEqualObjects(decoded.targetClass, @"TargetClass");
}

- (void)testDescription {
    PFRelation *relation = [[PFRelation alloc] init];
    relation.targetClass = @"SomeClass";

    XCTAssertTrue([relation.description rangeOfString:@"SomeClass"].location != NSNotFound);
}

@end
