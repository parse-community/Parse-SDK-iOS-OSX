/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Darwin.libkern.OSAtomic;

#import "PFBaseState.h"
#import "PFTestCase.h"

@interface PFTestBaseStateSubclass : PFBaseState <PFBaseStateSubclass> {
@public
    __unsafe_unretained id _assignValue;
}

@property (nonatomic, readwrite, strong) id defaultValue;

@property (nonatomic, readwrite, unsafe_unretained) id assignValue;
@property (nonatomic, readwrite, weak) id weakValue;
@property (nonatomic, readwrite, strong) id strongValue;
@property (nonatomic, readwrite, copy) id copyValue NS_RETURNS_NOT_RETAINED;
@property (nonatomic, readwrite, copy) id mutableCopyValue NS_RETURNS_NOT_RETAINED;

@end

@implementation PFTestBaseStateSubclass

- (id)init {
    self = [super init];
    if (!self) return nil;

    _defaultValue = @"Hello, World!";

    return self;
}

+ (NSDictionary *)propertyAttributes {
    return @{
             @"defaultValue" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],

             @"assignValue" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeAssign],
             @"weakValue" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeWeak],
             @"strongValue" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeStrong],
             @"copyValue" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
             @"mutableCopyValue" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeMutableCopy],
             };
}

- (id)nilValueForProperty:(NSString *)propertyName {
    return nil;
}

@end

@interface BaseStateTests : PFTestCase

@end

@implementation BaseStateTests

///--------------------------------------
#pragma mark - Association Types
///--------------------------------------

- (void)testDefaultValues {
    PFTestBaseStateSubclass *state = [[PFTestBaseStateSubclass alloc] init];
    XCTAssertEqualObjects(state.defaultValue, @"Hello, World!");

    state.defaultValue = @"Different String";

    PFTestBaseStateSubclass *newState = [PFTestBaseStateSubclass stateWithState:state];
    XCTAssertNotEqualObjects(newState.defaultValue, @"Hello, World!");
}

- (void)testAssignValue {
    // Some random value. Don't treat this as an actual object!
    __unsafe_unretained id theValue = (__bridge id)(void *)0xDEADBEEF;

    PFTestBaseStateSubclass *state = [[PFTestBaseStateSubclass alloc] init];
    state.assignValue = theValue;

    PFTestBaseStateSubclass *newState = [[PFTestBaseStateSubclass alloc] initWithState:state];

    // Cannot use dot-syntax here. ARC is dumb and tries to retain it anyway.
    __unsafe_unretained id valueA = state->_assignValue;
    __unsafe_unretained id valueB = newState->_assignValue;

    XCTAssertEqual(valueA, valueB);
    XCTAssertEqual(valueB, theValue);
}

- (void)testWeakValue {
    PFTestBaseStateSubclass *state, *newState;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"

    @autoreleasepool {
        id theValue = [NSObject new];

        state = [[PFTestBaseStateSubclass alloc] init];
        state.weakValue = theValue;

        newState = [[PFTestBaseStateSubclass alloc] initWithState:state];

        XCTAssertEqual(state.weakValue, newState.weakValue);
        XCTAssertEqual(state.weakValue, theValue);

        theValue = nil;
    }

    OSMemoryBarrier();

    XCTAssertEqual(state.weakValue, newState.weakValue);
    XCTAssertEqual(state.weakValue, nil);
#pragma clang diagnostic pop
}

- (void)testStrongValue {
    __weak id weakValue;

    PFTestBaseStateSubclass *state, *newState;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-repeated-use-of-weak"

    @autoreleasepool {
        id theValue = [NSObject new];
        weakValue = theValue;

        state = [[PFTestBaseStateSubclass alloc] init];
        state.strongValue = theValue;

        newState = [[PFTestBaseStateSubclass alloc] initWithState:state];

        XCTAssertEqual(state.strongValue, newState.strongValue);
        XCTAssertEqual(state.strongValue, theValue);
    }

    OSMemoryBarrier();

    XCTAssertNotNil(weakValue);
    XCTAssertEqual(state.strongValue, newState.strongValue);
    XCTAssertEqual(state.strongValue, weakValue);
#pragma clang diagnostic pop
}

- (void)testCopyValue {
    NSMutableString *originalValue = [NSMutableString stringWithFormat:@"Foo"];

    PFTestBaseStateSubclass *state, *newState;

    state = [[PFTestBaseStateSubclass alloc] init];
    state.copyValue = originalValue;

    newState = [[PFTestBaseStateSubclass alloc] initWithState:state];

    XCTAssertNotEqual(state.copyValue, originalValue);

    // Copying a NSMutableString gives a NSString, which when copied again returns itself.
    XCTAssertEqual(state.copyValue, newState.copyValue);

    XCTAssertEqualObjects(state.copyValue, originalValue);
    XCTAssertEqualObjects(state.copyValue, newState.copyValue);

    // Same reason as above.
    XCTAssertEqual([state.copyValue copy], [state.copyValue copy]);
    XCTAssertEqual([newState.copyValue copy], [newState.copyValue copy]);
}

