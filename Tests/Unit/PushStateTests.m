/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMutablePushState.h"
#import "PFQueryState.h"
#import "PFTestCase.h"
#import "PFAssert.h"

@interface PushStateTests : PFTestCase

@end

@implementation PushStateTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFPushState *)samplePushState {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];
    state.channels = [NSSet setWithObject:@"yolo"];
    state.queryState = [[PFQueryState alloc] init];
    state.expirationDate = [NSDate date];
    state.expirationTimeInterval = @1.0;
    state.pushDate = [NSDate dateWithTimeIntervalSinceNow:120];
    state.payload = @{ @"alert" : @"yarr" };
    return [state copy];
}

- (void)assertPushState:(PFPushState *)state equalToState:(PFPushState *)differentState {
    XCTAssertEqualObjects(state.channels, differentState.channels);
    XCTAssertEqualObjects(state.queryState, differentState.queryState);
    XCTAssertEqualObjects(state.expirationDate, differentState.expirationDate);
    XCTAssertEqualObjects(state.expirationTimeInterval, differentState.expirationTimeInterval);
    XCTAssertEqualObjects(state.pushDate, differentState.pushDate);
    XCTAssertEqualObjects(state.payload, differentState.payload);
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testInit {
    PFPushState *state = [[PFPushState alloc] init];
    XCTAssertNotNil(state);
    XCTAssertNil(state.channels);
    XCTAssertNil(state.queryState);
    XCTAssertNil(state.expirationDate);
    XCTAssertNil(state.expirationTimeInterval);
    XCTAssertNil(state.pushDate);

    state = [[PFMutablePushState alloc] init];
    XCTAssertNotNil(state);
    XCTAssertNil(state.channels);
    XCTAssertNil(state.queryState);
    XCTAssertNil(state.expirationDate);
    XCTAssertNil(state.expirationTimeInterval);
    XCTAssertNil(state.pushDate);
}

- (void)testInitWithState {
    PFPushState *sampleState = [self samplePushState];

    PFPushState *state = [[PFPushState alloc] initWithState:sampleState];
    [self assertPushState:state equalToState:sampleState];

    state = [PFPushState stateWithState:sampleState];
    [self assertPushState:state equalToState:sampleState];

    state = [[PFMutablePushState alloc] initWithState:sampleState];
    [self assertPushState:state equalToState:sampleState];

    state = [PFMutablePushState stateWithState:sampleState];
    [self assertPushState:state equalToState:sampleState];
}

- (void)testCopying {
    PFPushState *sampleState = [self samplePushState];
    [self assertPushState:[sampleState copy] equalToState:sampleState];

    sampleState = [[PFMutablePushState alloc] initWithState:sampleState];
    [self assertPushState:[sampleState copy] equalToState:sampleState];
}

- (void)testMutableCopying {
    PFMutablePushState *state = [[self samplePushState] mutableCopy];
    state.payload = @{ @"abc" : @"def" };
    XCTAssertEqualObjects(state.payload, @{ @"abc" : @"def" });
}

- (void)testMutableAccessors {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];

    NSSet *channels = [NSMutableSet setWithObject:@"yarr"];
    state.channels = channels;
    XCTAssertNotEqual(state.channels, channels);
    XCTAssertEqualObjects(state.channels, channels);

    PFQueryState *queryState = [[PFQueryState alloc] init];
    state.queryState = queryState;
    XCTAssertNotEqual(state.queryState, queryState);
    XCTAssertEqualObjects(state.queryState, queryState);

    state.expirationDate = [NSDate dateWithTimeIntervalSince1970:100500];
    XCTAssertEqualObjects(state.expirationDate, [NSDate dateWithTimeIntervalSince1970:100500]);

    state.expirationTimeInterval = @100500.0;
    XCTAssertEqualObjects(state.expirationTimeInterval, @100500.0);

    NSDictionary *payload = [@{ @"a" : @"b" } mutableCopy];
    state.payload = payload;
    XCTAssertNotEqual(state.payload, payload);
    XCTAssertEqualObjects(state.payload, payload);
}

- (void)testSetPayloadWithMessage {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];
    [state setPayloadWithMessage:@"yolo"];
    XCTAssertEqualObjects(state.payload, @{ @"alert" : @"yolo" });

    [state setPayloadWithMessage:nil];
    XCTAssertNil(state.payload);
}

- (void)testSetPushTimeValidation {
    PFMutablePushState *state = [[PFMutablePushState alloc] init];
    PFAssertThrowsInvalidArgumentException(state.pushDate = [NSDate distantPast]);
    PFAssertThrowsInvalidArgumentException(state.pushDate = [NSDate distantFuture]);
    
    NSDate *slightlyPast = [NSDate dateWithTimeIntervalSinceNow:-1];
    PFAssertThrowsInvalidArgumentException(state.pushDate = slightlyPast);
    
    NSDateComponents *toAdd = [[NSDateComponents alloc] init];
    toAdd.day = 13;
    NSDate *withinTwoWeeks = [[NSCalendar currentCalendar] dateByAddingComponents:toAdd toDate:[NSDate date] options:0];
    XCTAssertNoThrow(state.pushDate = withinTwoWeeks);
    toAdd.day = 14;
    toAdd.minute = 1;
    NSDate *beyondTwoWeeks = [[NSCalendar currentCalendar] dateByAddingComponents:toAdd toDate:[NSDate date] options:0];
    PFAssertThrowsInvalidArgumentException(state.pushDate = beyondTwoWeeks);
}

@end
