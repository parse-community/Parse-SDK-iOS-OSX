/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFConfig.h>
#import <Parse/PFConstants.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This category lists all methods of `PFConfig` class that are synchronous, but have asynchronous counterpart,
 Calling one of these synchronous methods could potentially block the current thread for a large amount of time,
 since it might be fetching from network or saving/loading data from disk.
 */
@interface PFConfig (Synchronous)

///--------------------------------------
#pragma mark - Retrieving Config
///--------------------------------------

/**
 Gets the `PFConfig` object *synchronously* from the server.

 @return Instance of `PFConfig` if the operation succeeded, otherwise `nil`.
 */
+ (nullable PFConfig *)getConfig PF_SWIFT_UNAVAILABLE;

/**
 Gets the `PFConfig` object *synchronously* from the server and sets an error if it occurs.

 @param error Pointer to an `NSError` that will be set if necessary.

 @return Instance of PFConfig if the operation succeeded, otherwise `nil`.
 */
+ (nullable PFConfig *)getConfig:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
