/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class BFTask;

/*!
 A common protocol for general Parse authentication providers.
 This interface allows for additional providers (e.g. Facebook, Twitter, etc.) to be plugged in,
 separating the service-specific authentication process from the common work
 that needs to be done to actually link the service to a user.
 */
@protocol PFAuthenticationProvider <NSObject>

/*!
 Returns a unique identifier for this service.
 This identifier must match the key in the authData hash for this provider's data on the server.
 */
+ (NSString *)authType;

/*!
 Invoked by a PFUser to authenticate with the service.  This function should call back PFUser (using the supplied blocks) to notify it of success.
 The NSDictionary passed to the success block should contain relevant authData (and should match the server's expectations of data to be used
 for verifying identity on the server).
 */
- (BFTask *)authenticateAsync;

/*!
 Invoked by a PFUser upon logOut.  Deauthenticate should be used to clear any state being kept by the provider that is associated with the logged-in user.
 */
- (BFTask *)deauthenticateAsync;

/*!
 Upon logging in (or restoring a PFUser from disk), authData is returned from the server, and the PFUser passes that data into this function,
 allowin the authentication provider to set up its internal state appropriately (e.g. setting auth tokens and keys on a service's SDK so that the SDK
 can be used immediately, without having to reauthorize).  authData can be nil, in which case the user has been unlinked, and the service should clear its
 internal state.  Returning NO from this function indicates the authData was somehow invalid, and the user should be unlinked from the provider.
 */
- (BOOL)restoreAuthenticationWithAuthData:(NSDictionary *)authData;

@end
