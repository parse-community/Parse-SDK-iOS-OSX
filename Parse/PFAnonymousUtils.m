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
#import "PFCoreManager.h"
#import "PFInternalUtils.h"
#import "PFUserAuthenticationController.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

@implementation PFAnonymousUtils

+ (PFAnonymousAuthenticationProvider *)_authenticationProvider {
    NSString *authType = [PFAnonymousAuthenticationProvider authType];

    PFUserAuthenticationController *controller = [Parse _currentManager].coreManager.userAuthenticationController;
    PFAnonymousAuthenticationProvider *provider = [controller authenticationProviderForAuthType:authType];
    if (!provider) {
        provider = [[PFAnonymousAuthenticationProvider alloc] init];
        [controller registerAuthenticationProvider:provider];
    }
    return provider;
}

+ (BOOL)isLinkedWithUser:(PFUser *)user {
    return [user.linkedServiceNames containsObject:[[[self _authenticationProvider] class] authType]];
}

+ (BFTask *)logInInBackground {
    PFUserAuthenticationController *controller = [Parse _currentManager].coreManager.userAuthenticationController;
    return [controller logInUserAsyncWithAuthType:[[[self _authenticationProvider] class] authType]];
}

+ (void)logInWithBlock:(PFUserResultBlock)block {
    [[self logInInBackground] thenCallBackOnMainThreadAsync:block];
}

+ (void)logInWithTarget:(id)target selector:(SEL)selector {
    [PFAnonymousUtils logInWithBlock:^(PFUser *user, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:user object:error];
    }];
}

+ (PFUser *)_lazyLogIn {
    PFAnonymousAuthenticationProvider *provider = [self _authenticationProvider];
    return [PFUser logInLazyUserWithAuthType:[[provider class] authType] authData:[provider authData]];
}

@end
