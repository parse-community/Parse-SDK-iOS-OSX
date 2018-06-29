/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFAnonymousUtils.h>
#import <Parse/PFConstants.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This category lists all methods of `PFAnonymousUtils` that are deprecated and will be removed in the near future.
 */
@interface PFAnonymousUtils (Deprecated)

///--------------------------------------
#pragma mark - Creating an Anonymous User
///--------------------------------------

/**
 Creates an anonymous user asynchronously and invokes a selector on a target.

 @param target Target object for the selector.
 @param selector The selector that will be called when the asynchronous request is complete.
 It should have the following signature: `(void)callbackWithUser:(PFUser *)user error:(NSError *)error`.

 @deprecated Please use `PFAnonymousUtils.+logInWithBlock:` instead.
 */
+ (void)logInWithTarget:(nullable id)target
               selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFAnonymousUtils.+logInWithBlock:` instead.");

@end

NS_ASSUME_NONNULL_END
