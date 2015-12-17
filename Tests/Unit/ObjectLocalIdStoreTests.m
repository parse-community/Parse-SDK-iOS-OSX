/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFDecoder.h"
#import "PFFileManager.h"
#import "PFInternalUtils.h"
#import "PFJSONSerialization.h"
#import "PFObjectLocalIdStore.h"
#import "PFTestCase.h"

@interface ObjectLocalIdStoreTests : PFTestCase

@end

@implementation ObjectLocalIdStoreTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFFileManagerProvider>)mockedDataSource {
    id<PFFileManagerProvider> dataSource = PFStrictProtocolMock(@protocol(PFFileManagerProvider));
    [OCMStub(dataSource.fileManager) andReturn:PFStrictClassMock([PFFileManager class])];
    return dataSource;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id<PFFileManagerProvider> dataSource = [self mockedDataSource];
    PFFileManager *fileManager = dataSource.fileManager;
    OCMStub([fileManager parseDataItemPathForPathComponent:[OCMArg isNotNil]]).andReturn(NSTemporaryDirectory());

    PFObjectLocalIdStore *store = [[PFObjectLocalIdStore alloc] initWithDataSource:dataSource];
    XCTAssertNotNil(store);
    XCTAssertEqual((id)store.dataSource, dataSource);

    store = [PFObjectLocalIdStore storeWithDataSource:dataSource];
    XCTAssertNotNil(store);
    XCTAssertEqual((id)store.dataSource, dataSource);
}

- (void)testRetain {
    id<PFFileManagerProvider> dataSource = [self mockedDataSource];
    PFFileManager *fileManager = dataSource.fileManager;
    OCMStub([fileManager parseDataItemPathForPathComponent:[OCMArg isNotNil]]).andReturn(NSTemporaryDirectory());

    PFObjectLocalIdStore *store = [[PFObjectLocalIdStore alloc] initWithDataSource:dataSource];

    NSString *localId1 = [store createLocalId];
    XCTAssertNotNil(localId1);
    [store retainLocalIdOnDisk:localId1]; // refcount = 1
    XCTAssertNil([store objectIdForLocalId:localId1]);

    NSString *localId2 = [store createLocalId];
    XCTAssertNotNil(localId2);
    [store retainLocalIdOnDisk:localId2]; // refcount = 1
    XCTAssertNil([store objectIdForLocalId:localId2]);

    [store retainLocalIdOnDisk:localId1]; // refcount = 2
    XCTAssertNil([store objectIdForLocalId:localId1]);
    XCTAssertNil([store objectIdForLocalId:localId2]);

    [store releaseLocalIdOnDisk:localId1]; // refcount = 1
    XCTAssertNil([store objectIdForLocalId:localId1]);
    XCTAssertNil([store objectIdForLocalId:localId2]);

    NSString *objectId1 = @"objectId1";
    [store setObjectId:objectId1 forLocalId:localId1];
    XCTAssertEqualObjects(objectId1, [store objectIdForLocalId:localId1]);
    XCTAssertNil([store objectIdForLocalId:localId2]);

    [store retainLocalIdOnDisk:localId1]; // refcount = 2
    XCTAssertEqualObjects(objectId1, [store objectIdForLocalId:localId1]);
    XCTAssertNil([store objectIdForLocalId:localId2]);

    NSString *objectId2 = @"objectId2";
    [store setObjectId:objectId2 forLocalId:localId2];
    XCTAssertEqualObjects(objectId1, [store objectIdForLocalId:localId1]);
    XCTAssertEqualObjects(objectId2, [store objectIdForLocalId:localId2]);

    [store releaseLocalIdOnDisk:localId1]; // refcount = 1
    XCTAssertEqualObjects(objectId1, [store objectIdForLocalId:localId1]);
    XCTAssertEqualObjects(objectId2, [store objectIdForLocalId:localId2]);

    [store releaseLocalIdOnDisk:localId1]; // refcount = 0
    XCTAssertEqualObjects(objectId1, [store objectIdForLocalId:localId1]);
    XCTAssertEqualObjects(objectId2, [store objectIdForLocalId:localId2]);

    [store clearInMemoryCache];
    XCTAssertNil([store objectIdForLocalId:localId1]);
    XCTAssertEqualObjects(objectId2, [store objectIdForLocalId:localId2]);

    [store releaseLocalIdOnDisk:localId2]; // refcount = 0
    XCTAssertNil([store objectIdForLocalId:localId1]);
    XCTAssertNil([store objectIdForLocalId:localId2]);

    [store clearInMemoryCache];
    XCTAssertNil([store objectIdForLocalId:localId1]);
    XCTAssertNil([store objectIdForLocalId:localId2]);

    [store clear];
}

- (void)testRetainAfterRelease {
    id<PFFileManagerProvider> dataSource = [self mockedDataSource];
    PFFileManager *fileManager = dataSource.fileManager;
    OCMStub([fileManager parseDataItemPathForPathComponent:[OCMArg isNotNil]]).andReturn(NSTemporaryDirectory());

    PFObjectLocalIdStore *store = [[PFObjectLocalIdStore alloc] initWithDataSource:dataSource];

    NSString *localId = [store createLocalId];
    [store setObjectId:@"venus" forLocalId:localId];
    [store retainLocalIdOnDisk:localId];
    [store clearInMemoryCache];
    XCTAssertEqualObjects(@"venus", [store objectIdForLocalId:localId]);

    [store clear];
}

- (void)testLongSerialization {
    long long expected = 0x8000000000000000L;
    NSDictionary *object = @{ @"hugeNumber" : @(expected) };

    NSString *json = [PFJSONSerialization stringFromJSONObject:object];

    NSDictionary *parsed = [PFJSONSerialization JSONObjectFromString:json];
    object = [[PFDecoder objectDecoder] decodeObject:parsed];
    long long actual = [object[@"hugeNumber"] longLongValue];
    XCTAssertEqual(expected, actual, @"The number should be parsed correctly.");
}

@end
