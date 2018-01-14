/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFCloud.h>
#import <Parse/PFConstants.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This category lists all methods of `PFCloud` that are deprecated and will be removed in the near future.
 */
@interface PFCloud (Deprecated)

/**
 Calls the given cloud function *asynchronously* with the parameters provided
 and then executes the given selector when it is done.

 @param function The function name to call.
 @param parameters The parameters to send to the function.
 @param target The object to call the selector on.
 @param selector The selector to call when the function call finished.
 It should have the following signature: `(void)callbackWithResult:(id)result error:(NSError *)error`.
 Result will be `nil` if error is set and vice versa.

 @deprecated Please use `PFCloud.+callFunctionInBackground:withParameters:` instead.
 */
+ (void)callFunctionInBackground:(NSString *)function
                  withParameters:(nullable NSDictionary *)parameters
                          target:(nullable id)target
                        selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFCloud.+callFunctionInBackground:withParameters:` instead.");

@end

NS_ASSUME_NONNULL_END
