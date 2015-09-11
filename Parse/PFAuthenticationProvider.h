/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Bolts/BFTask.h>

#import <Parse/PFConstants.h>

PF_ASSUME_NONNULL_BEGIN

/*!
 Provides a general interface for delegation of third party authentication with <PFUser>s.
 */
@protocol PFAuthenticationProvider <NSObject>

/*!
 @returns Returns a unique name for the type of authentication the provider does.
 */
+ (NSString *)authType;

/*!
 @abstract Deauthenticates (logs out) the user associated with this provider.

 @returns A task that resolves to anything if deauthentication succeeded, otherwise - faulted task.
 */
- (BFTask *)deauthenticateInBackground;

/*!
 @abstract Restores authenticaiton that has been serialized, such as session keys, etc.

 @param authData The auth data for the provider. This value may be `nil` when unlinking an account.

 @returns A task that resolves to anything if authenticaiton restoration succeeded, otherwise - faulted task.
 */
- (BFTask *)restoreAuthenticationInBackgroundWithAuthData:(PF_NULLABLE NSDictionary *)authData;

@end

PF_ASSUME_NONNULL_END
