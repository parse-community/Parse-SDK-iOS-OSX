/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#if __has_include(<Bolts/BFTask.h>)
#import <Bolts/BFTask.h>
#else
#import "BFTask.h"
#endif

#import "PFConstants.h"

NS_ASSUME_NONNULL_BEGIN

/**
 The `PFCloud` class provides methods for interacting with Parse Cloud Functions.

 To be able to cancel calls, create an instance of `PFCloud`, make the calls with its instance methods,
 and cancel them with `cancel`.
 */
@interface PFCloud : NSObject

/**
 Calls the given cloud function *asynchronously* with the parameters provided.

 @param function The function name to call.
 @param parameters The parameters to send to the function.

 @return The task, that encapsulates the work being done.
 */
+ (BFTask<id> *)callFunctionInBackground:(NSString *)function
                          withParameters:(nullable NSDictionary *)parameters;

/**
 Calls the given cloud function *asynchronously* with the parameters provided
 and executes the given block when it is done.

 @param function The function name to call.
 @param parameters The parameters to send to the function.
 @param block The block to execute when the function call finished.
 It should have the following argument signature: `^(id result, NSError *error)`.
 */
+ (void)callFunctionInBackground:(NSString *)function
                  withParameters:(nullable NSDictionary *)parameters
                           block:(nullable PFIdResultBlock)block;

/**
 Calls the given cloud function *asynchronously* with the parameters provided, in a call that `cancel` can cancel.

 If the call is cancelled before it completes, the task is cancelled shortly afterwards, without waiting for
 the request to end; a cancelled task has no result and no error. A call that completes at the same time
 as it is cancelled may still have a result or error.

 @warning Cancelling only affects the client. If the request has already reached the server,
 the cloud function keeps running there and its changes are not rolled back.

 @param function The function name to call.
 @param parameters The parameters to send to the function.

 @return The task, that encapsulates the work being done.
 */
- (BFTask<id> *)callFunctionInBackground:(NSString *)function
                          withParameters:(nullable NSDictionary *)parameters;

/**
 Calls the given cloud function *asynchronously* with the parameters provided, in a call that `cancel` can cancel,
 and executes the given block when it is done, unless the call is cancelled.

 Cancelling ensures that the block won't be called, unless it is already being called. Cancel on the main thread,
 where the block is called, to be sure that the block isn't called after `cancel` returns.

 @warning Cancelling only affects the client. If the request has already reached the server,
 the cloud function keeps running there and its changes are not rolled back.

 @param function The function name to call.
 @param parameters The parameters to send to the function.
 @param block The block to execute when the function call finished.
 It should have the following argument signature: `^(id result, NSError *error)`.
 */
- (void)callFunctionInBackground:(NSString *)function
                  withParameters:(nullable NSDictionary *)parameters
                           block:(nullable PFIdResultBlock)block;

/**
 Cancels the calls made with this instance that haven't completed yet. Calls made afterwards are not affected.
 */
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
