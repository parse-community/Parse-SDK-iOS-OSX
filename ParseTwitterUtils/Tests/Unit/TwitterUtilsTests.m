/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTwitterTestCase.h"
#import "PFTwitterUtils_Private.h"
#import "PF_Twitter.h"

@import Parse;

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

@interface TwitterUtilsTests : PFTwitterTestCase

@end

@implementation TwitterUtilsTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)tearDown {
    [PFTwitterUtils _setAuthenticationProvider:nil];

    [super tearDown];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testInitialize {
    id parseMock = PFStrictClassMock([Parse class]);
    OCMStub([parseMock applicationId]).andReturn(@"yolo");
    OCMStub([parseMock clientKey]).andReturn(@"yarr");

    id userMock = PFStrictClassMock([PFUser class]);
    OCMExpect(ClassMethod([userMock registerAuthenticationDelegate:[OCMArg checkWithBlock:^BOOL(id obj) {
        return (obj != nil);
    }] forAuthType:@"twitter"]));

    [PFTwitterUtils initializeWithConsumerKey:@"a" consumerSecret:@"b"];
    XCTAssertNotNil([PFTwitterUtils twitter]);
    XCTAssertEqualObjects([PFTwitterUtils twitter].consumerKey, @"a");
    XCTAssertEqualObjects([PFTwitterUtils twitter].consumerSecret, @"b");

    OCMVerifyAll(userMock);
}

- (void)testInitializeTwice {
    id parseMock = PFStrictClassMock([Parse class]);
    OCMStub([parseMock applicationId]).andReturn(@"yolo");
    OCMStub([parseMock clientKey]).andReturn(@"yarr");

    id userMock = PFStrictClassMock([PFUser class]);

    [PFTwitterUtils initializeWithConsumerKey:@"a" consumerSecret:@"b"];
    XCTAssertNotNil([PFTwitterUtils twitter]);
    XCTAssertEqualObjects([PFTwitterUtils twitter].consumerKey, @"a");
    XCTAssertEqualObjects([PFTwitterUtils twitter].consumerSecret, @"b");

    [PFTwitterUtils initializeWithConsumerKey:@"b" consumerSecret:@"c"];
    XCTAssertNotNil([PFTwitterUtils twitter]);
    XCTAssertEqualObjects([PFTwitterUtils twitter].consumerKey, @"a");
    XCTAssertEqualObjects([PFTwitterUtils twitter].consumerSecret, @"b");

    OCMVerifyAll(userMock);
}

- (void)testInitializeRequiresParseInitialize {
    PFAssertThrowsInconsistencyException([PFTwitterUtils initializeWithConsumerKey:@"a" consumerSecret:@"b"]);
}

@end
