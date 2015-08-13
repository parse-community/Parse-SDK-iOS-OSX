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
    PFAssertThrowsInvalidArgumentException([[PFUser alloc] initWithClassName:@"notuserclass"]);
}

- (void)testImmutableFieldsCannotBeChanged {
    PFUser *user = [PFUser object];
    PFAssertThrowsInvalidArgumentException(user[@"sessionToken"] = @"a");
}

- (void)testImmutableFieldsCannotBeDeleted {
    PFUser *user = [PFUser object];
    PFAssertThrowsInvalidArgumentException([user removeObjectForKey:@"username"]);
    PFAssertThrowsInvalidArgumentException([user removeObjectForKey:@"sessionToken"]);
}

#pragma mark Sign Up

- (void)testUserCannotSignUpWithoutUsername {
    PFUser *user = [PFUser user];
    user.password = @"yolo";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[user signUpInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.faulted);
        XCTAssertEqualObjects(task.error.domain, PFParseErrorDomain);
        XCTAssertEqual(task.error.code, kPFErrorUsernameMissing);
        XCTAssertNotNil(task.error.userInfo[NSLocalizedDescriptionKey]);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testUserCannotSignUpWithoutPassword {
    PFUser *user = [PFUser user];
    user.username = @"yolo";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[user signUpInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.faulted);
        XCTAssertEqualObjects(task.error.domain, PFParseErrorDomain);
        XCTAssertEqual(task.error.code, kPFErrorUserPasswordMissing);
        XCTAssertNotNil(task.error.userInfo[NSLocalizedDescriptionKey]);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

@end
