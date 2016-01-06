/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Bolts/BFTask.h>

#import <Parse/PFConstants.h>

NS_ASSUME_NONNULL_BEGIN

@class PFConfig;

typedef void(^PFConfigResultBlock)(PFConfig *_Nullable config, NSError *_Nullable error);

/**
 `PFConfig` is a representation of the remote configuration object.
 It enables you to add things like feature gating, a/b testing or simple "Message of the day".
 */
@interface PFConfig : NSObject

///--------------------------------------
#pragma mark - Current Config
///--------------------------------------

/**
 Returns the most recently fetched config.

 If there was no config fetched - this method will return an empty instance of `PFConfig`.

 @return Current, last fetched instance of PFConfig.
 */
+ (PFConfig *)currentConfig;

///--------------------------------------
#pragma mark - Retrieving Config
///--------------------------------------

/**
 Gets the `PFConfig` *asynchronously* and sets it as a result of a task.

 @return The task, that encapsulates the work being done.
 */
+ (BFTask<PFConfig *> *)getConfigInBackground;

/**
 Gets the `PFConfig` *asynchronously* and executes the given callback block.

 @param block The block to execute.
 It should have the following argument signature: `^(PFConfig *config, NSError *error)`.
 */
+ (void)getConfigInBackgroundWithBlock:(nullable PFConfigResultBlock)block;

///--------------------------------------
#pragma mark - Parameters
///--------------------------------------

/**
 Returns the object associated with a given key.

 @param key The key for which to return the corresponding configuration value.

 @return The value associated with `key`, or `nil` if there is no such value.
 */
- (nullable id)objectForKey:(NSString *)key;

/**
 Returns the object associated with a given key.

 This method enables usage of literal syntax on `PFConfig`.
 E.g. `NSString *value = config[@"key"];`

 @see objectForKey:

 @param keyedSubscript The keyed subscript for which to return the corresponding configuration value.

 @return The value associated with `key`, or `nil` if there is no such value.
 */
- (nullable id)objectForKeyedSubscript:(NSString *)keyedSubscript;

@end

NS_ASSUME_NONNULL_END
