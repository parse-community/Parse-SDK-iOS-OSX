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

- (BFTask *)deauthenticateAsyncWithProviderForAuthType:(NSString *)authType;

- (BFTask *)restoreAuthenticationAsyncWithAuthData:(nullable NSDictionary *)authData
                           forProviderWithAuthType:(NSString *)authType;

///--------------------------------------
/// @name Log In
///--------------------------------------

- (BFTask *)logInUserAsyncWithAuthType:(NSString *)authType authData:(NSDictionary *)authData;

@end

NS_ASSUME_NONNULL_END
