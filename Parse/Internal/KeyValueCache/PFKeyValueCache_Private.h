/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFKeyValueCache.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFKeyValueCache ()

///--------------------------------------
#pragma mark - Properties
///--------------------------------------

@property (nullable, nonatomic, strong, readwrite) NSFileManager *fileManager;
@property (nullable, nonatomic, strong, readwrite) NSCache *memoryCache;

@property (nonatomic, assign) NSUInteger maxDiskCacheBytes;
@property (nonatomic, assign) NSUInteger maxDiskCacheRecords;
@property (nonatomic, assign) NSUInteger maxMemoryCacheBytesPerRecord;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithCacheDirectoryURL:(nullable NSURL *)url
                              fileManager:(nullable NSFileManager *)fileManager
                              memoryCache:(nullable NSCache *)cache NS_DESIGNATED_INITIALIZER;

///--------------------------------------
#pragma mark - Waiting
///--------------------------------------

- (void)waitForOutstandingOperations;

@end

@interface PFKeyValueCacheEntry : NSObject

///--------------------------------------
#pragma mark - Properties
///--------------------------------------

@property (atomic, copy, readonly) NSString *value;
@property (atomic, strong, readonly) NSDate *creationTime;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)cacheEntryWithValue:(NSString *)value;
+ (instancetype)cacheEntryWithValue:(NSString *)value creationTime:(NSDate *)creationTime;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithValue:(NSString *)value;
- (instancetype)initWithValue:(NSString *)value
                 creationTime:(NSDate *)creationTime NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
