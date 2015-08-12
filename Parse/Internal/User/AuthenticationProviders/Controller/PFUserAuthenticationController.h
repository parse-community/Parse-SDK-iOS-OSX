/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFAuthenticationProvider.h"

NS_ASSUME_NONNULL_BEGIN

@class BFTask;
@class PFUser;

@interface PFUserAuthenticationController : NSObject

///--------------------------------------
/// @name Authentication Providers
///--------------------------------------

- (void)registerAuthenticationProvider:(id<PFAuthenticationProvider>)provider;
- (void)unregisterAuthenticationProvider:(id<PFAuthenticationProvider>)provider;

- (id<PFAuthenticationProvider>)authenticationProviderForAuthType:(NSString *)authType;

///--------------------------------------
/// @name Authentication
///--------------------------------------

- (BFTask *)authenticateAsyncWithProviderForAuthType:(NSString *)authType;
- (BFTask *)deauthenticateAsyncWithProviderForAuthType:(NSString *)authType;

- (BOOL)restoreAuthenticationWithAuthData:(nullable NSDictionary *)authData
                  withProviderForAuthType:(NSString *)authType;

///--------------------------------------
/// @name Log In
///--------------------------------------

- (BFTask *)logInUserAsyncWithAuthType:(NSString *)authType;
- (BFTask *)logInUserAsyncWithAuthType:(NSString *)authType authData:(NSDictionary *)authData;

///--------------------------------------
/// @name Link
///--------------------------------------

- (BFTask *)linkUserAsync:(PFUser *)user withAuthType:(NSString *)authType;
- (BFTask *)linkUserAsync:(PFUser *)user withAuthType:(NSString *)authType authData:(NSDictionary *)authData;

@end

NS_ASSUME_NONNULL_END
