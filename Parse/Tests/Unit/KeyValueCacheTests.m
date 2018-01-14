/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "PFKeyValueCache_Private.h"
#import "PFMacros.h"
#import "PFTestCase.h"
#import "TestCache.h"
#import "TestFileManager.h"

@interface KeyValueCacheTests : PFTestCase
@end

@implementation KeyValueCacheTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (NSString *)sampleDirectoryPath {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"KeyValueCacheDir"];
}

- (NSURL *)sampleDirectoryURL {
    return [NSURL URLWithString:[self sampleDirectoryPath]];
}

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    PFKeyValueCache *cache = [[PFKeyValueCache alloc] initWithCacheDirectoryPath:[self sampleDirectoryPath]];
    XCTAssertNotNil(cache);
    XCTAssertEqualObjects(cache.fileManager, [NSFileManager defaultManager]);
    XCTAssertNotNil(cache.memoryCache);
    XCTAssertEqualObjects(cache.cacheDirectoryPath, [self sampleDirectoryPath]);
    XCTAssertEqual(cache.maxDiskCacheBytes, 1024 * 1024 * 10);
    XCTAssertEqual(cache.maxDiskCacheRecords, 1000);
    XCTAssertEqual(cache.maxMemoryCacheBytesPerRecord, 1024 * 1024);

    id mockedFileManager = [TestFileManager fileManager];
    OCMExpect([mockedFileManager createDirectoryAtURL:OCMOCK_ANY withIntermediateDirectories:YES attributes:nil error:NULL]);

    NSCache *mockedCache = [TestCache cache];
    cache = [[PFKeyValueCache alloc] initWithCacheDirectoryURL:[self sampleDirectoryURL]
                                                   fileManager:mockedFileManager
                                                   memoryCache:mockedCache];

    XCTAssertNotNil(cache);
    XCTAssertEqualObjects(mockedFileManager, cache.fileManager);
    XCTAssertEqualObjects(mockedCache, cache.memoryCache);
    XCTAssertEqualObjects(cache.cacheDirectoryPath, [self sampleDirectoryPath]);
    XCTAssertEqual(cache.maxDiskCacheBytes, 1024 * 1024 * 10);
    XCTAssertEqual(cache.maxDiskCacheRecords, 1000);
    XCTAssertEqual(cache.maxMemoryCacheBytesPerRecord, 1024 * 1024);
}

- (void)testBasicMemoryCaching {
    PFKeyValueCache *cache = [[PFKeyValueCache alloc] initWithCacheDirectoryURL:nil
                                                                    fileManager:nil
                                                                    memoryCache:[TestCache cache]];
    [cache setObject:@"value" forKey:@"key1"];
    [cache setObject:@"value" forKey:@"key2"];

    XCTAssertEqualObjects([cache objectForKey:@"key1" maxAge:INFINITY], @"value");
    XCTAssertEqualObjects([cache objectForKey:@"key2" maxAge:INFINITY], @"value");

    [cache removeObjectForKey:@"key1"];

    XCTAssertEqualObjects([cache objectForKey:@"key1" maxAge:INFINITY], nil);
    XCTAssertEqualObjects([cache objectForKey:@"key2" maxAge:INFINITY], @"value");
}

- (void)testBasicDiskCaching {
    NSFileManager *mockedFileManager = [TestFileManager fileManager];
    PFKeyValueCache *cache = [[PFKeyValueCache alloc] initWithCacheDirectoryURL:[self sampleDirectoryURL]
                                                                    fileManager:mockedFileManager
                                                                    memoryCache:nil];

    [cache setObject:@"value" forKey:@"key1"];
    [cache setObject:@"value" forKey:@"key2"];

    XCTAssertEqualObjects([cache objectForKey:@"key1" maxAge:INFINITY], @"value");
    XCTAssertEqualObjects([cache objectForKey:@"key2" maxAge:INFINITY], @"value");

    [cache removeObjectForKey:@"key1"];

    XCTAssertEqualObjects([cache objectForKey:@"key1" maxAge:INFINITY], nil);
    XCTAssertEqualObjects([cache objectForKey:@"key2" maxAge:INFINITY], @"value");

    [cache removeAllObjects];
}

- (void)testMemoryCacheOldEntryEviction {
    PFKeyValueCache *cache = [[PFKeyValueCache alloc] initWithCacheDirectoryURL:nil
                                                                    fileManager:nil
                                                                    memoryCache:[TestCache cache]];

    [cache setObject:@"value" forKey:@"key1"];
    XCTAssertNil([cache objectForKey:@"key1" maxAge:0]);

    [cache waitForOutstandingOperations];
}

- (void)testDiskCacheOldEntryEviction {
    NSFileManager *mockedFileManager = [TestFileManager fileManager];
    PFKeyValueCache *cache = [[PFKeyValueCache alloc] initWithCacheDirectoryURL:[self sampleDirectoryURL]
                                                                    fileManager:mockedFileManager
                                                                    memoryCache:nil];
    [cache setObject:@"value" forKey:@"key1"];
    XCTAssertNil([cache objectForKey:@"key1" maxAge:0]);

    [cache waitForOutstandingOperations];
}

- (void)testMaxFileCompaction {
    NSCache *mockedCache = [TestCache cache];
    NSFileManager *mockedFileManager = [TestFileManager fileManager];
    PFKeyValueCache *cache = [[PFKeyValueCache alloc] initWithCacheDirectoryURL:[self sampleDirectoryURL]
                                                                    fileManager:mockedFileManager
                                                                    memoryCache:mockedCache];
    cache.maxDiskCacheRecords = 1;

    [cache setObject:@"value" forKey:@"key1"];
    [cache setObject:@"value" forKey:@"key2"];

    [cache waitForOutstandingOperations];

    XCTAssertNotNil([cache objectForKey:@"key1" maxAge:INFINITY]);
    XCTAssertNotNil([cache objectForKey:@"key2" maxAge:INFINITY]);

    [mockedCache removeAllObjects];

    XCTAssertNil([cache objectForKey:@"key1" maxAge:INFINITY]);
    XCTAssertNotNil([cache objectForKey:@"key2" maxAge:INFINITY]);

    [cache waitForOutstandingOperations];
}

- (void)testMaxSizeCompaction {
    NSCache *mockedCache = [TestCache cache];
    NSFileManager *mockedFileManager = [TestFileManager fileManager];
    PFKeyValueCache *cache = [[PFKeyValueCache alloc] initWithCacheDirectoryURL:[self sampleDirectoryURL]
                                                                    fileManager:mockedFileManager
                                                                    memoryCache:mockedCache];
    cache.maxDiskCacheBytes = 5;

    [cache setObject:@"value" forKey:@"key1"];
    [cache setObject:@"value" forKey:@"key2"];

    XCTAssertNotNil([cache objectForKey:@"key1" maxAge:INFINITY]);
    XCTAssertNotNil([cache objectForKey:@"key2" maxAge:INFINITY]);

    [mockedCache removeAllObjects];

    XCTAssertNil([cache objectForKey:@"key1" maxAge:INFINITY]);
    XCTAssertNotNil([cache objectForKey:@"key2" maxAge:INFINITY]);

    [cache waitForOutstandingOperations];
}
@end
