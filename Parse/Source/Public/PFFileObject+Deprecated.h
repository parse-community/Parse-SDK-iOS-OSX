/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFConstants.h>
#import <Parse/PFFileObject.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This category lists all methods of `PFFileObject` that are deprecated and will be removed in the near future.
 */
@interface PFFileObject (Deprecated)

///--------------------------------------
#pragma mark - Saving Files
///--------------------------------------

/**
 Saves the file *asynchronously* and invokes the given selector on a target.

 @param target The object to call selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.
 `[result boolValue]` will tell you whether the call succeeded or not.

 @deprecated Please use `PFFileObject.-saveInBackgroundWithBlock:` instead.
 */
- (void)saveInBackgroundWithTarget:(nullable id)target
                          selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFFileObject.-saveInBackgroundWithBlock:` instead.");

///--------------------------------------
#pragma mark - Getting Files
///--------------------------------------

/**
 *Asynchronously* gets the data from cache if available or fetches its contents from the network.

 @param target The object to call selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(NSData *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.

 @deprecated Please use `PFFileObject.-getDataInBackgroundWithBlock:` instead.
 */
- (void)getDataInBackgroundWithTarget:(nullable id)target
                             selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFFileObject.-getDataInBackgroundWithBlock:` instead.");

@end

NS_ASSUME_NONNULL_END
