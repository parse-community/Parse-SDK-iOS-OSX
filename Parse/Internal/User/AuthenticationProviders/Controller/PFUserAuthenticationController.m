/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUserAuthenticationController.h"

#import "BFTask+Private.h"
#import "PFMacros.h"
#import "PFUserPrivate.h"
#import "PFObjectPrivate.h"
#import "PFAnonymousUtils.h"
#import "PFAnonymousAuthenticationProvider.h"
#import "PFUserController.h"
#import "PFAssert.h"

@interface PFUserAuthenticationController () {
    dispatch_queue_t _dataAccessQueue;
    NSMutableDictionary *_authenticationProviders;
}

@end

@implementation PFUserAuthenticationController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _dataAccessQueue = dispatch_queue_create("com.parse.user.authenticationManager", DISPATCH_QUEUE_SERIAL);
    _authenticationProviders = [NSMutableDictionary dictionary];

    return self;
}

///--------------------------------------
#pragma mark - Authentication Providers
///--------------------------------------

- (void)registerAuthenticationProvider:(id<PFAuthenticationProvider>)provider {
    PFParameterAssert(provider, @"Authentication provider can't be `nil`.");

    NSString *authType = [[provider class] authType];
    PFParameterAssert(authType, @"Authentication provider's `authType` can't be `nil`.");
    PFConsistencyAssert(![self authenticationProviderForAuthType:authType],
                        @"Authentication provider already registered for authType `%@`.", authType);

    dispatch_sync(_dataAccessQueue, ^{
        _authenticationProviders[authType] = provider;
    });

    // TODO: (nlutsenko) Decouple this further.
    if (![authType isEqualToString:@"anonymous"]) {
        [[PFUser currentUser] synchronizeAuthDataWithAuthType:authType];
    }
}

- (void)unregisterAuthenticationProvider:(id<PFAuthenticationProvider>)provider {
    NSString *authType = [[provider class] authType];
    if (!authType) {
        return;
    }
    dispatch_sync(_dataAccessQueue, ^{
        [_authenticationProviders removeObjectForKey:authType];
    });
}

- (id<PFAuthenticationProvider>)authenticationProviderForAuthType:(NSString *)authType {
    if (!authType) {
        return nil;
    }

    __block id<PFAuthenticationProvider> provider = nil;
    dispatch_sync(_dataAccessQueue, ^{
        provider = _authenticationProviders[authType];
    });
    return provider;
}

///--------------------------------------
#pragma mark - Authentication
///--------------------------------------

- (BFTask *)deauthenticateAsyncWithProviderForAuthType:(NSString *)authType {
    id<PFAuthenticationProvider> provider = [self authenticationProviderForAuthType:authType];
    if (provider) {
        return [provider deauthenticateInBackground];
    }
    return [BFTask taskWithResult:nil];
}

- (BFTask *)restoreAuthenticationAsyncWithAuthData:(nullable NSDictionary *)authData
                           forProviderWithAuthType:(NSString *)authType {
    id<PFAuthenticationProvider> provider = [self authenticationProviderForAuthType:authType];
    if (!provider) {
        return [BFTask taskWithResult:nil];
    }
    return [provider restoreAuthenticationInBackgroundWithAuthData:authData];
}

///--------------------------------------
#pragma mark - Log In
///--------------------------------------

- (BFTask *)logInUserAsyncWithAuthType:(NSString *)authType authData:(NSDictionary *)authData {
    //TODO: (nlutsenko) Make it fully async.
    //TODO: (nlutsenko) Inject `PFUserController` here.
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser && [PFAnonymousUtils isLinkedWithUser:currentUser]) {
        if ([currentUser isLazy]) {
            PFUser *user = currentUser;
            BFTask *resolveLaziness = nil;
            NSDictionary *oldAnonymousData = nil;
            @synchronized (user.lock) {
                oldAnonymousData = user.authData[[PFAnonymousAuthenticationProvider authType]];

                // Replace any anonymity with the new linked authData
                [user stripAnonymity];

                [user.authData setObject:authData forKey:authType];
                [user.linkedServiceNames addObject:authType];

                resolveLaziness = [user resolveLazinessAsync:[BFTask taskWithResult:nil]];
            }

            return [resolveLaziness continueAsyncWithBlock:^id(BFTask *task) {
                if (task.isCancelled || task.exception || task.error) {
                    [user.authData removeObjectForKey:authType];
                    [user.linkedServiceNames removeObject:authType];
                    [user restoreAnonymity:oldAnonymousData];
                    return task;
                }
                return task.result;
            }];
        } else {
            return [[currentUser linkWithAuthTypeInBackground:authType
                                                     authData:authData] continueAsyncWithBlock:^id(BFTask *task) {
                NSError *error = task.error;
                if (error) {
                    if (error.code == kPFErrorAccountAlreadyLinked) {
                        // An account that's linked to the given authData already exists,
                        // so log in instead of trying to claim.
                        return [[PFUser userController] logInCurrentUserAsyncWithAuthType:authType
                                                                                 authData:authData
                                                                         revocableSession:[PFUser _isRevocableSessionEnabled]];
                    } else {
                        return task;
                    }
                }

                return [BFTask taskWithResult:currentUser];
            }];
        }
    }
    return [[PFUser userController] logInCurrentUserAsyncWithAuthType:authType
                                                             authData:authData
                                                     revocableSession:[PFUser _isRevocableSessionEnabled]];

}

@end
