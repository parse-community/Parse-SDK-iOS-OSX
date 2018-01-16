/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

NS_ASSUME_NONNULL_BEGIN

@class BFTask<__covariant BFGenericType>;

/**
 The `PF_Twitter` class is a simple interface for interacting with the Twitter REST API,
 automating sign-in and OAuth signing of requests against the API.
 */
@interface PF_Twitter : NSObject

/**
 Initializes an instance of `PF_Twitter` configured to access device Twitter accounts with Accounts.framework,
 and remote access to Twitter accounts - and, if no accounts are found locally - through a built-in webview.

 After setting `consumerKey` and `consumerSecret`, authorization to Twitter accounts can be requested with
`authorizeInBackground`, and then revoked with its opposite, `deauthorizeInBackground`.
 */
- (instancetype)init;

/**
 Consumer key of the application that is used to authorize with Twitter.
 */
@property (nullable, nonatomic, copy) NSString *consumerKey;

/**
 Consumer secret of the application that is used to authorize with Twitter.
 */
@property (nullable, nonatomic, copy) NSString *consumerSecret;

/**
 Auth token for the current user.
 */
@property (nullable, nonatomic, copy) NSString *authToken;

/**
 Auth token secret for the current user.
 */
@property (nullable, nonatomic, copy) NSString *authTokenSecret;

/**
 Twitter user id of the currently signed in user.
 */
@property (nullable, nonatomic, copy) NSString *userId;

/**
 Twitter screen name of the currently signed in user.
 */
@property (nullable, nonatomic, copy) NSString *screenName;

/**
 Displays an auth dialog and populates the authToken, authTokenSecret, userId, and screenName properties
 if the Twitter user grants permission to the application.

 @return The task, that encapsulates the work being done.
 */
- (BFTask *)authorizeInBackground;

/**
 Invalidates an OAuth token for the current user, if the Twitter user has granted permission to the
 current application.

 @return The task, that encapsulates the work being done.
 */
- (BFTask *)deauthorizeInBackground;

/**
 Displays an auth dialog and populates the authToken, authTokenSecret, userId, and screenName properties
 if the Twitter user grants permission to the application.

 @param success Invoked upon successful authorization.
 @param failure Invoked upon an error occurring in the authorization process.
 @param cancel Invoked when the user cancels authorization.
 */
- (void)authorizeWithSuccess:(nullable void (^)(void))success
                     failure:(nullable void (^)(NSError *__nullable error))failure
                      cancel:(nullable void (^)(void))cancel;

/**
 Adds a 3-legged OAuth signature to an `NSMutableURLRequest` based
 upon the properties set for the Twitter object.

 Use this function to sign requests being made to the Twitter API.

 @param request Request to sign.
 */
- (void)signRequest:(nullable NSMutableURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
