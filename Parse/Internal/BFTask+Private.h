/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTask.h>

#import "PFInternalUtils.h"

@interface BFExecutor (Background)

+ (instancetype)defaultPriorityBackgroundExecutor;

@end

@interface BFTask (Private)

- (instancetype)continueAsyncWithBlock:(BFContinuationBlock)block;
- (instancetype)continueAsyncWithSuccessBlock:(BFContinuationBlock)block;

- (instancetype)continueWithResult:(id)result;
- (instancetype)continueWithSuccessResult:(id)result;

- (instancetype)continueWithMainThreadResultBlock:(PFIdResultBlock)resultBlock
                               executeIfCancelled:(BOOL)executeIfCancelled;
- (instancetype)continueWithMainThreadBooleanResultBlock:(PFBooleanResultBlock)resultBlock
                                      executeIfCancelled:(BOOL)executeIfCancelled;

/*!
 Adds a continuation to the task that will run the given block on the main
 thread sometime after this task has finished. If the task was cancelled,
 the block will never be called. If the task had an exception, the exception
 will be throw on the main thread instead of running the block. Otherwise,
 the block will be given the result and error of this task.
 @returns A new task that will be finished once the block has run.
 */
- (BFTask *)thenCallBackOnMainThreadAsync:(void(^)(id result, NSError *error))block;

/*!
 Identical to thenCallBackOnMainThreadAsync:, except that the result of a successful
 task will be converted to a BOOL using the boolValue method, and that will
 be passed to the block instead of the original result.
 */
- (BFTask *)thenCallBackOnMainThreadWithBoolValueAsync:(void(^)(BOOL result, NSError *error))block;

/*!
 Same as `waitForResult:error withMainThreadWarning:YES`
 */
- (id)waitForResult:(NSError **)error;

/*!
 Waits until this operation is completed, then returns its value.
 This method is inefficient and consumes a thread resource while its running.

 @param error          If an error occurs, upon return contains an `NSError` object that describes the problem.
 @param warningEnabled `BOOL` value that

 @return Returns a `self.result` if task completed. `nil` - if cancelled.
 */
- (id)waitForResult:(NSError **)error withMainThreadWarning:(BOOL)warningEnabled;

@end

extern void forceLoadCategory_BFTask_Private();
