/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPin.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface PinUnitTests : PFUnitTestCase

@end

@implementation PinUnitTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testAccessors {
    PFPin *pin = [[PFPin alloc] init];

    pin.name = @"Matcha";
    pin.objects = [@[ @"Green Tea" ] mutableCopy];

    XCTAssertEqualObjects(@"Matcha", pin.name);
    XCTAssertEqualObjects(@"Green Tea", pin.objects[0]);
}

@end
