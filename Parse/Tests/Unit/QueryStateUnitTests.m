/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMacros.h"
#import "PFMutableQueryState.h"
#import "PFTestCase.h"

@interface QueryStateUnitTests : PFTestCase

@end

@implementation QueryStateUnitTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFQueryState *)sampleQueryState {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];
    state.limit = 100;
    state.skip = 200;
    state.cachePolicy = kPFCachePolicyCacheOnly;
    state.maxCacheAge = 100500.0;
    state.trace = YES;
    state.shouldIgnoreACLs = YES;
    state.shouldIncludeDeletingEventually = YES;
    state.queriesLocalDatastore = YES;
    state.localDatastorePinName = @"Yolo!";

    [state setEqualityConditionWithObject:@"a" forKey:@"b"];
    [state setRelationConditionWithObject:@"c" forKey:@"d"];

    [state sortByKey:@"a" ascending:NO];

    [state includeKey:@"yolo"];
    [state selectKeys:@[ @"yolo" ]];
    [state redirectClassNameForKey:@"ABC"];
    return state;
}

- (void)assertQueryState:(PFQueryState *)state equalToState:(PFQueryState *)differentState {
    XCTAssertEqualObjects(state, differentState);
    XCTAssertEqualObjects(state.parseClassName, differentState.parseClassName);

    XCTAssertEqual(state.limit, differentState.limit);
    XCTAssertEqual(state.skip, differentState.skip);
    XCTAssertEqual(state.cachePolicy, differentState.trace);
    XCTAssertEqual(state.trace, differentState.trace);
    XCTAssertEqual(state.shouldIgnoreACLs, differentState.shouldIgnoreACLs);
    XCTAssertEqual(state.shouldIncludeDeletingEventually, differentState.shouldIncludeDeletingEventually);
    XCTAssertEqual(state.queriesLocalDatastore, differentState.queriesLocalDatastore);

    XCTAssertEqualObjects(state.conditions, differentState.conditions);
    XCTAssertEqualObjects(state.sortKeys, differentState.sortKeys);
    XCTAssertEqualObjects(state.sortOrderString, differentState.sortOrderString);
    XCTAssertEqualObjects(state.includedKeys, differentState.includedKeys);
    XCTAssertEqualObjects(state.selectedKeys, differentState.selectedKeys);
    XCTAssertEqualObjects(state.extraOptions, differentState.extraOptions);

    XCTAssertEqualObjects(state.localDatastorePinName, differentState.localDatastorePinName);
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testDefaultValues {
    PFQueryState *state = [[PFQueryState alloc] init];
    XCTAssertEqual(state.cachePolicy, kPFCachePolicyIgnoreCache);
    XCTAssertEqual(state.maxCacheAge, INFINITY);
    XCTAssertEqual(state.limit, -1);

    state = [[PFMutableQueryState alloc] init];
    XCTAssertEqual(state.cachePolicy, kPFCachePolicyIgnoreCache);
    XCTAssertEqual(state.maxCacheAge, INFINITY);
    XCTAssertEqual(state.limit, -1);
}

- (void)testInitWithState {
    PFQueryState *sampleState = [self sampleQueryState];
    PFQueryState *state = [[PFQueryState alloc] initWithState:sampleState];
    [self assertQueryState:state equalToState:sampleState];

    state = [[PFMutableQueryState alloc] initWithState:sampleState];
    [self assertQueryState:state equalToState:sampleState];

    state = [PFQueryState stateWithState:sampleState];
    [self assertQueryState:state equalToState:sampleState];

    state = [PFMutableQueryState stateWithState:sampleState];
    [self assertQueryState:state equalToState:sampleState];
}

- (void)testInitWithClassName {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");

    state = [PFMutableQueryState stateWithParseClassName:@"Yarr"];
    XCTAssertEqualObjects(state.parseClassName, @"Yarr");
}

- (void)testCopying {
    PFQueryState *sampleState = [self sampleQueryState];
    PFQueryState *state = [sampleState copy];

    XCTAssertFalse([state isKindOfClass:[PFMutableQueryState class]]);
    [self assertQueryState:state equalToState:sampleState];
}

- (void)testMutableCopying {
    PFQueryState *sampleState = [self sampleQueryState];
    PFMutableQueryState *state = [sampleState mutableCopy];

    XCTAssert([state isKindOfClass:[PFMutableQueryState class]]);
    [self assertQueryState:state equalToState:sampleState];
}

- (void)testGenericConditions {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];
    [state setConditionType:@"$yolo" withObject:@"a" forKey:@"yarr"];

    XCTAssertEqualObjects(state.conditions[@"yarr"][@"$yolo"], @"a");
}

