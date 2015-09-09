/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFUser.h>

#import "PFMacros.h"

extern NSString *const PFUserCurrentUserFileName;
extern NSString *const PFUserCurrentUserPinName;
extern NSString *const PFUserCurrentUserKeychainItemName;

@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFCommandResult;
@class PFUserController;

@interface PFUser (Private)

///--------------------------------------
/// @name Current User
///--------------------------------------
+ (BFTask *)_getCurrentUserSessionTokenAsync;
+ (NSString *)currentSessionToken;

- (void)synchronizeAllAuthData;

- (BFTask *)_handleServiceLoginCommandResult:(PFCommandResult *)result;

- (void)synchronizeAuthDataWithAuthType:(NSString *)authType;

+ (PFUser *)logInLazyUserWithAuthType:(NSString *)authType authData:(NSDictionary *)authData;
- (BFTask *)resolveLazinessAsync:(BFTask *)toAwait;
- (void)stripAnonymity;
- (void)restoreAnonymity:(id)data;

///--------------------------------------
/// @name Revocable Session
///--------------------------------------
+ (BOOL)_isRevocableSessionEnabled;
+ (void)_setRevocableSessionEnabled:(BOOL)enabled;

+ (PFUserController *)userController;

@end

// Private Properties
@interface PFUser () {
    BOOL isCurrentUser;
    NSMutableDictionary *authData;
    NSMutableSet *linkedServiceNames;
    BOOL isLazy;
}

// This earmarks the user as being an "identity" user. This will make saves write through
// to the currentUser singleton and disk object
@property (nonatomic, assign) BOOL isCurrentUser;

@property (nonatomic, strong, readonly) NSMutableDictionary *authData;
@property (nonatomic, strong, readonly) NSMutableSet *linkedServiceNames;
@property (nonatomic, assign) BOOL isLazy;

- (BOOL)_isAuthenticatedWithCurrentUser:(PFUser *)currentUser;

- (BFTask *)_logOutAsync;

///--------------------------------------
/// @name Third-party Authentication (Private)
///--------------------------------------

+ (void)_unregisterAuthenticationDelegateForAuthType:(NSString *)authType;

@end
