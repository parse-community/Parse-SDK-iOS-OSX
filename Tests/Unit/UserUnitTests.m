/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUnitTestCase.h"
#import "PFUser.h"

@interface UserUnitTests : PFUnitTestCase

@end

@implementation UserUnitTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructorsClassNameValidation {
    PFAssertThrowsInvalidArgumentException([[PFUser alloc] initWithClassName:@"notuserclass"],
                                           @"Should throw an exception for invalid classname");
}

- (void)testImmutableFieldsCannotBeChanged {
    [PFUser registerSubclass];

    PFUser *user = [PFUser object];
    PFAssertThrowsInvalidArgumentException(user[@"sessionToken"] = @"a");
}

- (void)testImmutableFieldsCannotBeDeleted {
    [PFUser registerSubclass];

    PFUser *user = [PFUser object];
    PFAssertThrowsInvalidArgumentException([user removeObjectForKey:@"username"]);
    PFAssertThrowsInvalidArgumentException([user removeObjectForKey:@"sessionToken"]);
}

@end
