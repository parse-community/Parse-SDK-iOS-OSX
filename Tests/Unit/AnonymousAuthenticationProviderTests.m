/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Bolts.BFTask;

#import "PFAnonymousAuthenticationProvider.h"
#import "PFTestCase.h"

@interface AnonymousAuthenticationProviderTests : PFTestCase

@end

@implementation AnonymousAuthenticationProviderTests

- (void)testConstructors {
    PFAnonymousAuthenticationProvider *provider = [[PFAnonymousAuthenticationProvider alloc] init];
    XCTAssertNotNil(provider);
}

- (void)testAuthData {
    PFAnonymousAuthenticationProvider *provider = [[PFAnonymousAuthenticationProvider alloc] init];

    NSDictionary *authData = provider.authData;
    XCTAssertNotNil(authData);
    XCTAssertNotNil(authData[@"id"]);
    XCTAssertNotEqualObjects(authData, provider.authData);
}

- (void)testRestoreAuthentication {
    PFAnonymousAuthenticationProvider *provider = [[PFAnonymousAuthenticationProvider alloc] init];
    XCTAssertTrue([provider restoreAuthenticationWithAuthData:@{ @"id" : @"123" }]);
}

- (void)testRestoreAuthenticationWithNoData {
    PFAnonymousAuthenticationProvider *provider = [[PFAnonymousAuthenticationProvider alloc] init];
    XCTAssertTrue([provider restoreAuthenticationWithAuthData:nil]);
}

@end
