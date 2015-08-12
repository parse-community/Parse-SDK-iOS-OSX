/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class BFTask;

NS_ASSUME_NONNULL_BEGIN

typedef BFTask * __nonnull (^PFBlockRetryerBlock)();

/*!
 This class will retry block for a specified number of times.
 */
@interface PFBlockRetryer : NSObject

/*!
 @abstract Runs the given block repeatedly.

 @discussion Runs the given block repeatedly until either:
 - the block returns a successful task
 - the block returns a cancelled task
 - the block has been run attempts time.
 After every run of the block, it waits twice as long as the previous time,
 starting with the default initial delay.

 @returns `BFTask` which is the result of last run of the block.
 */
+ (BFTask *)retryBlock:(PFBlockRetryerBlock)block forAttempts:(NSUInteger)attempts;
+ (BFTask *)retryBlock:(PFBlockRetryerBlock)block forAttempts:(NSUInteger)attempts delay:(NSTimeInterval)delay;

///--------------------------------------
/// @name Initial Retry Delay
///--------------------------------------

+ (void)setInitialRetryDelay:(NSTimeInterval)delay;
+ (NSTimeInterval)initialRetryDelay;

@end

NS_ASSUME_NONNULL_END
