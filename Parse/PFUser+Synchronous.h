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
 This category lists all methods of `PFUser` class that are synchronous, but have asynchronous counterpart,
 Calling one of these synchronous methods could potentially block the current thread for a large amount of time,
 since it might be fetching from network or saving/loading data from disk.
 */
@interface PFUser (Synchronous)

///--------------------------------------
#pragma mark - Creating a New User
///--------------------------------------

/**
 Signs up the user *synchronously*.

 This will also enforce that the username isn't already taken.

 @warning Make sure that password and username are set before calling this method.

 @return Returns `YES` if the sign up was successful, otherwise `NO`.
 */
- (BOOL)signUp PF_SWIFT_UNAVAILABLE;

/**
 Signs up the user *synchronously*.

 This will also enforce that the username isn't already taken.

 @warning Make sure that password and username are set before calling this method.

 @param error Error object to set on error.

 @return Returns whether the sign up was successful.
 */
- (BOOL)signUp:(NSError **)error;

///--------------------------------------
#pragma mark - Logging In
///--------------------------------------

/**
 Makes a *synchronous* request to login a user with specified credentials.

 Returns an instance of the successfully logged in `PFUser`.
 This also caches the user locally so that calls to `+currentUser` will use the latest logged in user.

 @param username The username of the user.
 @param password The password of the user.

 @return Returns an instance of the `PFUser` on success.
 If login failed for either wrong password or wrong username, returns `nil`.
 */
+ (nullable instancetype)logInWithUsername:(NSString *)username password:(NSString *)password PF_SWIFT_UNAVAILABLE;

/**
 Makes a *synchronous* request to login a user with specified credentials.

 Returns an instance of the successfully logged in `PFUser`.
 This also caches the user locally so that calls to `+currentUser` will use the latest logged in user.

 @param username The username of the user.
 @param password The password of the user.
 @param error The error object to set on error.

 @return Returns an instance of the `PFUser` on success.
 If login failed for either wrong password or wrong username, returns `nil`.
 */
+ (nullable instancetype)logInWithUsername:(NSString *)username password:(NSString *)password error:(NSError **)error;

///--------------------------------------
#pragma mark - Becoming a User
///--------------------------------------

/**
 Makes a *synchronous* request to become a user with the given session token.

 Returns an instance of the successfully logged in `PFUser`.
 This also caches the user locally so that calls to `+currentUser` will use the latest logged in user.

 @param sessionToken The session token for the user.

 @return Returns an instance of the `PFUser` on success.
 If becoming a user fails due to incorrect token, it returns `nil`.
 */
+ (nullable instancetype)become:(NSString *)sessionToken PF_SWIFT_UNAVAILABLE;

/**
 Makes a *synchronous* request to become a user with the given session token.

 Returns an instance of the successfully logged in `PFUser`.
 This will also cache the user locally so that calls to `+currentUser` will use the latest logged in user.

 @param sessionToken The session token for the user.
 @param error The error object to set on error.

 @return Returns an instance of the `PFUser` on success.
 If becoming a user fails due to incorrect token, it returns `nil`.
 */
+ (nullable instancetype)become:(NSString *)sessionToken error:(NSError **)error;

///--------------------------------------
#pragma mark - Logging Out
///--------------------------------------

/**
 *Synchronously* logs out the currently logged in user on disk.
 */
+ (void)logOut;

///--------------------------------------
#pragma mark - Requesting a Password Reset
///--------------------------------------

/**
 *Synchronously* Send a password reset request for a specified email.

 If a user account exists with that email, an email will be sent to that address
 with instructions on how to reset their password.

 @param email Email of the account to send a reset password request.

 @return Returns `YES` if the reset email request is successful. `NO` - if no account was found for the email address.
 */
+ (BOOL)requestPasswordResetForEmail:(NSString *)email PF_SWIFT_UNAVAILABLE;

/**
 *Synchronously* send a password reset request for a specified email and sets an error object.

 If a user account exists with that email, an email will be sent to that address
 with instructions on how to reset their password.

 @param email Email of the account to send a reset password request.
 @param error Error object to set on error.
 @return Returns `YES` if the reset email request is successful. `NO` - if no account was found for the email address.
 */
+ (BOOL)requestPasswordResetForEmail:(NSString *)email error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
