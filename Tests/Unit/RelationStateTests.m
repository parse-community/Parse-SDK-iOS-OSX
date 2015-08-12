/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMutableRelationState.h"
#import "PFRelationState.h"
#import "PFTestCase.h"

@interface RelationStateTests : PFTestCase

@end

@implementation RelationStateTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFRelationState *)sampleRelationStateWithParent:(PFObject *)parent {
    PFMutableRelationState *state = [[PFMutableRelationState alloc] init];

    state.parent = nil;
    state.key = @"Treasure";
    state.targetClass = @"Ship";

    return [state copy];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testInit {
    PFRelationState *state = [[PFRelationState alloc] init];
    XCTAssertNotNil(state);

    XCTAssertNil(state.parent);
    XCTAssertNil(state.parentObjectId);
    XCTAssertNil(state.parentClassName);
    XCTAssertNil(state.key);
    XCTAssertNil(state.targetClass);
    XCTAssertNotNil(state.knownObjects);

    state = [[PFMutableRelationState alloc] init];
    XCTAssertNotNil(state);

    XCTAssertNil(state.parent);
    XCTAssertNil(state.parentObjectId);
    XCTAssertNil(state.parentClassName);
    XCTAssertNil(state.targetClass);
    XCTAssertNil(state.key);
    XCTAssertNotNil(state.knownObjects);
}

- (void)testInitWithState {
    PFRelationState *sampleState = [self sampleRelationStateWithParent:nil];

    PFRelationState *state = [[PFRelationState alloc] initWithState:sampleState];
    XCTAssertEqualObjects(state, sampleState);

    state = [PFRelationState stateWithState:sampleState];
    XCTAssertEqualObjects(state, sampleState);

    state = [[PFMutableRelationState alloc] initWithState:sampleState];
    XCTAssertEqualObjects(state, sampleState);

    state = [PFMutableRelationState stateWithState:sampleState];
    XCTAssertEqualObjects(state, sampleState);
}

- (void)testCopying {
    PFRelationState *sampleState = [self sampleRelationStateWithParent:nil];
    XCTAssertEqualObjects([sampleState copy], sampleState);

    sampleState = [PFMutableRelationState stateWithState:sampleState];
    XCTAssertEqualObjects([sampleState copy], sampleState);
}

- (void)testMutableCopy {
    PFMutableRelationState *sampleState = [[self sampleRelationStateWithParent:nil] mutableCopy];
    sampleState.knownObjects = [NSMutableSet setWithObjects:@1, nil];

    XCTAssertEqualObjects([sampleState mutableCopy], sampleState);
}

@end
