/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFObject+Subclass.h>
#import <Parse/PFRelation.h>
#import <Parse/PFSubclassing.h>

#import "PFObjectPrivate.h"
#import "PFObjectSubclassingController.h"
#import "PFUnitTestCase.h"
#import "ParseUnitTests-Swift.h"

@interface TestSubclass : PFObject<PFSubclassingSkipAutomaticRegistration>
@end

@interface NotSubclass : PFObject<PFSubclassingSkipAutomaticRegistration>
@end

@interface PropertySubclass : PFObject<PFSubclassingSkipAutomaticRegistration> {
@public
    id _ivarProperty;
}

@property (nonatomic, assign) int primitiveProperty;
@property (nonatomic, strong) id objectProperty;
@property (nonatomic, strong, readonly) PFRelation *relationProperty;
@property (nonatomic, strong) PFRelation *badRelation;

@property (nonatomic, strong) id ivarProperty;
@property (nonatomic, copy) id aCopyProperty;

@property (nonatomic, assign) CGPoint badProperty;

@end

@interface BadSubclass : TestSubclass
@end

@interface GoodSubclass : TestSubclass
@end

@implementation TestSubclass

+ (NSString *)parseClassName {
    return @"TestSubclass";
}

@end

@implementation NotSubclass

+ (NSString *)parseClassName {
    return @"TestSubclass";
}

@end

@implementation PropertySubclass

@dynamic primitiveProperty, objectProperty, relationProperty, ivarProperty, aCopyProperty, badProperty, badRelation;

+ (NSString *)parseClassName {
    return @"PropertySubclass";
}

- (void)badSelector {

}

@end

@implementation BadSubclass

+ (NSString *)parseClassName {
    return @"Bad";
}

@end

@implementation GoodSubclass
@end

@interface ObjectSubclassingControllerTests : PFUnitTestCase

@end

@implementation ObjectSubclassingControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (void)badSelector {
    // To shut the compiler up
}

