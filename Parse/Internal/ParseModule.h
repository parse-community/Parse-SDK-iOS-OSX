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

@protocol ParseModule <NSObject>

- (void)parseDidInitializeWithApplicationId:(NSString *)applicationId clientKey:(nullable NSString *)clientKey;

@end

@interface ParseModuleCollection : NSObject <ParseModule>

@property (nonatomic, assign, readonly) NSUInteger modulesCount;

- (void)addParseModule:(id<ParseModule>)module;
- (void)removeParseModule:(id<ParseModule>)module;

- (BOOL)containsModule:(id<ParseModule>)module;

@end

NS_ASSUME_NONNULL_END
