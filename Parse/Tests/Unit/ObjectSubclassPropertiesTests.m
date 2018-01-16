/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObject+Subclass.h"
#import "PFObjectPrivate.h"
#import "PFRelation.h"
#import "PFSubclassing.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

// A test class used to verify that dynamic sythesizers work for properties of the
// object and ivars with copy and retain semantics. Properties that are NSNumbers
// should also support accessors and mutators which automatically unbox the value into
// its corresponding primitive.
@interface PFTestObject : PFObject<PFSubclassing> {
@public
    id ivarId;
    int ivarInt;
    bool ivarCXXBool;
    unsigned short ivarShort;
    BOOL usedNativeAccessor;
    BOOL usedNativeMutator;
}

@property (atomic, retain) id idProperty;
@property (atomic, copy) NSString *stringCopyProperty;
@property (atomic, assign) short shortProperty;
@property (atomic, assign) unsigned short ushortProperty;
@property (atomic, assign) int intProperty;
@property (atomic, assign) uint uintProperty;
@property (atomic, assign) long longProperty;
@property (atomic, assign) unsigned long ulongProperty;
@property (atomic, assign) BOOL boolProperty;
@property (atomic, retain) id ivarId;
@property (atomic, assign) int ivarInt;
@property (atomic, assign) unsigned short ivarShort;
@property (atomic, copy) NSString *stringWithNativeAccessor;
@property (atomic, copy) NSString *stringWithNativeMutator;
@property (atomic, assign) float floatProperty;
@property (atomic, assign) double doubleProperty;
@property (atomic, assign) int x;
@property (atomic, assign) int PascalCaseProperty;
@property (atomic, assign) bool ivarCXXBool;
@property (atomic, assign) bool cxxBool;
@property (atomic, strong) PFRelation *relation;

@end

@implementation PFTestObject

@dynamic idProperty;
@dynamic stringCopyProperty;
@dynamic shortProperty;
@dynamic ushortProperty;
@dynamic intProperty;
@dynamic uintProperty;
@dynamic longProperty;
@dynamic ulongProperty;
@dynamic boolProperty;
@dynamic ivarId;
@dynamic ivarInt;
@dynamic ivarShort;
@dynamic stringWithNativeAccessor;
@dynamic stringWithNativeMutator;
@dynamic floatProperty;
@dynamic doubleProperty;
@dynamic x;
@dynamic PascalCaseProperty;
@dynamic cxxBool;
@dynamic ivarCXXBool;
@dynamic relation;

+ (NSString *)parseClassName {
    return @"Test";
}

- (NSString *)stringWithNativeAccessor {
    usedNativeAccessor = YES;
    return self[@"stringWithNativeAccessor"];
}

- (void)setStringWithNativeMutator:(NSString *)aString {
    usedNativeMutator = YES;
    self[@"stringWithNativeMutator"] = aString;
}
@end

///--------------------------------------
#pragma mark - ObjectSubclassPropertiesTests
///--------------------------------------

@interface ObjectSubclassPropertiesTests : PFUnitTestCase

@end

@implementation ObjectSubclassPropertiesTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testDynamicObjectProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    NSString *idValue = @"foo";
    object.idProperty = idValue;
    XCTAssertEqualObjects(@"foo", object[@"idProperty"]);
    XCTAssertEqualObjects(@"foo", object.idProperty);
    XCTAssertEqual(idValue, object.idProperty, @"Should use retain semantics");
}

- (void)testDynamicObjectPropertyWithCopySemantics {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    // Must use a mutable string so -copy isn't optimized to return self;
    NSMutableString *stringValue = [NSMutableString stringWithString:@"stringValue"];
    object.stringCopyProperty = stringValue;
    XCTAssertEqualObjects(stringValue, object.stringCopyProperty);
    XCTAssertNotEqual(stringValue, object.stringCopyProperty,
                      @"Should use copy semantics");
}

- (void)testBoxedIntegerProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    // Boxed primitives
    object.shortProperty = 1;
    XCTAssertEqualObjects(@1, object[@"shortProperty"]);
    XCTAssertEqual((short)1, object.shortProperty);

    object.ushortProperty = 2;
    XCTAssertEqualObjects(@2, object[@"ushortProperty"]);
    XCTAssertEqual((unsigned short)2, object.ushortProperty);

    object.intProperty = 3;
    XCTAssertEqualObjects(@3, object[@"intProperty"]);
    XCTAssertEqual((int)3, object.intProperty);

    object.uintProperty = 4;
    XCTAssertEqualObjects(@4, object[@"uintProperty"]);
    XCTAssertEqual((unsigned int)4, object.uintProperty);

    object.longProperty = 5;
    XCTAssertEqualObjects(@5, object[@"longProperty"]);
    XCTAssertEqual((long)5, object.longProperty);

    object.ulongProperty = 6;
    XCTAssertEqualObjects(@6, object[@"ulongProperty"]);
    XCTAssertEqual((unsigned long)6, object.ulongProperty);
}

