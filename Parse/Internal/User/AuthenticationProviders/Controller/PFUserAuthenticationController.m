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

- (void)registerAuthenticationDelegate:(id<PFUserAuthenticationDelegate>)delegate forAuthType:(NSString *)authType {
    PFParameterAssert(delegate, @"Authentication delegate can't be `nil`.");
    PFParameterAssert(authType, @"Authentication provider's `authType` can't be `nil`.");
    PFConsistencyAssert(![self authenticationDelegateForAuthType:authType],
                        @"Authentication provider already registered for authType `%@`.", authType);

    dispatch_sync(_dataAccessQueue, ^{
        _authenticationProviders[authType] = delegate;
    });

    // TODO: (nlutsenko) Decouple this further.
    if (![authType isEqualToString:@"anonymous"]) {
        [[PFUser currentUser] synchronizeAuthDataWithAuthType:authType];
    }
}

- (void)unregisterAuthenticationDelegateForAuthType:(NSString *)authType {
    if (!authType) {
        return;
    }
    dispatch_sync(_dataAccessQueue, ^{
        [_authenticationProviders removeObjectForKey:authType];
    });
}

- (id<PFUserAuthenticationDelegate>)authenticationDelegateForAuthType:(NSString *)authType {
    if (!authType) {
        return nil;
    }

    __block id<PFUserAuthenticationDelegate> provider = nil;
    dispatch_sync(_dataAccessQueue, ^{
        provider = _authenticationProviders[authType];
    });
    return provider;
}

///--------------------------------------
#pragma mark - Authentication
///--------------------------------------

- (BFTask PF_GENERIC(NSNumber *)*)deauthenticateAsyncWithProviderForAuthType:(NSString *)authType {
    return [self restoreAuthenticationAsyncWithAuthData:nil forProviderWithAuthType:authType];
}

- (BFTask PF_GENERIC(NSNumber *)*)restoreAuthenticationAsyncWithAuthData:(nullable NSDictionary *)authData
                                                 forProviderWithAuthType:(NSString *)authType {
    id<PFUserAuthenticationDelegate> provider = [self authenticationDelegateForAuthType:authType];
    if (!provider) {
        return [BFTask taskWithResult:@YES];
    }
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id {
        return [BFTask taskWithResult:@([provider restoreAuthenticationWithAuthData:authData])];
    }];
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
            @synchronized(user.lock) {
                oldAnonymousData = user.authData[PFUserAnonymousAuthenticationType];

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
