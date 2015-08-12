/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAnalyticsUtilities.h"
#import "PFHash.h"
#import "PFTestCase.h"

@interface AnalyticsUtilitiesTests : PFTestCase

@end

@implementation AnalyticsUtilitiesTests

- (void)testDigestSerializesPayload {
    id payload = nil;
    XCTAssertEqualObjects(PFMD5HashFromString(@""),
                          [PFAnalyticsUtilities md5DigestFromPushPayload:payload],
                          @"Digest of a nil payload should match digest of empty string");
    payload = @"derp";
    XCTAssertEqualObjects(PFMD5HashFromString(@"derp"),
                          [PFAnalyticsUtilities md5DigestFromPushPayload:payload],
                          @"Digest should match digest of raw string");
    payload = @{};
    XCTAssertEqualObjects(PFMD5HashFromString(@""),
                          [PFAnalyticsUtilities md5DigestFromPushPayload:payload],
                          @"Digest of an empty payload should match digest of empty string");
    payload = @{ @"body": @"there you go" };
    XCTAssertEqualObjects(PFMD5HashFromString(@"bodythere you go"),
                          [PFAnalyticsUtilities md5DigestFromPushPayload:payload],
                          @"Digest of an dictionary payload should match digest of flattened dictionary");
    payload = @{ @"body": @"woof", @"args": @[ @"arg one", @"arg two" ] };
    XCTAssertEqualObjects(PFMD5HashFromString(@"argsarg onearg twobodywoof"),
                          [PFAnalyticsUtilities md5DigestFromPushPayload:payload],
                          @"Digest of an dictionary payload should match digest of sorted, flattened dictionary");
}

@end
