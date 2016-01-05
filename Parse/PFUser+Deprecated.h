/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFConstants.h>
#import <Parse/PFUser.h>

NS_ASSUME_NONNULL_BEGIN

/**
 This category lists all methods of `PFUser` that are deprecated and will be removed in the near future.
 */
@interface PFUser (Deprecated)

///--------------------------------------
#pragma mark - Creating a New User
///--------------------------------------

/**
 Signs up the user *asynchronously*.

 This will also enforce that the username isn't already taken.

 @warning Make sure that password and username are set before calling this method.

 @param target Target object for the selector.
 @param selector The selector that will be called when the asynchrounous request is complete.
 It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.
 `[result boolValue]` will tell you whether the call succeeded or not.

 @deprecated Please use `PFUser.-signUpInBackgroundWithBlock:` instead.
 */
- (void)signUpInBackgroundWithTarget:(nullable id)target
                            selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFUser.-signUpInBackgroundWithBlock:` instead.");

///--------------------------------------
#pragma mark - Logging In
///--------------------------------------

/**
 Makes an *asynchronous* request to login a user with specified credentials.

 Returns an instance of the successfully logged in `PFUser`.
 This also caches the user locally so that calls to `+currentUser` will use the latest logged in user.

 @param username The username of the user.
 @param password The password of the user.
 @param target Target object for the selector.
 @param selector The selector that will be called when the asynchrounous request is complete.
 It should have the following signature: `(void)callbackWithUser:(PFUser *)user error:(NSError *)error`.

 @deprecated Please use `PFUser.+logInWithUsernameInBackground:password:block:` instead.
 */
+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
                               target:(nullable id)target
                             selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFUser.+logInWithUsernameInBackground:password:block:` instead.");

///--------------------------------------
#pragma mark - Becoming a User
///--------------------------------------

/**
 Makes an *asynchronous* request to become a user with the given session token.

 Returns an instance of the successfully logged in `PFUser`. This also caches the user locally
 so that calls to `+currentUser` will use the latest logged in user.

 @param sessionToken The session token for the user.
 @param target Target object for the selector.
 @param selector The selector that will be called when the asynchrounous request is complete.
 It should have the following signature: `(void)callbackWithUser:(PFUser *)user error:(NSError *)error`.

 @deprecated Please use `PFUser.+becomeInBackground:block:` instead.
 */
+ (void)becomeInBackground:(NSString *)sessionToken
                    target:(nullable id)target
                  selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFUser.+becomeInBackground:block:` instead.");

///--------------------------------------
#pragma mark - Requesting a Password Reset
///--------------------------------------

/**
 Send a password reset request *asynchronously* for a specified email and sets an error object.

 If a user account exists with that email, an email will be sent to that address
 with instructions on how to reset their password.

 @param email Email of the account to send a reset password request.
 @param target Target object for the selector.
 @param selector The selector that will be called when the asynchronous request is complete.
 It should have the following signature: `(void)callbackWithResult:(NSNumber *)result error:(NSError *)error`.
 `error` will be `nil` on success and set if there was an error.
 `[result boolValue]` will tell you whether the call succeeded or not.

 @deprecated Please use `PFUser.+requestPasswordResetForEmailInBackground:block:` instead.
 */
+ (void)requestPasswordResetForEmailInBackground:(NSString *)email
                                          target:(nullable id)target
                                        selector:(nullable SEL)selector PARSE_DEPRECATED("Please use `PFUser.+requestPasswordResetForEmailInBackground:block:` instead.");

@end

NS_ASSUME_NONNULL_END
