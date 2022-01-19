/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSessionUtilities.h"
#import "PFTestCase.h"

@interface SessionUtilitiesTests : PFTestCase

@end

@implementation SessionUtilitiesTests

- (void)testRevocableSessionToken {
    XCTAssertTrue([PFSessionUtilities isSessionTokenRevocable:@"r:blahblahblah"]);
}

- (void)testRevocableSesionTokenWithMiddleToken {
    XCTAssertTrue([PFSessionUtilities isSessionTokenRevocable:@"blahr:blah"]);
}

- (void)testRevocableSessionTokenFromNil {
    XCTAssertFalse([PFSessionUtilities isSessionTokenRevocable:nil]);
}

- (void)testRevocableSessionTokenFromBadToken {
    XCTAssertFalse([PFSessionUtilities isSessionTokenRevocable:@"blahblah"]);
}

@end
