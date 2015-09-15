/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAnonymousUtils.h"
#import "PFAnonymousUtils_Private.h"

#import "BFTask+Private.h"
#import "PFAnonymousAuthenticationProvider.h"
#import "PFInternalUtils.h"
#import "PFUserPrivate.h"

@implementation PFAnonymousUtils

///--------------------------------------
#pragma mark - Log In
///--------------------------------------

+ (BFTask *)logInInBackground {
    PFAnonymousAuthenticationProvider *provider = [self _authenticationProvider];
    return [PFUser logInWithAuthTypeInBackground:PFAnonymousUserAuthenticationType authData:provider.authData];
}

+ (void)logInWithBlock:(PFUserResultBlock)block {
    [[self logInInBackground] thenCallBackOnMainThreadAsync:block];
}

+ (void)logInWithTarget:(id)target selector:(SEL)selector {
    [self logInWithBlock:^(PFUser *user, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:user object:error];
    }];
}

///--------------------------------------
#pragma mark - Link
///--------------------------------------

+ (BOOL)isLinkedWithUser:(PFUser *)user {
    return [user isLinkedWithAuthType:PFAnonymousUserAuthenticationType];
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

static PFAnonymousAuthenticationProvider *authenticationProvider_;

+ (dispatch_queue_t)_providerAccessQueue {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.parse.anonymousUtils.provider.access", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (PFAnonymousAuthenticationProvider *)_authenticationProvider {
    __block PFAnonymousAuthenticationProvider *provider = nil;
    dispatch_sync([self _providerAccessQueue], ^{
        provider = authenticationProvider_;
        if (!provider) {
            provider = [[PFAnonymousAuthenticationProvider alloc] init];
            [PFUser registerAuthenticationDelegate:provider forAuthType:PFAnonymousUserAuthenticationType];
            authenticationProvider_ = provider;
        }
    });
    return provider;
}

+ (void)_clearAuthenticationProvider {
    [PFUser _unregisterAuthenticationDelegateForAuthType:PFAnonymousUserAuthenticationType];
    dispatch_sync([self _providerAccessQueue], ^{
        authenticationProvider_ = nil;
    });
}

///--------------------------------------
#pragma mark - Lazy Login
///--------------------------------------

+ (PFUser *)_lazyLogIn {
    PFAnonymousAuthenticationProvider *provider = [self _authenticationProvider];
    return [PFUser logInLazyUserWithAuthType:PFAnonymousUserAuthenticationType authData:provider.authData];
}

@end
