/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPropertyInfo.h"
#import "PFPropertyInfo_Runtime.h"
#import "PFTestCase.h"

@interface TestObject : NSObject

@property (atomic, copy) NSString *foo;
@property (atomic, assign) int bar;

@property (atomic, assign) id noIvar;

@end

@implementation TestObject

@dynamic noIvar;

static void *noIvarKey = &noIvarKey;
- (void)setNoIvar:(id)noIvar {
    objc_setAssociatedObject(self, noIvarKey, noIvar, OBJC_ASSOCIATION_RETAIN);
}

- (id)noIvar {
    return objc_getAssociatedObject(self, noIvarKey);
}

@end

@interface PropertyInfoTests : PFTestCase

@end

@implementation PropertyInfoTests

- (void)testInit {
    PFPropertyInfo *info = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"foo"];

    XCTAssertEqual(info.name, @"foo");
    XCTAssertEqual(info.associationType, PFPropertyInfoAssociationTypeCopy);

    info = [PFPropertyInfo propertyInfoWithClass:[TestObject class]
                                            name:@"foo"
                                 associationType:PFPropertyInfoAssociationTypeWeak];

    XCTAssertEqual(info.name, @"foo");
    XCTAssertEqual(info.associationType, PFPropertyInfoAssociationTypeWeak);
}

- (void)testGetWrappedValue {
    TestObject *obj = [[TestObject alloc] init];
    obj.foo = @"Bar";
    obj.bar = 25;

    PFPropertyInfo *fooInfo = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"foo"];
    PFPropertyInfo *barInfo = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"bar"];

    XCTAssertEqualObjects(@"Bar", [fooInfo getWrappedValueFrom:obj]);
    XCTAssertEqualObjects(@25, [barInfo getWrappedValueFrom:obj]);
}

- (void)testSetWrappedValue {
    TestObject *obj = [[TestObject alloc] init];

    PFPropertyInfo *fooInfo = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"foo"];
    PFPropertyInfo *barInfo = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"bar"];

    [fooInfo setWrappedValue:@"Bar" forObject:obj];
    [barInfo setWrappedValue:@25 forObject:obj];

    XCTAssertEqualObjects(@"Bar", obj.foo);
    XCTAssertEqual(25, obj.bar);
}

- (void)testTakeValue {
    TestObject *a = [[TestObject alloc] init];
    TestObject *b = [[TestObject alloc] init];

    a.foo = @"Bar";
    a.bar = 15;
    a.noIvar = @"Foo";

    PFPropertyInfo *fooInfo = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"foo"];
    PFPropertyInfo *barInfo = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"bar"];
    PFPropertyInfo *noIvarInvo = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"noIvar"];

    [fooInfo takeValueFrom:a toObject:b];
    [barInfo takeValueFrom:a toObject:b];
    [noIvarInvo takeValueFrom:a toObject:b];

    XCTAssertEqualObjects(a.foo, b.foo);
    XCTAssertEqual(a.bar, b.bar);
    XCTAssertEqualObjects(a.noIvar, b.noIvar);
}

- (void)testEquality {
    PFPropertyInfo *fooInfo = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"foo"];
    PFPropertyInfo *barInfo = [PFPropertyInfo propertyInfoWithClass:[TestObject class] name:@"bar"];

    XCTAssertTrue([fooInfo isEqual:fooInfo]);
    XCTAssertFalse([fooInfo isEqual:barInfo]);
    XCTAssertFalse([fooInfo isEqual:nil]);
}

@end
