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
#import "PFOperationSet.h"
#import "PFTestCase.h"

@interface OperationSetUnitTests : PFTestCase

@end

@implementation OperationSetUnitTests

- (PFOperationSet *)makeTestOperationSet {
    PFOperationSet *result = [[PFOperationSet alloc] init];
    result[@"witch"] = [PFSetOperation setWithValue:@"doctor"];
    result[@"something"] = [[PFDeleteOperation alloc] init];
    result.saveEventually = YES;
    return result;
}

- (void)testMergeOperationSet {
    PFOperationSet *operation1 = [[PFOperationSet alloc] init];
    PFOperationSet *operation2 = [self makeTestOperationSet];

    // Check if we can override existing object
    operation1[@"witch"] = [[PFDeleteOperation alloc] init];
    // Check if previous objects still exist when merged
    operation1[@"bar"] = [PFSetOperation setWithValue:@"foo"];

    // MERGE!! *insert awesome BGM here*
    [operation1 mergeOperationSet:operation2];

    // Should be merged with operation2
    PFAssertIsKindOfClass(operation1[@"witch"], PFDeleteOperation);

    // Should exist from operation1
    PFAssertIsKindOfClass(operation1[@"bar"], PFSetOperation);

    // Should exist from operation2
    PFAssertIsKindOfClass(operation1[@"something"], PFDeleteOperation);
}

- (void)testOperationSetWithREST {
    PFOperationSet *operation1 = [self makeTestOperationSet];
    // Use default PFEncoding
    NSArray *operationSetUUIDs = nil;
    NSDictionary *restified = [operation1 RESTDictionaryUsingObjectEncoder:[PFPointerObjectEncoder objectEncoder]
                                                         operationSetUUIDs:&operationSetUUIDs];
    // Check returned operationSetUUIDs
    XCTAssertNotNil(operationSetUUIDs);
    PFAssertEqualInts(1, operationSetUUIDs.count);
    XCTAssertEqualObjects(operation1.uuid, operationSetUUIDs[0]);
    // Use default PFDecoder
    PFOperationSet *operation2 = [PFOperationSet operationSetFromRESTDictionary:restified
                                                                   usingDecoder:[[PFDecoder alloc] init]];

    // Make sure they're equal
    NSEnumerator *keyEnumerator1 = [operation1 keyEnumerator];
    for (id key in keyEnumerator1) {
        PFAssertIsKindOfClass(operation1[key], operation2[key]);
    }
    NSEnumerator *keyEnumerator2 = [operation1 keyEnumerator];
    for (id key in keyEnumerator2) {
        PFAssertIsKindOfClass(operation1[key], operation2[key]);
    }
    XCTAssertEqual(operation1.uuid, operation2.uuid);
    XCTAssertEqual(operation1.saveEventually, operation2.saveEventually);
}

- (void)testGetterAndSetter {
    PFOperationSet *testOp = [[PFOperationSet alloc] init];
    id setOp = [PFSetOperation setWithValue:@"doctor"];
    id deleteOp = [[PFDeleteOperation alloc] init];
    [testOp setObject:setOp forKey:@"witch"];
    testOp[@"something"] = deleteOp;

    XCTAssertEqual(setOp, [testOp objectForKey:@"witch"]);
    XCTAssertEqual(setOp, testOp[@"witch"]);

    XCTAssertEqual(deleteOp, [testOp objectForKey:@"something"]);
    XCTAssertEqual(deleteOp, testOp[@"something"]);
}

- (void)testRemoveObjectForKey {
    PFOperationSet *operationSet = [[PFOperationSet alloc] init];

    PFFieldOperation *operation = [PFSetOperation setWithValue:@"yolo"];
    operationSet[@"yarr"] = operation;

    XCTAssertEqual(operationSet[@"yarr"], operation);

    NSDate *date = operationSet.updatedAt;
    [operationSet removeObjectForKey:@"yarr"];
    XCTAssertNil(operationSet[@"yarr"]);
    XCTAssertNotEqualObjects(date, operationSet.updatedAt);
}

- (void)testRemoveAllObjects {
    PFOperationSet *operationSet = [[PFOperationSet alloc] init];

    operationSet[@"yarr"] = [PFSetOperation setWithValue:@"a"];
    operationSet[@"yolo"] = [PFAddOperation addWithObjects:@[ @"b" ]];

    XCTAssertNotNil(operationSet[@"yarr"]);
    XCTAssertNotNil(operationSet[@"yolo"]);
    XCTAssertEqual(operationSet.count, 2);

    NSDate *date = operationSet.updatedAt;
    [operationSet removeAllObjects];
    XCTAssertNil(operationSet[@"yarr"]);
    XCTAssertNil(operationSet[@"yolo"]);
    XCTAssertEqual(operationSet.count, 0);
    XCTAssertNotEqualObjects(date, operationSet.updatedAt);
}

- (void)testCopying {
    PFOperationSet *operationSet = [[PFOperationSet alloc] init];
    operationSet[@"yarr"] = [PFSetOperation setWithValue:@"yolo"];

    PFOperationSet *operationSetCopy = [operationSet copy];
    XCTAssertEqualObjects(operationSet.uuid, operationSetCopy.uuid);
    XCTAssertEqualObjects(operationSet.updatedAt, operationSetCopy.updatedAt);
    XCTAssertEqual(operationSet.saveEventually, operationSetCopy.saveEventually);
    XCTAssertEqualObjects(operationSet[@"yarr"], operationSetCopy[@"yarr"]);
}

- (void)testFastEnumeration {
    PFOperationSet *operationSet = [[PFOperationSet alloc] init];
    operationSet[@"yarr1"] = [PFSetOperation setWithValue:@"yolo"];
    operationSet[@"yarr2"] = [PFSetOperation setWithValue:@"yolo"];

    NSMutableArray *keys = [NSMutableArray array];
    for (NSString *key in operationSet) {
        [keys addObject:key];
    }
    XCTAssertEqualObjects(keys, (@[ @"yarr1", @"yarr2" ]));
}

@end