- (void)testMutableCopyValue {
    NSString *originalValue = @"Bar";

    PFTestBaseStateSubclass *state, *newState;

    state = [[PFTestBaseStateSubclass alloc] init];
    state.mutableCopyValue = originalValue;

    newState = [[PFTestBaseStateSubclass alloc] initWithState:state];

    XCTAssertNotEqual(state.mutableCopyValue, newState.mutableCopyValue);

    // Default copy setters won't invoke -mutableCopy.
    XCTAssertEqual(originalValue, state.mutableCopyValue);

    XCTAssertEqualObjects(state.mutableCopyValue, newState.mutableCopyValue);
    XCTAssertEqualObjects(state.mutableCopyValue, originalValue);

    XCTAssertThrows([state.mutableCopyValue appendString:@"Foo"]);
    XCTAssertNoThrow([newState.mutableCopyValue appendString:@"Foo"]);
}

///--------------------------------------
#pragma mark - Description
///--------------------------------------

- (void)testDescription {
    PFTestBaseStateSubclass *state = [[PFTestBaseStateSubclass alloc] init];
    state.strongValue = @15;

    NSString *oldDescription = [state description];

    state.strongValue = @25;

    NSString *newDescritption = [state description];

    XCTAssertNotEqualObjects(oldDescription, newDescritption);
}

- (void)testDebugDescription {
    PFTestBaseStateSubclass *state = [[PFTestBaseStateSubclass alloc] init];
    state.strongValue = @[ @1, @2, @3 ];

    XCTAssertNotEqualObjects([state description], [state debugDescription]);
}

///--------------------------------------
#pragma mark - Dictionary Representation
///--------------------------------------

- (void)testDictionaryRepresentation {
    PFTestBaseStateSubclass *state = [[PFTestBaseStateSubclass alloc] init];

    NSMutableDictionary *expected = [@{
        @"defaultValue" : @"Hello, World!",
    } mutableCopy];

    XCTAssertEqualObjects(expected, [state dictionaryRepresentation]);

    state.strongValue = @25;
    expected[@"strongValue"] = @25;

    XCTAssertEqualObjects(expected, [state dictionaryRepresentation]);
}

// As this is a method only used when debugging, this simple of a test case should suffice.
- (void)testDebugQuickLookObject {
    PFTestBaseStateSubclass *state = [[PFTestBaseStateSubclass alloc] init];

    XCTAssertEqualObjects([[state dictionaryRepresentation] description], [state debugQuickLookObject]);
}


///--------------------------------------
#pragma mark - Equality
///--------------------------------------

- (void)testEquality {
    PFTestBaseStateSubclass *state1, *state2;

    state1 = [[PFTestBaseStateSubclass alloc] init];
    state2 = [[PFTestBaseStateSubclass alloc] init];

    // Reasoning: XCTAssertEqualObjects checks for pointers for us already, so we dont' get 100% coverage without this.
    XCTAssertTrue([state1 isEqual:state1]);
    XCTAssertEqualObjects(state1, state2);

    XCTAssertNotEqualObjects(state1, nil);
    XCTAssertNotEqualObjects(state1, @"Hello, World!");

    state1.strongValue = @25;

    XCTAssertNotEqualObjects(state1, state2);

    state2.strongValue = @25;

    XCTAssertEqualObjects(state1, state2);
}

///--------------------------------------
#pragma mark - Comparison
///--------------------------------------

- (void)testCompare {
    PFTestBaseStateSubclass *state1, *state2;

    state1 = [[PFTestBaseStateSubclass alloc] init];
    state2 = [[PFTestBaseStateSubclass alloc] init];

    XCTAssertEqual([state1 compare:state2], NSOrderedSame);

    state1.strongValue = @25;
    state2.strongValue = @20;

    XCTAssertEqual([state1 compare:state2], NSOrderedDescending);
    XCTAssertEqual([state2 compare:state1], NSOrderedAscending);

    state2.strongValue = @30;

    XCTAssertEqual([state1 compare:state2], NSOrderedAscending);
    XCTAssertEqual([state2 compare:state1], NSOrderedDescending);
}

///--------------------------------------
#pragma mark - Hashing
///--------------------------------------

- (void)testHash {
    PFTestBaseStateSubclass *state = [[PFTestBaseStateSubclass alloc] init];
    NSUInteger oldHash = [state hash];

    state.strongValue = @25;

    XCTAssertNotEqual(oldHash, [state hash]);
}

@end
