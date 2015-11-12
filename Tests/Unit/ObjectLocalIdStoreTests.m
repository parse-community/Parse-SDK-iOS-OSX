/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFCoreManager.h"
#import "PFDecoder.h"
#import "PFFileManager.h"
#import "PFInternalUtils.h"
#import "PFJSONSerialization.h"
#import "PFObjectLocalIdStore.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface ObjectLocalIdStoreTests : PFUnitTestCase

@end

@implementation ObjectLocalIdStoreTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    [[Parse _currentManager].coreManager.objectLocalIdStore clear];
}

- (void)tearDown {
    [[Parse _currentManager].coreManager.objectLocalIdStore clear];

    [super tearDown];
}

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

    PFObjectLocalIdStore *store = [[PFObjectLocalIdStore alloc] initWithDataSource:dataSource];
    XCTAssertNotNil(store);
    XCTAssertEqual((id)store.dataSource, dataSource);

    store = [PFObjectLocalIdStore storeWithDataSource:dataSource];
    XCTAssertNotNil(store);
    XCTAssertEqual((id)store.dataSource, dataSource);
}

- (void)testRetain {
    PFObjectLocalIdStore *manager = [Parse _currentManager].coreManager.objectLocalIdStore;

    NSString *localId1 = [manager createLocalId];
    XCTAssertNotNil(localId1);
    [manager retainLocalIdOnDisk:localId1];  // refcount = 1
    XCTAssertNil([manager objectIdForLocalId:localId1]);

    NSString *localId2 = [manager createLocalId];
    XCTAssertNotNil(localId2);
    [manager retainLocalIdOnDisk:localId2];  // refcount = 1
    XCTAssertNil([manager objectIdForLocalId:localId2]);

    [manager retainLocalIdOnDisk:localId1];  // refcount = 2
    XCTAssertNil([manager objectIdForLocalId:localId1]);
    XCTAssertNil([manager objectIdForLocalId:localId2]);

    [manager releaseLocalIdOnDisk:localId1];  // refcount = 1
    XCTAssertNil([manager objectIdForLocalId:localId1]);
    XCTAssertNil([manager objectIdForLocalId:localId2]);

    NSString *objectId1 = @"objectId1";
    [manager setObjectId:objectId1 forLocalId:localId1];
    XCTAssertEqualObjects(objectId1, [manager objectIdForLocalId:localId1]);
    XCTAssertNil([manager objectIdForLocalId:localId2]);

    [manager retainLocalIdOnDisk:localId1];  // refcount = 2
    XCTAssertEqualObjects(objectId1, [manager objectIdForLocalId:localId1]);
    XCTAssertNil([manager objectIdForLocalId:localId2]);

    NSString *objectId2 = @"objectId2";
    [manager setObjectId:objectId2 forLocalId:localId2];
    XCTAssertEqualObjects(objectId1, [manager objectIdForLocalId:localId1]);
    XCTAssertEqualObjects(objectId2, [manager objectIdForLocalId:localId2]);

    [manager releaseLocalIdOnDisk:localId1];  // refcount = 1
    XCTAssertEqualObjects(objectId1, [manager objectIdForLocalId:localId1]);
    XCTAssertEqualObjects(objectId2, [manager objectIdForLocalId:localId2]);

    [manager releaseLocalIdOnDisk:localId1];  // refcount = 0
    XCTAssertEqualObjects(objectId1, [manager objectIdForLocalId:localId1]);
    XCTAssertEqualObjects(objectId2, [manager objectIdForLocalId:localId2]);

    [manager clearInMemoryCache];
    XCTAssertNil([manager objectIdForLocalId:localId1]);
    XCTAssertEqualObjects(objectId2, [manager objectIdForLocalId:localId2]);

    [manager releaseLocalIdOnDisk:localId2];  // refcount = 0
    XCTAssertNil([manager objectIdForLocalId:localId1]);
    XCTAssertNil([manager objectIdForLocalId:localId2]);

    [manager clearInMemoryCache];
    XCTAssertNil([manager objectIdForLocalId:localId1]);
    XCTAssertNil([manager objectIdForLocalId:localId2]);

    XCTAssertFalse([[Parse _currentManager].coreManager.objectLocalIdStore clear]);
}

- (void)testRetainAfterRelease {
    PFObjectLocalIdStore *manager = [Parse _currentManager].coreManager.objectLocalIdStore;

    NSString *localId = [manager createLocalId];
    [manager setObjectId:@"venus" forLocalId:localId];
    [manager retainLocalIdOnDisk:localId];
    [manager clearInMemoryCache];
    XCTAssertEqualObjects(@"venus", [manager objectIdForLocalId:localId]);
}

- (void)testLongSerialization {
    long long expected = 0x8000000000000000L;
    NSDictionary *object = @{ @"hugeNumber": @(expected) };

    NSString *json = [PFJSONSerialization stringFromJSONObject:object];

    NSDictionary *parsed = [PFJSONSerialization JSONObjectFromString:json];
    object = [[PFDecoder objectDecoder] decodeObject:parsed];
    long long actual = [object[@"hugeNumber"] longLongValue];
    XCTAssertEqual(expected, actual, @"The number should be parsed correctly.");
}

@end
