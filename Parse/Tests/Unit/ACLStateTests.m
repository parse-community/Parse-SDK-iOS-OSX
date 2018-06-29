/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFACLState.h"
#import "PFMutableACLState.h"
#import "PFTestCase.h"

@interface ACLStateTests : PFTestCase

@end

@implementation ACLStateTests

- (void)testConstructors {
    PFACLState *state = [[PFACLState alloc] init];
    XCTAssertEqualObjects(state.permissions, @{ });
    XCTAssertFalse(state.shared);

    PFMutableACLState *mutableState = [[PFMutableACLState alloc] init];
    mutableState.permissions[@"key"] = @"value";
    mutableState.shared = YES;

    state = [[PFACLState alloc] initWithState:mutableState];
    XCTAssertEqualObjects(state.permissions, @{ @"key": @"value" });
    XCTAssertTrue(state.shared);

    state = [PFACLState stateWithState:mutableState];
    XCTAssertEqualObjects(state.permissions, @{ @"key": @"value" });
    XCTAssertTrue(state.shared);

    state = [[PFACLState alloc] initWithState:[PFACLState new] mutatingBlock:^(PFMutableACLState *toMutate) {
        toMutate.permissions[@"key"] = @"value";
        toMutate.shared = YES;
    }];
    XCTAssertEqualObjects(state.permissions, @{ @"key": @"value" });
    XCTAssertTrue(state.shared);

    state = [PFACLState stateWithState:[PFACLState new] mutatingBlock:^(PFMutableACLState *toMutate) {
        toMutate.permissions[@"key"] = @"value";
        toMutate.shared = YES;
    }];
    XCTAssertEqualObjects(state.permissions, @{ @"key": @"value" });
    XCTAssertTrue(state.shared);
}

- (void)testCopy {
    PFMutableACLState *toCopy = [[PFMutableACLState alloc] init];
    toCopy.permissions[@"key"] = @"value";

    PFACLState *newState = [toCopy copy];
    XCTAssertEqualObjects(toCopy, newState);
    XCTAssertFalse([newState isKindOfClass:[PFMutableACLState class]]);

    newState = [toCopy mutableCopy];
    XCTAssertEqualObjects(toCopy, newState);
    XCTAssertTrue([newState isKindOfClass:[PFMutableACLState class]]);

    newState = [toCopy copyByMutatingWithBlock:^(PFMutableACLState *newState) {
        newState.shared = YES;
    }];

    XCTAssertEqualObjects(newState.permissions, toCopy.permissions);
    XCTAssertTrue(newState.shared);
}

@end
