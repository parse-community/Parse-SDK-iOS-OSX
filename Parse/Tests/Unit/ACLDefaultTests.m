/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUnitTestCase.h"

#import "PFACLPrivate.h"

@interface ACLDefaultTests : PFUnitTestCase

@end

@implementation ACLDefaultTests

- (void)testDefaultACL {
    PFACL *newACL = [PFACL ACL];
    [newACL setPublicReadAccess:YES];
    [newACL setShared:YES];

    XCTAssertNotEqualObjects(newACL, [PFACL defaultACL]);
    [PFACL setDefaultACL:newACL withAccessForCurrentUser:YES];
    XCTAssertEqualObjects(newACL, [PFACL defaultACL]);
}

@end