- (void)testEqualityConditions {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];
    [state setEqualityConditionWithObject:@"a" forKey:@"yarr"];

    XCTAssertEqualObjects(state.conditions[@"yarr"], @"a");
}

- (void)testRelationConditions {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];
    [state setRelationConditionWithObject:@"a" forKey:@"yarr"];

    XCTAssertEqualObjects(state.conditions[@"$relatedTo"][@"object"], @"a");
    XCTAssertEqualObjects(state.conditions[@"$relatedTo"][@"key"], @"yarr");
}

- (void)testRemoveConditions {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];
    [state setEqualityConditionWithObject:@"a" forKey:@"b"];
    XCTAssertEqual(state.conditions.count, 1);

    [state removeAllConditions];
    XCTAssertEqual(state.conditions.count, 0);
}

- (void)testSortByKey {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];

    [state sortByKey:@"a" ascending:YES];
    XCTAssertEqualObjects(state.sortKeys, @[ @"a" ]);

    [state sortByKey:@"b" ascending:NO];
    XCTAssertEqualObjects(state.sortKeys, @[ @"-b" ]);
}

- (void)testAddSortKey {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];

    [state addSortKey:@"a" ascending:YES];
    XCTAssertEqualObjects(state.sortKeys, @[ @"a" ]);

    [state addSortKey:@"b" ascending:NO];

    NSArray *sortKeys = @[ @"a", @"-b" ];
    XCTAssertEqualObjects(state.sortKeys, sortKeys);

    [state addSortKey:nil ascending:YES];
    XCTAssertEqualObjects(state.sortKeys, sortKeys);

    [state addSortKey:nil ascending:NO];
    XCTAssertEqualObjects(state.sortKeys, sortKeys);
}

- (void)testAddSortKeysFromDescriptors {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];

    NSArray *sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"a" ascending:YES],
                                  [NSSortDescriptor sortDescriptorWithKey:@"b" ascending:NO] ];
    [state addSortKeysFromSortDescriptors:sortDescriptors];

    NSArray *sortKeys = @[ @"a", @"-b" ];
    XCTAssertEqualObjects(state.sortKeys, sortKeys);
}

- (void)testIncludeKeys {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];
    [state includeKey:@"a"];
    [state includeKey:@"b"];

    NSSet *includedKeys = PF_SET(@"a", @"b");
    XCTAssertEqualObjects(state.includedKeys, includedKeys);
}

- (void)testIncludeMultipleKeys {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];
    [state includeKeys:@[ @"a", @"b", @"c" ]];
    [state includeKey:@"a"];

    NSSet *includedKeys = PF_SET(@"a", @"b", @"c");
    XCTAssertEqualObjects(state.includedKeys, includedKeys);
}

- (void)testSelectKeys {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];

    NSArray *selectedKeys = @[ @"a", @"b" ];
    [state selectKeys:selectedKeys];
    XCTAssertEqualObjects(state.selectedKeys, [NSSet setWithArray:selectedKeys]);

    [state selectKeys:@[]];
    XCTAssertEqualObjects(state.selectedKeys, [NSSet setWithArray:selectedKeys]);

    [state selectKeys:nil];
    XCTAssertNil(state.selectedKeys);
}

- (void)testRedirectClassName {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];

    [state redirectClassNameForKey:@"yolo"];
    XCTAssertEqualObjects(state.extraOptions, @{ @"redirectClassNameForKey" : @"yolo" });
}

- (void)testDebugQuickLookObject {
    PFMutableQueryState *state = [[PFMutableQueryState alloc] initWithParseClassName:@"Yarr"];
    id quickLookObject = [state debugQuickLookObject];

    XCTAssertNotNil(quickLookObject);
    XCTAssertEqualObjects(quickLookObject, [[state dictionaryRepresentation] description]);
}

@end
