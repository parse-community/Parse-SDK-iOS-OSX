/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestCase.h"

#import "PFURLConstructor.h"

@interface URLConstructorTests : PFTestCase

@end

@implementation URLConstructorTests

- (void)testURLWithNilPathNilQuery {
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com"
                                                             path:nil
                                                            query:nil].absoluteString,
                          @"https://yolo.com");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/"
                                                             path:nil
                                                            query:nil].absoluteString,
                          @"https://yolo.com/");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/123"
                                                             path:nil
                                                            query:nil].absoluteString,
                          @"https://yolo.com/123");
}

- (void)testURLWithPath {
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com"
                                                             path:@"100500/yolo"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/100500/yolo");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com"
                                                             path:@"/100500/yolo"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/100500/yolo");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/"
                                                             path:@"100500/yolo"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/100500/yolo");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/"
                                                             path:@"/100500/yolo"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/100500/yolo");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/abc"
                                                             path:@"100500/yolo"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/abc/100500/yolo");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/abc/"
                                                             path:@"/100500/yolo"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/abc/100500/yolo");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/abc/xyz"
                                                             path:@"/100500/yolo"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/abc/xyz/100500/yolo");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/"
                                                             path:@"/yolo/"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/yolo/");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/"
                                                             path:@"a/yolo/"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/a/yolo/");
    XCTAssertEqualObjects([PFURLConstructor URLFromAbsoluteString:@"https://yolo.com/"
                                                             path:@"/a/yolo/"
                                                            query:nil].absoluteString,
                          @"https://yolo.com/a/yolo/");
}

@end
