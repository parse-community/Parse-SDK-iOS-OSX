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
#import "PFSubclassing.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

@interface TheFlash : PFObject<PFSubclassingSkipAutomaticRegistration> {
    NSString *flashName;
}

+ (NSString *)parseClassName;

@property (atomic, copy) NSString *flashName;
@property (atomic, copy, readonly) NSString *realName;
@end

@implementation TheFlash

@dynamic flashName;
@dynamic realName;

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self.flashName = @"The Flash";

    return self;
}

+ (NSString *)parseClassName {
    return @"Person";
}

@end

@interface BarryAllen : TheFlash

@end

@implementation BarryAllen

+ (NSString *)parseClassName {
    return @"TheFlash";
}

@end

@interface ClassWithDirtyingConstructor : PFObject<PFSubclassingSkipAutomaticRegistration>
@end

@implementation ClassWithDirtyingConstructor

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self[@"Bar"] = @"Foo";

    return self;
}

+ (NSString *)parseClassName {
    return @"ClassWithDirtyingConstructor";
}

@end

@interface UtilityClass : PFObject
@end

@implementation UtilityClass
@end

@interface DescendantOfUtility : UtilityClass<PFSubclassingSkipAutomaticRegistration>
@end

@implementation DescendantOfUtility
+ (NSString *)parseClassName {
    return @"Descendant";
}
@end

@interface StateClass : PFObject<PFSubclassing, PFSubclassingSkipAutomaticRegistration>

@property (nonatomic, copy) NSString *state;

@end

@implementation StateClass

@dynamic state;

+ (NSString *)parseClassName {
    return @"State";
}

@end

///--------------------------------------
#pragma mark - ObjectSubclassTests
///--------------------------------------

@interface ObjectSubclassTests : PFUnitTestCase

@end

@implementation ObjectSubclassTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testExplicitConstructor {
    TheFlash *flash = [TheFlash alloc];
    XCTAssertThrows(flash = [flash init], @"Cannot init an unregistered subclass");

    [TheFlash registerSubclass];
    flash = [[TheFlash alloc] init];
    XCTAssertEqualObjects(@"Person", TheFlash.parseClassName);
    XCTAssertEqualObjects(@"The Flash", ((TheFlash*)flash).flashName);
}

- (void)testSubclassConstructor {
    PFObject *theFlash = [PFObject objectWithClassName:@"Person"];
    XCTAssertFalse([theFlash isKindOfClass:[TheFlash class]]);

    [TheFlash registerSubclass];
    theFlash = [PFObject objectWithClassName:@"Person"];
    XCTAssertTrue([theFlash isKindOfClass:[TheFlash class]]);
    XCTAssertEqualObjects(@"The Flash", [(TheFlash*)theFlash flashName]);
}

- (void)testSubclassesMustHaveTheirParentsParseClassName {
    [TheFlash registerSubclass];
    XCTAssertThrows([BarryAllen registerSubclass]);
}

- (void)testDirtyPointerDetection {
    [ClassWithDirtyingConstructor registerSubclass];
    XCTAssertThrows([ClassWithDirtyingConstructor objectWithoutDataWithObjectId:@"NotUsed"]);
    [PFObject unregisterSubclass:[ClassWithDirtyingConstructor class]];
}

- (void)testSubclassesCanInheritUtilityClassesWithoutParseClassName {
    // Even though this class subclasses a subclass of PFObject and defines
    // its own parseClassName, this should succeed because the parent class
    // did not define parseClassName
    [DescendantOfUtility registerSubclass];
}

- (void)testStateIsSubclassable {
    [StateClass registerSubclass];
    StateClass *stateClass = [StateClass object];
    XCTAssertNil(stateClass.state);

    stateClass.state = @"StateString!";
    XCTAssertEqualObjects(stateClass.state, @"StateString!");
}

@end
