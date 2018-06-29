/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PFKeyValueCache : NSObject

@property (nonatomic, copy, readonly) NSString *cacheDirectoryPath;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCacheDirectoryPath:(NSString *)path;

///--------------------------------------
#pragma mark - Setting
///--------------------------------------

- (void)setObject:(NSString *)object forKey:(NSString *)key;
- (void)setObject:(NSString *)object forKeyedSubscript:(NSString *)key;

///--------------------------------------
#pragma mark - Getting
///--------------------------------------

- (nullable NSString *)objectForKey:(NSString *)key maxAge:(NSTimeInterval)age;

///--------------------------------------
#pragma mark - Removing
///--------------------------------------

- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
