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
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCacheDirectoryPath:(NSString *)path;

///--------------------------------------
/// @name Setting
///--------------------------------------

- (void)setObject:(NSString *)object forKey:(NSString *)key;
- (void)setObject:(NSString *)object forKeyedSubscript:(NSString *)key;

///--------------------------------------
/// @name Getting
///--------------------------------------

- (NSString *)objectForKey:(NSString *)key maxAge:(NSTimeInterval)age;

///--------------------------------------
/// @name Removing
///--------------------------------------

- (void)removeObjectForKey:(NSString *)key;
- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