- (NSInvocation *)_forwardingInvocationForTarget:(PFObject *)target
                                        selector:(SEL)aSelector
                                      controller:(PFObjectSubclassingController *)controller {
    NSMethodSignature *methodSignature = [controller forwardingMethodSignatureForSelector:aSelector
                                                                                  ofClass:[target class]];
    if (methodSignature == nil) {
        methodSignature = [target methodSignatureForSelector:aSelector];
    }
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    [invocation setTarget:target];
    [invocation setSelector:aSelector];

    return invocation;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructor {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    XCTAssertNotNil(subclassingController);
}

- (void)testRegister {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    [subclassingController registerSubclass:[TestSubclass class]];

    XCTAssertEqual([TestSubclass class], [subclassingController subclassForParseClassName:@"TestSubclass"]);
}

- (void)testRegistrationAfterMethodResolution {
    PropertySubclass *subclass = [[PropertySubclass alloc] initWithClassName:@"Yolo"];
    XCTAssertNoThrow(subclass.primitiveProperty = 1);
    XCTAssertEqual(subclass.primitiveProperty, 1);

    [PropertySubclass registerSubclass];
    XCTAssertEqual(subclass.primitiveProperty, 1);
    XCTAssertNoThrow(subclass.primitiveProperty = 2);
    XCTAssertEqual(subclass.primitiveProperty, 2);
}

- (void)testUnregister {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    [subclassingController registerSubclass:[TestSubclass class]];

    XCTAssertEqual([TestSubclass class], [subclassingController subclassForParseClassName:@"TestSubclass"]);

    [subclassingController unregisterSubclass:[TestSubclass class]];

    XCTAssertNil([subclassingController subclassForParseClassName:@"TestSubclass"]);
}

- (void)testSubclassingEdgeCases {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    [subclassingController registerSubclass:[TestSubclass class]];

    XCTAssertEqual([TestSubclass class], [subclassingController subclassForParseClassName:@"TestSubclass"]);
    XCTAssertThrows([subclassingController registerSubclass:[BadSubclass class]]);
    XCTAssertEqual([TestSubclass class], [subclassingController subclassForParseClassName:@"TestSubclass"]);

    XCTAssertNoThrow([subclassingController registerSubclass:[GoodSubclass class]]);
    XCTAssertEqual([GoodSubclass class], [subclassingController subclassForParseClassName:@"TestSubclass"]);

    XCTAssertNoThrow([subclassingController registerSubclass:[TestSubclass class]]);
    XCTAssertEqual([GoodSubclass class], [subclassingController subclassForParseClassName:@"TestSubclass"]);

    XCTAssertThrows([subclassingController registerSubclass:[NotSubclass class]]);
    XCTAssertEqual([GoodSubclass class], [subclassingController subclassForParseClassName:@"TestSubclass"]);
}

- (void)testForwardingMethodSignature {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    [subclassingController registerSubclass:[PropertySubclass class]];

    XCTAssertEqualObjects([subclassingController forwardingMethodSignatureForSelector:@selector(primitiveProperty)
                                                                              ofClass:[PropertySubclass class]],
                          [NSMethodSignature signatureWithObjCTypes:"i@:"]);

    XCTAssertEqualObjects([subclassingController forwardingMethodSignatureForSelector:@selector(setPrimitiveProperty:)
                                                                              ofClass:[PropertySubclass class]],
                          [NSMethodSignature signatureWithObjCTypes:"v@:i"]);


    XCTAssertNil([subclassingController forwardingMethodSignatureForSelector:@selector(badSelector)
                                                                     ofClass:[PropertySubclass class]]);
}

- (void)testBadForwarding {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    // Don't register subclass with controller.
    [PropertySubclass registerSubclass];

    PropertySubclass *object = [[PropertySubclass alloc] init];

    [subclassingController registerSubclass:[PropertySubclass class]];
    NSInvocation *invocation = [self _forwardingInvocationForTarget:object
                                                           selector:@selector(badSelector)
                                                         controller:subclassingController];
    XCTAssertFalse([subclassingController forwardObjectInvocation:invocation withObject:object]);

    // This will print the warning message to the console, which gives us 100% test coverage!
    invocation = [self _forwardingInvocationForTarget:object
                                             selector:@selector(badRelation)
                                           controller:subclassingController];
}

- (void)testForwardingGetter {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    [PropertySubclass registerSubclass];
    [subclassingController registerSubclass:[PropertySubclass class]];

#define AssertInvocationAssertValueEquals(invocation, type, value) ({ \
    type _expected = (value); \
    type _actual; [invocation getReturnValue:&_actual];  \
    XCTAssertEqual(_expected, _actual); \
})

    PropertySubclass *target = [[PropertySubclass alloc] init];
    target[@"primitiveProperty"] = @1337;
    target[@"objectProperty"] = @"Hello, World!";
    target[@"aCopyProperty"] = [[NSMutableString alloc] initWithString:@"Hello, World!"];
    target[@"badProperty"] = @"Some Value";
    target->_ivarProperty = @8675309;

    NSInvocation *invocation = [self _forwardingInvocationForTarget:target
                                                           selector:@selector(primitiveProperty)
                                                         controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    AssertInvocationAssertValueEquals(invocation, int, 1337);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(objectProperty)
                                           controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    AssertInvocationAssertValueEquals(invocation, __unsafe_unretained id, @"Hello, World!");

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(ivarProperty)
                                           controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    AssertInvocationAssertValueEquals(invocation, __unsafe_unretained id, target->_ivarProperty);

    target[@"objectProperty"] = [NSNull null];
    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(objectProperty)
                                           controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    AssertInvocationAssertValueEquals(invocation, __unsafe_unretained id, nil);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(relationProperty)
                                           controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    __unsafe_unretained PFRelation *returnValue = nil;
    [invocation getReturnValue:&returnValue];
    XCTAssertTrue([returnValue isKindOfClass:[PFRelation class]]);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(aCopyProperty)
                                           controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    __unsafe_unretained NSString *copyPropertyValue = nil;
    [invocation getReturnValue:&copyPropertyValue];

    // Ensure our mutable string is now immutable.
    XCTAssertThrows([(NSMutableString *)copyPropertyValue appendString:@"foo"]);


    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(badProperty)
                                           controller:subclassingController];
    XCTAssertThrows([subclassingController forwardObjectInvocation:invocation withObject:target]);
}

