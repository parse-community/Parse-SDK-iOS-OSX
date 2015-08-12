/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFieldOperation.h"
#import "PFObjectUtilities.h"
#import "PFOperationSet.h"
#import "PFTestCase.h"

@interface ObjectUtilitiesTests : PFTestCase

@end

@implementation ObjectUtilitiesTests

- (void)testApplyFieldOperation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    id value = [PFObjectUtilities newValueByApplyingFieldOperation:[PFSetOperation setWithValue:@"b"]
                                                      toDictionary:dictionary
                                                            forKey:@"a"];
    XCTAssertEqualObjects(value, @"b");
    XCTAssertEqualObjects(dictionary, @{ @"a" : @"b" });
}

- (void)testApplyOperationSet {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    PFOperationSet *operationSet = [[PFOperationSet alloc] init];
    operationSet[@"a"] = [PFSetOperation setWithValue:@"b"];
    [PFObjectUtilities applyOperationSet:operationSet toDictionary:dictionary];
    XCTAssertEqualObjects(dictionary, @{ @"a" : @"b" });
}

- (void)testEquality {
    XCTAssertFalse([PFObjectUtilities isObject:nil equalToObject:@"a"]);
    XCTAssertFalse([PFObjectUtilities isObject:@"a" equalToObject:nil]);
    XCTAssertFalse([PFObjectUtilities isObject:@"a" equalToObject:@"b"]);
    XCTAssertFalse([PFObjectUtilities isObject:@"a" equalToObject:[NSDate date]]);
    XCTAssertTrue([PFObjectUtilities isObject:nil equalToObject:nil]);
    XCTAssertTrue([PFObjectUtilities isObject:@"a" equalToObject:@"a"]);
}

@end
