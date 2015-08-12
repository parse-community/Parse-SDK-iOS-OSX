/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestCase.h"

#import "PFHash.h"

@interface HashTests : PFTestCase

@end

@implementation HashTests

- (void)testMD5SimpleHash {
    XCTAssertEqualObjects(@"5eb63bbbe01eeed093cb22bb8f5acdc3", PFMD5HashFromString(@"hello world"));
    XCTAssertEqualObjects(@"5eb63bbbe01eeed093cb22bb8f5acdc3",
                          PFMD5HashFromData([@"hello world" dataUsingEncoding:NSUTF8StringEncoding]));
}

- (void)testMD5HashFromUnicode {
    XCTAssertEqualObjects(@"9c853e20bb12ff256734a992dd224f17", PFMD5HashFromString(@"foo א"));
    XCTAssertEqualObjects(@"9c853e20bb12ff256734a992dd224f17",
                          PFMD5HashFromData([@"foo א" dataUsingEncoding:NSUTF8StringEncoding]));
    
    XCTAssertEqualObjects(@"9c853e20bb12ff256734a992dd224f17", PFMD5HashFromString(@"foo \327\220"));
    XCTAssertEqualObjects(@"9c853e20bb12ff256734a992dd224f17",
                          PFMD5HashFromData([@"foo \327\220" dataUsingEncoding:NSUTF8StringEncoding]));
}

@end