- (void)testForwardingSetter {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    [PropertySubclass registerSubclass];
    [subclassingController registerSubclass:[PropertySubclass class]];

    PropertySubclass *target = [[PropertySubclass alloc] init];


    id objectAgument = nil;
    NSInvocation *invocation = [self _forwardingInvocationForTarget:target
                                                           selector:@selector(setObjectProperty:)
                                                         controller:subclassingController];

    objectAgument = @"Hello, World!";
    [invocation setArgument:&objectAgument atIndex:2];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    XCTAssertEqualObjects(target[@"objectProperty"], @"Hello, World!");

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(setPrimitiveProperty:)
                                           controller:subclassingController];
    [invocation setArgument:&(int) { 1337 } atIndex:2];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    XCTAssertEqualObjects(target[@"primitiveProperty"], @1337);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(setIvarProperty:)
                                           controller:subclassingController];
    objectAgument = @8675309;
    [invocation setArgument:&objectAgument atIndex:2];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    XCTAssertEqualObjects(target->_ivarProperty, @8675309);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(setObjectProperty:)
                                           controller:subclassingController];
    objectAgument = nil;
    [invocation setArgument:&objectAgument atIndex:2];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    XCTAssertEqualObjects(target[@"objectProperty"], nil);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(setACopyProperty:)
                                           controller:subclassingController];
    objectAgument = [[NSMutableString alloc] initWithString:@"Hello, World!"];
    [invocation setArgument:&objectAgument atIndex:2];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    XCTAssertThrows([target[@"aCopyProperty"] appendString:@"foo"]);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(setBadProperty:)
                                           controller:subclassingController];
    [invocation setArgument:&(CGPoint) { 1, 1 } atIndex:2];
    XCTAssertThrows([subclassingController forwardObjectInvocation:invocation withObject:target]);
}

- (void)testSwiftGetters {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    [SwiftSubclass registerSubclass];
    [subclassingController registerSubclass:[SwiftSubclass class]];

#define AssertInvocationAssertValueEquals(invocation, type, value) ({ \
    type _expected = (value); \
    type _actual; [invocation getReturnValue:&_actual];  \
    XCTAssertEqual(_expected, _actual); \
})

    SwiftSubclass *target = [[SwiftSubclass alloc] init];
    target[@"primitiveProperty"] = @1337;
    target[@"objectProperty"] = @"Hello, World!";
    target[@"aCopyProperty"] = [[NSMutableString alloc] initWithString:@"Hello, World!"];
    target[@"badProperty"] = @"Some Value";

    NSInvocation *invocation = [self _forwardingInvocationForTarget:target
                                                           selector:@selector(primitiveProperty)
                                                         controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    AssertInvocationAssertValueEquals(invocation, NSInteger, 1337);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(objectProperty)
                                           controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    AssertInvocationAssertValueEquals(invocation, __unsafe_unretained id, @"Hello, World!");

    target[@"objectProperty"] = [NSNull null];
    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(objectProperty)
                                           controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    AssertInvocationAssertValueEquals(invocation, __unsafe_unretained id, nil);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(relationProperty)
                                           controller:subclassingController];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    __unsafe_unretained PFRelation *returnValue = nil;
    [invocation getReturnValue:&returnValue];
    XCTAssertTrue([returnValue isKindOfClass:[PFRelation class]]);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(badProperty)
                                           controller:subclassingController];
    XCTAssertThrows([subclassingController forwardObjectInvocation:invocation withObject:target]);
}

- (void)testSwiftSetters {
    PFObjectSubclassingController *subclassingController = [[PFObjectSubclassingController alloc] init];
    [SwiftSubclass registerSubclass];
    [subclassingController registerSubclass:[SwiftSubclass class]];

    SwiftSubclass *target = [[SwiftSubclass alloc] init];

    id objectAgument = nil;
    NSInvocation *invocation = [self _forwardingInvocationForTarget:target
                                                           selector:@selector(setObjectProperty:)
                                                         controller:subclassingController];

    objectAgument = @"Hello, World!";
    [invocation setArgument:&objectAgument atIndex:2];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    XCTAssertEqualObjects(target[@"objectProperty"], @"Hello, World!");

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(setPrimitiveProperty:)
                                           controller:subclassingController];
    [invocation setArgument:&(NSInteger) { 1337 } atIndex:2];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    XCTAssertEqualObjects(target[@"primitiveProperty"], @1337);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(setObjectProperty:)
                                           controller:subclassingController];
    objectAgument = nil;
    [invocation setArgument:&objectAgument atIndex:2];
    [subclassingController forwardObjectInvocation:invocation withObject:target];
    XCTAssertEqualObjects(target[@"objectProperty"], nil);

    invocation = [self _forwardingInvocationForTarget:target
                                             selector:@selector(setBadProperty:)
                                           controller:subclassingController];
    [invocation setArgument:&(CGPoint) { 1, 1 } atIndex:2];
    XCTAssertThrows([subclassingController forwardObjectInvocation:invocation withObject:target]);
}

@end
