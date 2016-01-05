/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFConstants.h>
#import <Parse/PFQuery.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This category lists all methods of `PFQuery` that are deprecated and will be removed in the near future.
 */
@interface PFQuery (Deprecated)

///--------------------------------------
#pragma mark - Getting Objects by ID
///--------------------------------------

/**
 Gets a `PFObject` asynchronously.

 This mutates the PFQuery. It will reset limit to `1`, skip to `0` and remove all conditions, leaving only `objectId`.

 @param objectId The id of the object being requested.
 @param target The target for the callback selector.
 @param selector The selector for the callback.
 It should have the following signature: `(void)callbackWithResult:(id)result error:(NSError *)error`.
 Result will be `nil` if error is set and vice versa.

 @deprecated Please use `PFQuery.-getObjectInBackgroundWithId:block:` instead.
 */
- (void)getObjectInBackgroundWithId:(NSString *)objectId
                             target:(nullable id)target
                           selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFQuery.-getObjectInBackgroundWithId:block:` instead.");

///--------------------------------------
#pragma mark - Getting all Matches for a Query
///--------------------------------------

/**
 Finds objects *asynchronously* and calls the given callback with the results.

 @param target The object to call the selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(id)result error:(NSError *)error`.
 Result will be `nil` if error is set and vice versa.

 @deprecated Please use `PFQuery.-findObjectsInBackgroundWithBlock:` instead.
 */
- (void)findObjectsInBackgroundWithTarget:(nullable id)target
                                 selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFQuery.-findObjectsInBackgroundWithBlock:` instead.");

///--------------------------------------
#pragma mark - Getting the First Match in a Query
///--------------------------------------

/**
 Gets an object *asynchronously* and calls the given callback with the results.

 @warning This method mutates the query. It will reset the limit to `1`.

 @param target The object to call the selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(PFObject *)result error:(NSError *)error`.
 `result` will be `nil` if `error` is set OR no object was found matching the query.
 `error` will be `nil` if `result` is set OR if the query succeeded, but found no results.

 @deprecated Please use `PFQuery.-getFirstObjectInBackgroundWithBlock:` instead.
 */
- (void)getFirstObjectInBackgroundWithTarget:(nullable id)target
                                    selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFQuery.-getFirstObjectInBackgroundWithBlock:` instead.");

///--------------------------------------
#pragma mark - Counting the Matches in a Query
///--------------------------------------

/**
 Counts objects *asynchronously* and calls the given callback with the count.

 @param target The object to call the selector on.
 @param selector The selector to call.
 It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError *)error`.

 @deprecated Please use `PFQuery.-countObjectsInBackgroundWithBlock:` instead.
 */
- (void)countObjectsInBackgroundWithTarget:(nullable id)target
                                  selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFQuery.-countObjectsInBackgroundWithBlock:` instead.");

@end

NS_ASSUME_NONNULL_END
