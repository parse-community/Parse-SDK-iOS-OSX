/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDecoder.h"
#import "PFEncoder.h"
#import "PFJSONSerialization.h"
#import "PFObject.h"
#import "PFObjectFileCoder.h"
#import "PFTestCase.h"

@interface ObjectFileCoderTests : PFTestCase

@end

@implementation ObjectFileCoderTests

- (void)testDataFromObject {
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    object.objectId = @"100500";
    object[@"yarr"] = @"pff";

    NSData *data = [PFObjectFileCoder dataFromObject:object usingEncoder:[PFEncoder objectEncoder]];
    NSDictionary *dictionary = [PFJSONSerialization JSONObjectFromData:data];
    XCTAssertEqualObjects(dictionary, (@{ @"classname" : @"Yolo",
                                          @"data" : @{@"objectId" : @"100500"} }));
}

- (void)testObjectFromData {
    NSDictionary *dictionary = @{ @"classname" : @"Yolo",
                                  @"data" : @{@"objectId" : @"100500", @"yarr" : @"pff"} };
    NSData *data = [PFJSONSerialization dataFromJSONObject:dictionary];

    PFObject *object = [PFObjectFileCoder objectFromData:data usingDecoder:[PFDecoder objectDecoder]];
    XCTAssertNotNil(object);
    XCTAssertEqualObjects(object.parseClassName, @"Yolo");
    XCTAssertEqualObjects(object.objectId, @"100500");
    XCTAssertEqualObjects(object[@"yarr"], @"pff");
    XCTAssertFalse(object.dirty);
}

@end
