/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFEncoder.h"
#import "PFFieldOperation.h"
#import "PFMutableObjectState.h"
#import "PFOperationSet.h"
#import "PFTestCase.h"

@interface ObjectStateTests : PFTestCase

@end

@implementation ObjectStateTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFObjectState *)sampleObjectState {
    PFMutableObjectState *state = [PFMutableObjectState stateWithParseClassName:@"Yarr"];
    state.objectId = @"yolo";
    state.complete = YES;
    return state;
}

- (void)assertObjectState:(PFObjectState *)state equalToState:(PFObjectState *)differentState {
    XCTAssertEqualObjects(state.parseClassName, differentState.parseClassName);
    XCTAssertEqualObjects(state.objectId, differentState.objectId);
    XCTAssertEqual(state.complete, differentState.complete);
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testInit {
    PFObjectState *state = [[PFObjectState alloc] init];
    XCTAssertNil(state.parseClassName);
    XCTAssertNil(state.objectId);
    XCTAssertFalse(state.complete);

    state = [[PFMutableObjectState alloc] init];
    XCTAssertNil(state.parseClassName);
    XCTAssertNil(state.objectId);
    XCTAssertFalse(state.complete);
}

- (void)testInitWithParseClassName {
    PFObjectState *state = [[PFObjectState alloc] initWithParseClassName:@"Yarr"];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");

    state = [PFObjectState stateWithParseClassName:@"Yarr"];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");

    state = [[PFMutableObjectState alloc] initWithParseClassName:@"Yarr"];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");

    state = [PFMutableObjectState stateWithParseClassName:@"Yarr"];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");

    state = [PFObjectState stateWithParseClassName:@"Yarr" objectId:@"a" isComplete:YES];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");
    XCTAssertEqualObjects(state.objectId, @"a");
    XCTAssertTrue(state.complete);

    state = [[PFObjectState alloc] initWithParseClassName:@"Yarr" objectId:@"a" isComplete:YES];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");
    XCTAssertEqualObjects(state.objectId, @"a");
    XCTAssertTrue(state.complete);

    state = [PFMutableObjectState stateWithParseClassName:@"Yarr" objectId:@"a" isComplete:YES];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");
    XCTAssertEqualObjects(state.objectId, @"a");
    XCTAssertTrue(state.complete);

    state = [[PFMutableObjectState alloc] initWithParseClassName:@"Yarr" objectId:@"a" isComplete:YES];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");
    XCTAssertEqualObjects(state.objectId, @"a");
    XCTAssertTrue(state.complete);
}

- (void)testInitWithState {
    PFObjectState *sampleState = [self sampleObjectState];

    PFObjectState *state = [[PFObjectState alloc] initWithState:sampleState];
    [self assertObjectState:state equalToState:sampleState];

    state = [PFObjectState stateWithState:sampleState];
    [self assertObjectState:state equalToState:sampleState];

    state = [[PFMutableObjectState alloc] initWithState:sampleState];
    [self assertObjectState:state equalToState:sampleState];

    state = [PFMutableObjectState stateWithState:sampleState];
    [self assertObjectState:state equalToState:sampleState];
}

- (void)testCopying {
    PFObjectState *sampleState = [self sampleObjectState];
    PFObjectState *stateCopy = [sampleState copy];
    XCTAssertNotEqual(sampleState, stateCopy);
    [self assertObjectState:stateCopy equalToState:sampleState];

    PFMutableObjectState *mutableState = [PFMutableObjectState stateWithState:sampleState];
    stateCopy = [mutableState copy];
    XCTAssertNotEqual(mutableState, stateCopy);
    [self assertObjectState:stateCopy equalToState:sampleState];
}

- (void)testMutableCopying {
    PFObjectState *sampleState = [self sampleObjectState];
    PFObjectState *stateCopy = [sampleState mutableCopy];

    XCTAssertNotEqual(sampleState, stateCopy);
    [self assertObjectState:stateCopy equalToState:sampleState];

    PFMutableObjectState *state = [PFMutableObjectState stateWithState:sampleState];
    stateCopy = [state mutableCopy];
    XCTAssertNotEqual(state, stateCopy);
    [self assertObjectState:stateCopy equalToState:sampleState];
}

- (void)testMutableAccessors {
    PFMutableObjectState *mutableState = [[PFMutableObjectState alloc] init];

    mutableState.parseClassName = @"Yolo";
    XCTAssertEqualObjects(mutableState.parseClassName, @"Yolo");

    mutableState.objectId = @"yarr";
    XCTAssertEqualObjects(mutableState.objectId, @"yarr");

    mutableState.complete = YES;
    XCTAssertTrue(mutableState.complete);

    NSString *isoDate = @"1970-01-01T00:00:00Z";
    [mutableState setCreatedAtFromString:isoDate];
    [mutableState setUpdatedAtFromString:isoDate];

    XCTAssertEqualObjects(mutableState.createdAt, [NSDate dateWithTimeIntervalSince1970:0]);
    XCTAssertEqualObjects(mutableState.updatedAt, [NSDate dateWithTimeIntervalSince1970:0]);
}

- (void)testServerData {
    PFMutableObjectState *mutableState = [[PFMutableObjectState alloc] init];
    XCTAssertEqualObjects(mutableState.serverData, @{});

    [mutableState setServerDataObject:@"foo" forKey:@"bar"];
    XCTAssertEqualObjects(mutableState.serverData, @{ @"bar": @"foo" });

    [mutableState removeServerDataObjectForKey:@"bar"];
    XCTAssertEqualObjects(mutableState.serverData, @{});

    [mutableState setServerDataObject:@"foo" forKey:@"bar"];
    [mutableState removeServerDataObjectsForKeys:@[ @"bar" ]];

    XCTAssertEqualObjects(mutableState.serverData, @{});
    mutableState.serverData = @{ @"foo": @"bar" };

    XCTAssertEqualObjects(mutableState.serverData, @{ @"foo": @"bar" });
}

- (void)testEncode {
    PFMutableObjectState *mutableState = [[PFMutableObjectState alloc] init];
    mutableState.objectId = @"objectId";
    mutableState.createdAt = [NSDate dateWithTimeIntervalSince1970:0];
    mutableState.updatedAt = [NSDate dateWithTimeIntervalSince1970:5];
    mutableState.serverData = @{ @"a": @"b" };

    NSDictionary *expected = @{
        @"objectId": @"objectId",
        @"createdAt": @"1970-01-01T00:00:00.000Z",
        @"updatedAt": @"1970-01-01T00:00:05.000Z",
        @"a": @"b"
    };

    NSDictionary *actual = [mutableState dictionaryRepresentationWithObjectEncoder:[PFEncoder objectEncoder]];
    XCTAssertEqualObjects(actual, expected);
}

- (void)testApply {
    PFMutableObjectState *objectState = [[PFMutableObjectState alloc] init];
    objectState.objectId = @"betterObjectId";
    objectState.createdAt = [NSDate dateWithTimeIntervalSince1970:17];
    objectState.updatedAt = [NSDate dateWithTimeIntervalSince1970:25];
    objectState.serverData = @{ @"a": @"b", @"c": @"d" };

    PFMutableObjectState *secondState = [[PFMutableObjectState alloc] init];
    secondState.objectId = @"anObjectId";
    secondState.serverData = @{ @"a": @"d", @"e": @"f" };

    [secondState applyState:objectState];

    XCTAssertEqualObjects(secondState.objectId, @"betterObjectId");
    XCTAssertEqualObjects(secondState.createdAt, [NSDate dateWithTimeIntervalSince1970:17]);
    XCTAssertEqualObjects(secondState.updatedAt, [NSDate dateWithTimeIntervalSince1970:25]);
    XCTAssertEqualObjects(secondState.serverData, (@{ @"a": @"b", @"c": @"d", @"e": @"f" }));
}

- (void)testApplyOperation {
    PFMutableObjectState *objectState = [[PFMutableObjectState alloc] init];
    objectState.serverData = @{
       @"a": @13,
       @"b": @"someValue",
       @"c": @15
    };

    PFOperationSet *operationSet = [[PFOperationSet alloc] init];
    operationSet[@"a"] = [[PFIncrementOperation alloc] initWithAmount:@10];
    operationSet[@"b"] = [[PFDeleteOperation alloc] init];
    operationSet[@"c"] = [[PFSetOperation alloc] initWithValue:@25];

    [objectState applyOperationSet:operationSet];
    XCTAssertEqualObjects(objectState.serverData, (@{ @"a": @23, @"c": @25 }));
}

@end
