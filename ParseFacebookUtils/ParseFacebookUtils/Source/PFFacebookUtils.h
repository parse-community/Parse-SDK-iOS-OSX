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

#if __has_include(<Parse/PFConstants.h>)
#import <Parse/PFConstants.h>
#import <Parse/PFUser.h>
#else
#import "PFConstants.h"
#import "PFUser.h"
#endif

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "PFFacebookAuthenticationProvider.h"

NS_ASSUME_NONNULL_BEGIN

static PFFacebookAuthenticationProvider *authenticationProvider_;

/**
 The `PFFacebookUtils` class provides utility functions for using Facebook authentication with `PFUser`s.

 @warning This class supports official Facebook iOS SDK v4.0+ and is available only on iOS.
 */
@interface PFFacebookUtils : NSObject

+ (UIViewController *)applicationTopViewController;

///--------------------------------------
/// @name User Authentication Data
///--------------------------------------

+ (NSDictionary *)userAuthenticationDataWithFacebookUserId:(NSString *)userId
                                               accessToken:(NSString *)accessToken
                                            expirationDate:(NSDate *)expirationDate;
+ (nullable NSDictionary *)userAuthenticationDataFromAccessToken:(FBSDKAccessToken *)token;

+ (nullable FBSDKAccessToken *)facebookAccessTokenFromUserAuthenticationData:(nullable NSDictionary<NSString *, NSString *> *)authData;


///--------------------------------------
#pragma mark - Authentication Provider
///--------------------------------------

+ (void)_assertFacebookInitialized;

+ (PFFacebookAuthenticationProvider *)_authenticationProvider;

+ (void)_setAuthenticationProvider:(PFFacebookAuthenticationProvider *)provider;
///--------------------------------------
/// @name Logging In
///--------------------------------------

/**
 *Asynchronously* logs in a user using Facebook with read permissions.

 This method delegates to the Facebook SDK to authenticate the user,
 and then automatically logs in (or creates, in the case where it is a new user) a `PFUser`.

 @param permissions Array of read permissions to use.

 @return The task that has will a have `result` set to `PFUser` if operation succeeds.
 */
+ (BFTask<PFUser *> *)logInInBackgroundWithReadPermissions:(nullable NSArray<NSString *> *)permissions;

/**
 *Asynchronously* logs in a user using Facebook with read permissions.

 This method delegates to the Facebook SDK to authenticate the user,
 and then automatically logs in (or creates, in the case where it is a new user) a `PFUser`.

 @param permissions Array of read permissions to use.
 @param block       The block to execute when the log in completes.
 It should have the following signature: `^(PFUser *user, NSError *error)`.
 */
+ (void)logInInBackgroundWithReadPermissions:(nullable NSArray<NSString *> *)permissions
                                       block:(nullable PFUserResultBlock)block;

/**
 *Asynchronously* logs in a user using Facebook with publish permissions.

 This method delegates to the Facebook SDK to authenticate the user,
 and then automatically logs in (or creates, in the case where it is a new user) a `PFUser`.

 @param permissions Array of publish permissions to use.

 @return The task that has will a have `result` set to `PFUser` if operation succeeds.
 */
+ (BFTask<PFUser *> *)logInInBackgroundWithPublishPermissions:(nullable NSArray<NSString *> *)permissions;

/**
 *Asynchronously* logs in a user using Facebook with publish permissions.

 This method delegates to the Facebook SDK to authenticate the user,
 and then automatically logs in (or creates, in the case where it is a new user) a `PFUser`.

 @param permissions Array of publish permissions to use.
 @param block       The block to execute when the log in completes.
 It should have the following signature: `^(PFUser *user, NSError *error)`.
 */
+ (void)logInInBackgroundWithPublishPermissions:(nullable NSArray<NSString *> *)permissions
                                          block:(nullable PFUserResultBlock)block;

/**
 *Asynchronously* logs in a user using given Facebook Acess Token.

 This method delegates to the Facebook SDK to authenticate the user,
 and then automatically logs in (or creates, in the case where it is a new user) a `PFUser`.

 @param accessToken An instance of `FBSDKAccessToken` to use when logging in.

 @return The task that has will a have `result` set to `PFUser` if operation succeeds.
 */
+ (BFTask<PFUser *> *)logInInBackgroundWithAccessToken:(FBSDKAccessToken *)accessToken;

/**
 *Asynchronously* logs in a user using given Facebook Acess Token.

 This method delegates to the Facebook SDK to authenticate the user,
 and then automatically logs in (or creates, in the case where it is a new user) a `PFUser`.

 @param accessToken An instance of `FBSDKAccessToken` to use when logging in.
 @param block       The block to execute when the log in completes.
 It should have the following signature: `^(PFUser *user, NSError *error)`.
 */
+ (void)logInInBackgroundWithAccessToken:(FBSDKAccessToken *)accessToken
                                   block:(nullable PFUserResultBlock)block;

///--------------------------------------
/// @name Linking Users
///--------------------------------------