- (void)testBoxedFloatingPointProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];
    object.floatProperty = 1.5;
    XCTAssertEqualObjects(@1.5f, object[@"floatProperty"]);
    XCTAssertEqual(1.5f, object.floatProperty);

    object.doubleProperty = 1.75;
    XCTAssertEqualObjects(@1.75, object[@"doubleProperty"]);
    XCTAssertEqual(1.75, object.doubleProperty);
}

- (void)testBoxedBooleanProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    object.boolProperty = YES;
    XCTAssertTrue(object.boolProperty);
    XCTAssertEqualObjects(@YES, object[@"boolProperty"]);
    object.boolProperty = NO;

    // HOORAY! Boxing makes if statements work like most users expect they would
    XCTAssertFalse(object.boolProperty);
}

- (void)testShortNameProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    object.x = 1;
    XCTAssertEqual(object.x, 1);
    XCTAssertEqualObjects(@1, object[@"x"]);
}

- (void)testPascalCaseProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    object.PascalCaseProperty = 1;
    XCTAssertEqual(object.PascalCaseProperty, 1);
    XCTAssertEqualObjects(@1, object[@"PascalCaseProperty"]);
}

- (void)testIvarObjectProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    object->ivarId = @"Hello,";
    XCTAssertEqualObjects(@"Hello,", object.ivarId);

    object.ivarId = @"World!";
    XCTAssertEqualObjects(@"World!", object->ivarId);

    XCTAssertNil(object[@"ivarId"]);
}

- (void)testIvarPrimitiveProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    object->ivarInt = 5;
    XCTAssertEqual(5, object.ivarInt);

    object.ivarInt = 6;
    XCTAssertEqual(6, object->ivarInt);

    XCTAssertNil(object[@"ivarInt"]);

    // Test something that's not a bus width
    object->ivarShort = 42;
    XCTAssertEqual((unsigned short)42, object.ivarShort);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
    object.ivarShort = 0xCAFEBABE;
    XCTAssertEqual((unsigned short)0xBABE, object->ivarShort);
#pragma clang diagnostic pop

    XCTAssertNil(object[@"ivarShort"]);
}

- (void)testCXXBoolProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    object.cxxBool = true;
    XCTAssertTrue(object.cxxBool);
    XCTAssertEqualObjects(@YES, object[@"cxxBool"]);
    object.cxxBool = false;

    XCTAssertFalse(object.cxxBool);
}

- (void)testCXXBoolIvarProperties {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];

    object->ivarCXXBool = true;
    XCTAssertTrue(object.ivarCXXBool);

    object->ivarCXXBool = false;
    XCTAssertFalse(object->ivarCXXBool);

    XCTAssertNil(object[@"ivarCXXBool"]);
}

- (void)testDynamicPropertiesHonorPartialImplementations {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];
    object.stringWithNativeAccessor = @"Hello, world!";
    XCTAssertEqualObjects(@"Hello, world!", object.stringWithNativeAccessor);
    XCTAssertTrue(object->usedNativeAccessor);

    object.stringWithNativeMutator = @"Hello, world!";
    XCTAssertEqualObjects(@"Hello, world!", object.stringWithNativeMutator);
    XCTAssertTrue(object->usedNativeAccessor);
}

- (void)testObjectPropertiesAreRemovedWhenNilled {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];
    object.stringCopyProperty = @"Hello, world!";
    XCTAssertTrue([object.allKeys containsObject:@"stringCopyProperty"]);
    object.stringCopyProperty = nil;
    XCTAssertFalse([object.allKeys containsObject:@"stringCopyProperty"]);
}

// I'm not so sure the mutator is a good idea, but it'd be good to ensure that at least the
// accessors don't choke. Still, it's nice not to blow up if people do crazy things with NSNull.
- (void)testObjectPropertiesDontChokeOnNSNull {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];
    object.stringCopyProperty = (NSString *)[NSNull null];
    XCTAssertTrue([object.allKeys containsObject:@"stringCopyProperty"]);
    XCTAssertEqual((NSString *)nil, object.stringCopyProperty);
    object.stringCopyProperty = nil;
    XCTAssertFalse([object.allKeys containsObject:@"stringCopyProperty"]);
}

- (void)testBoxedPropertiesDontChokeOnNSNull {
    PFTestObject *object = [[PFTestObject alloc] initWithClassName:@"Test"];
    object[@"intProperty"] = [NSNull null];
    XCTAssertEqual(0, object.intProperty);
}

- (void)testRelationPropertiesCreateRelations {
    PFTestObject *object = [PFTestObject object];

    id relation = object.relation;
    XCTAssertTrue([relation isKindOfClass:[PFRelation class]]);
}

- (void)testRelationPropertiesAreReadOnly {
    XCTAssertThrows([PFTestObject object].relation = [[PFRelation alloc] init],
                   @"Relations are read-only and should not be assignable");
}

@end
