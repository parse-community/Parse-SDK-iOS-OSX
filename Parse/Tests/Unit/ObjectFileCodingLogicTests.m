/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDateFormatter.h"
#import "PFDecoder.h"
#import "PFObject.h"
#import "PFObjectFileCodingLogic.h"
#import "PFTestCase.h"

@interface ObjectFileCodingLogicTests : PFTestCase

@end

@implementation ObjectFileCodingLogicTests

- (void)testConstructors {
    PFObjectFileCodingLogic *logic = [[PFObjectFileCodingLogic alloc] init];
    XCTAssertNotNil(logic);

    logic = [PFObjectFileCodingLogic codingLogic];
    XCTAssertNotNil(logic);

    XCTAssertNotEqual([PFObjectFileCodingLogic codingLogic], [PFObjectFileCodingLogic codingLogic]);
}

- (void)testUpdateObject {
    NSDictionary *dictionary = @{ @"className" : @"Yolo",
                                  @"data" : @{@"objectId" : @"100500", @"slogan" : @"yarr"} };
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];

    PFObjectFileCodingLogic *logic = [PFObjectFileCodingLogic codingLogic];
    [logic updateObject:object fromDictionary:dictionary usingDecoder:[PFDecoder objectDecoder]];

    XCTAssertNotNil(object);
    XCTAssertEqualObjects(object.objectId, @"100500");
    XCTAssertEqualObjects(object[@"slogan"], @"yarr");
    XCTAssertTrue(object.dataAvailable);
}

- (void)testUpdateObjectWithLegacyKeys {
    NSDictionary *dictionary = @{ @"classname" : @"Yolo",
                                  @"id" : @"100500",
                                  @"created_at" : [[PFDateFormatter sharedFormatter] preciseStringFromDate:[NSDate date]],
                                  @"updated_at" : [[PFDateFormatter sharedFormatter] preciseStringFromDate:[NSDate date]],
                                  @"pointers" : @{@"yarr" : @[ @"Pirate", @"pff" ]},
                                  @"data" : @{@"a" : @"b"} };
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];

    PFObjectFileCodingLogic *logic = [PFObjectFileCodingLogic codingLogic];
    [logic updateObject:object fromDictionary:dictionary usingDecoder:[PFDecoder objectDecoder]];

    XCTAssertNotNil(object);
    XCTAssertEqualObjects(object.objectId, @"100500");
    XCTAssertEqualObjects(object.createdAt, [[PFDateFormatter sharedFormatter] dateFromString:dictionary[@"created_at"]]);
    XCTAssertEqualObjects(object.updatedAt, [[PFDateFormatter sharedFormatter] dateFromString:dictionary[@"updated_at"]]);
    XCTAssertEqualObjects(object[@"a"], @"b");
    XCTAssertTrue(object.dataAvailable);

    PFObject *pointer = object[@"yarr"];
    XCTAssertEqualObjects(pointer.parseClassName, @"Pirate");
    XCTAssertEqualObjects(pointer.objectId, @"pff");
    XCTAssertFalse(pointer.dataAvailable);
}

@end