/**
 *Asynchronously* links Facebook with read permissions to an existing `PFUser`.

 This method delegates to the Facebook SDK to authenticate
 the user, and then automatically links the account to the `PFUser`.
 It will also save any unsaved changes that were made to the `user`.

 @param user        User to link to Facebook.
 @param permissions Array of read permissions to use when logging in with Facebook.

 @return The task that will have a `result` set to `@YES` if operation succeeds.
 */
+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user
                                   withReadPermissions:(nullable NSArray<NSString *> *)permissions;

/**
 *Asynchronously* links Facebook with read permissions to an existing `PFUser`.

 This method delegates to the Facebook SDK to authenticate
 the user, and then automatically links the account to the `PFUser`.
 It will also save any unsaved changes that were made to the `user`.

 @param user        User to link to Facebook.
 @param permissions Array of read permissions to use.
 @param block       The block to execute when the linking completes.
 It should have the following signature: `^(BOOL succeeded, NSError *error)`.
 */
+ (void)linkUserInBackground:(PFUser *)user
         withReadPermissions:(nullable NSArray<NSString *> *)permissions
                       block:(nullable PFBooleanResultBlock)block;

/**
 *Asynchronously* links Facebook with publish permissions to an existing `PFUser`.

 This method delegates to the Facebook SDK to authenticate
 the user, and then automatically links the account to the `PFUser`.
 It will also save any unsaved changes that were made to the `user`.

 @param user        User to link to Facebook.
 @param permissions Array of publish permissions to use.

 @return The task that will have a `result` set to `@YES` if operation succeeds.
 */
+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user
                                withPublishPermissions:(NSArray<NSString *> *)permissions;

/**
 *Asynchronously* links Facebook with publish permissions to an existing `PFUser`.

 This method delegates to the Facebook SDK to authenticate
 the user, and then automatically links the account to the `PFUser`.
 It will also save any unsaved changes that were made to the `user`.

 @param user        User to link to Facebook.
 @param permissions Array of publish permissions to use.
 @param block       The block to execute when the linking completes.
 It should have the following signature: `^(BOOL succeeded, NSError *error)`.
 */
+ (void)linkUserInBackground:(PFUser *)user
      withPublishPermissions:(NSArray<NSString *> *)permissions
                       block:(nullable PFBooleanResultBlock)block;

/**
 *Asynchronously* links Facebook Access Token to an existing `PFUser`.

 This method delegates to the Facebook SDK to authenticate
 the user, and then automatically links the account to the `PFUser`.
 It will also save any unsaved changes that were made to the `user`.

 @param user        User to link to Facebook.
 @param accessToken An instance of `FBSDKAccessToken` to use.

 @return The task that will have a `result` set to `@YES` if operation succeeds.
 */
+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user withAccessToken:(FBSDKAccessToken *)accessToken;

/**
 *Asynchronously* links Facebook Access Token to an existing `PFUser`.

 This method delegates to the Facebook SDK to authenticate
 the user, and then automatically links the account to the `PFUser`.
 It will also save any unsaved changes that were made to the `user`.

 @param user        User to link to Facebook.
 @param accessToken An instance of `FBSDKAccessToken` to use.
 @param block       The block to execute when the linking completes.
 It should have the following signature: `^(BOOL succeeded, NSError *error)`.
 */
+ (void)linkUserInBackground:(PFUser *)user
             withAccessToken:(FBSDKAccessToken *)accessToken
                       block:(nullable PFBooleanResultBlock)block;

///--------------------------------------
/// @name Unlinking Users
///--------------------------------------

/**
 Unlinks the `PFUser` from a Facebook account *asynchronously*.

 @param user User to unlink from Facebook.
 @return The task, that encapsulates the work being done.
 */
+ (BFTask<NSNumber *> *)unlinkUserInBackground:(PFUser *)user;

/**
 Unlinks the `PFUser` from a Facebook account *asynchronously*.

 @param user User to unlink from Facebook.
 @param block The block to execute.
 It should have the following argument signature: `^(BOOL succeeded, NSError *error)`.
 */
+ (void)unlinkUserInBackground:(PFUser *)user block:(nullable PFBooleanResultBlock)block;

///--------------------------------------
/// @name Getting Linked State
///--------------------------------------

/**
 Whether the user has their account linked to Facebook.

 @param user User to check for a facebook link. The user must be logged in on this device.

 @return `YES` if the user has their account linked to Facebook, otherwise `NO`.
 */
+ (BOOL)isLinkedWithUser:(PFUser *)user;

@end

@interface BFTask (ParseFacebookUtils)

- (instancetype)pffb_continueWithMainThreadUserBlock:(PFUserResultBlock)block;
- (instancetype)pffb_continueWithMainThreadBooleanBlock:(PFBooleanResultBlock)block;
- (instancetype)pffb_continueWithMainThreadBlock:(BFContinuationBlock)block;

@end

@interface NSError (ParseFacebookUtils)

+ (instancetype)pffb_invalidFacebookSessionError;

@end

@interface NSDateFormatter (ParseFacebookUtils)

+ (instancetype)pffb_preciseDateFormatter;

@end

NS_ASSUME_NONNULL_END
