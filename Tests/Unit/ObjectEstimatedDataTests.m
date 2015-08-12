/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFieldOperation.h"
#import "PFObjectEstimatedData.h"
#import "PFOperationSet.h"
#import "PFTestCase.h"

@interface ObjectEstimatedDataTests : PFTestCase

@end

@implementation ObjectEstimatedDataTests

- (void)testConstructors {
    PFObjectEstimatedData *data = [[PFObjectEstimatedData alloc] init];
    XCTAssertNotNil(data);
    XCTAssertNotNil([data allKeys]);
    XCTAssertEqualObjects([data allKeys], @[]);

    data = [[PFObjectEstimatedData alloc] initWithServerData:nil operationSetQueue:nil];
    XCTAssertNotNil(data);
    XCTAssertNotNil([data allKeys]);
    XCTAssertEqualObjects([data allKeys], @[]);

    data = [[PFObjectEstimatedData alloc] initWithServerData:@{ @"a" : @"b" } operationSetQueue:nil];
    XCTAssertNotNil(data);
    XCTAssertNotNil([data allKeys]);
    XCTAssertEqualObjects([data allKeys], @[ @"a" ]);
    XCTAssertEqualObjects(data[@"a"], @"b");

    data = [PFObjectEstimatedData estimatedDataFromServerData:@{ @"a" : @"b" } operationSetQueue:nil];
    XCTAssertNotNil(data);
    XCTAssertNotNil([data allKeys]);
    XCTAssertEqualObjects([data allKeys], @[ @"a" ]);
    XCTAssertEqualObjects(data[@"a"], @"b");

    PFOperationSet *operationSet = [[PFOperationSet alloc] init];
    operationSet[@"c"] = [PFSetOperation setWithValue:@"d"];

    data = [PFObjectEstimatedData estimatedDataFromServerData:@{ @"a" : @"b" }
                                            operationSetQueue:@[ operationSet ]];
    XCTAssertNotNil(data);
    XCTAssertNotNil([data allKeys]);
    XCTAssertEqualObjects([data allKeys], (@[ @"a", @"c" ]));
    XCTAssertEqualObjects(data[@"a"], @"b");
    XCTAssertEqualObjects(data[@"c"], @"d");
}

- (void)testObjectForKey {
    PFObjectEstimatedData *data = [PFObjectEstimatedData estimatedDataFromServerData:@{ @"a" : @"b" }
                                                                   operationSetQueue:nil];
    XCTAssertEqualObjects([data objectForKey:@"a"], @"b");
    XCTAssertEqualObjects(data[@"a"], @"b");
}

- (void)testEnumeration {
    PFOperationSet *operationSet = [[PFOperationSet alloc] init];
    operationSet[@"c"] = [PFSetOperation setWithValue:@"d"];
    PFObjectEstimatedData *data = [PFObjectEstimatedData estimatedDataFromServerData:@{ @"a" : @"b" }
                                                                   operationSetQueue:@[ operationSet ]];

    __block NSUInteger counter = 0;
    [data enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        if (counter == 0) {
            XCTAssertEqualObjects(key, @"a");
            XCTAssertEqualObjects(obj, @"b");
        } else if (counter == 1) {
            XCTAssertEqualObjects(key, @"c");
            XCTAssertEqualObjects(obj, @"d");
        } else {
            XCTFail();
        }
        counter++;
    }];
}

- (void)testAllKeys {
    PFObjectEstimatedData *data = [PFObjectEstimatedData estimatedDataFromServerData:@{ @"a" : @"b" }
                                                                   operationSetQueue:nil];
    XCTAssertEqualObjects([data allKeys], @[ @"a" ]);
}

- (void)testDictionaryRepresentation {
    PFOperationSet *operationSet = [[PFOperationSet alloc] init];
    operationSet[@"c"] = [PFSetOperation setWithValue:@"d"];
    PFObjectEstimatedData *data = [PFObjectEstimatedData estimatedDataFromServerData:@{ @"a" : @"b" }
                                                                   operationSetQueue:@[ operationSet ]];
    NSDictionary *dictionary = data.dictionaryRepresentation;
    XCTAssertEqualObjects(dictionary, (@{ @"a" : @"b", @"c" : @"d" }));
    XCTAssertNotEqual(dictionary, data.dictionaryRepresentation);
}

@end
