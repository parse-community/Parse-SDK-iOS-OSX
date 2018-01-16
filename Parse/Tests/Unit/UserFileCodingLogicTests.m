/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDecoder.h"
#import "PFUnitTestCase.h"
#import "PFUserFileCodingLogic.h"
#import "PFUserPrivate.h"

@interface UserFileCodingLogicTests : PFUnitTestCase

@end

@implementation UserFileCodingLogicTests

- (void)testConstructors {
    PFUserFileCodingLogic *logic = [[PFUserFileCodingLogic alloc] init];
    XCTAssertNotNil(logic);

    logic = [PFUserFileCodingLogic codingLogic];
    XCTAssertNotNil(logic);

    XCTAssertNotEqual([PFUserFileCodingLogic codingLogic], [PFUserFileCodingLogic codingLogic]);
}

- (void)testUpdateObject {
    NSDictionary *dictionary = @{ @"className" : @"Yolo",
                                  @"data" : @{@"objectId" : @"100500", @"slogan" : @"yarr"},
                                  @"sessionToken" : @"tokenpff",
                                  @"authData" : @{@"a" : @"b", @"c" : [NSNull null]} };
    PFUser *user = [PFUser user];
    user.authData[@"c"] = @"d";
    [user.linkedServiceNames addObject:@"c"];

    PFUserFileCodingLogic *logic = [PFUserFileCodingLogic codingLogic];
    [logic updateObject:user fromDictionary:dictionary usingDecoder:[PFDecoder objectDecoder]];

    XCTAssertNotNil(user);
    XCTAssertEqualObjects(user.objectId, @"100500");
    XCTAssertEqualObjects(user[@"slogan"], @"yarr");
    XCTAssertTrue(user.dataAvailable);

    XCTAssertEqualObjects(user.authData, @{ @"a" : @"b" });
    XCTAssertEqualObjects(user.linkedServiceNames, [NSSet setWithObject:@"a"]);
    XCTAssertEqualObjects(user.sessionToken, @"tokenpff");
}

- (void)testUpdateObjectWithLegacyKeys {
    NSDictionary *dictionary = @{ @"session_token" : @"tokenpff",
                                  @"auth_data" : @{@"a" : @"b", @"c" : [NSNull null]} };
    PFUser *user = [PFUser user];
    user.authData[@"c"] = @"d";
    [user.linkedServiceNames addObject:@"c"];

    PFUserFileCodingLogic *logic = [PFUserFileCodingLogic codingLogic];
    [logic updateObject:user fromDictionary:dictionary usingDecoder:[PFDecoder objectDecoder]];

    XCTAssertNotNil(user);
    XCTAssertTrue(user.dataAvailable);

    XCTAssertEqualObjects(user.authData, @{ @"a" : @"b" });
    XCTAssertEqualObjects(user.linkedServiceNames, [NSSet setWithObject:@"a"]);
    XCTAssertEqualObjects(user.sessionToken, @"tokenpff");
}

@end
