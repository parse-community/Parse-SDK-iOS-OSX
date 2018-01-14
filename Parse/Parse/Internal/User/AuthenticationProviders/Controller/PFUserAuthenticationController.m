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
#import "PFCurrentUserController.h"
#import "PFAssert.h"

@interface PFUserAuthenticationController () {
    dispatch_queue_t _dataAccessQueue;
    NSMutableDictionary<NSString *, id<PFUserAuthenticationDelegate>>*_authenticationDelegates;
}

@end

@implementation PFUserAuthenticationController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFCurrentUserControllerProvider, PFUserControllerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;
    _dataAccessQueue = dispatch_queue_create("com.parse.user.authenticationManager", DISPATCH_QUEUE_SERIAL);
    _authenticationDelegates = [NSMutableDictionary dictionary];

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFCurrentUserControllerProvider, PFUserControllerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Authentication Providers
///--------------------------------------

- (void)registerAuthenticationDelegate:(id<PFUserAuthenticationDelegate>)delegate forAuthType:(NSString *)authType {
    PFParameterAssert(delegate, @"Authentication delegate can't be `nil`.");
    PFParameterAssert(authType, @"`authType` can't be `nil`.");
    PFConsistencyAssert(![self authenticationDelegateForAuthType:authType],
                        @"Authentication delegate already registered for authType `%@`.", authType);

    dispatch_sync(_dataAccessQueue, ^{
        _authenticationDelegates[authType] = delegate;
    });

    // TODO: (nlutsenko) Decouple this further.
    [[self.dataSource.currentUserController getCurrentUserAsyncWithOptions:0] continueWithSuccessBlock:^id(BFTask *task) {
        PFUser *user = task.result;
        [user synchronizeAuthDataWithAuthType:authType];
        return nil;
    }];
}

- (void)unregisterAuthenticationDelegateForAuthType:(NSString *)authType {
    if (!authType) {
        return;
    }
    dispatch_sync(_dataAccessQueue, ^{
        [_authenticationDelegates removeObjectForKey:authType];
    });
}

- (id<PFUserAuthenticationDelegate>)authenticationDelegateForAuthType:(NSString *)authType {
    if (!authType) {
        return nil;
    }

    __block id<PFUserAuthenticationDelegate> delegate = nil;
    dispatch_sync(_dataAccessQueue, ^{
        delegate = _authenticationDelegates[authType];
    });
    return delegate;
}

///--------------------------------------
#pragma mark - Authentication
///--------------------------------------

- (BFTask<NSNumber *> *)restoreAuthenticationAsyncWithAuthData:(nullable NSDictionary<NSString *, NSString *> *)authData
                                                   forAuthType:(NSString *)authType {
    id<PFUserAuthenticationDelegate> provider = [self authenticationDelegateForAuthType:authType];
    if (!provider) {
        return [BFTask taskWithResult:@YES];
    }
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id {
        return @([provider restoreAuthenticationWithAuthData:authData]);
    }];
}

- (BFTask<NSNumber *> *)deauthenticateAsyncWithAuthType:(NSString *)authType {
    return [self restoreAuthenticationAsyncWithAuthData:nil forAuthType:authType];
}

///--------------------------------------
#pragma mark - Log In
///--------------------------------------

- (BFTask<PFUser *> *)logInUserAsyncWithAuthType:(NSString *)authType
                                        authData:(NSDictionary<NSString *, NSString *> *)authData {
    return [[self.dataSource.currentUserController getCurrentUserAsyncWithOptions:0] continueWithSuccessBlock:^id(BFTask<PFUser *> *task) {
        PFUser *currentUser = task.result;
        if (currentUser && [PFAnonymousUtils isLinkedWithUser:currentUser]) {
            if (currentUser._lazy) {
                BFTask *resolveLaziness = nil;
                NSDictionary *oldAnonymousData = nil;
                @synchronized(currentUser.lock) {
                    oldAnonymousData = currentUser.authData[PFAnonymousUserAuthenticationType];

                    // Replace any anonymity with the new linked authData
                    [currentUser stripAnonymity];

                    currentUser.authData[authType] = authData;
                    [currentUser.linkedServiceNames addObject:authType];

                    resolveLaziness = [currentUser resolveLazinessAsync:[BFTask taskWithResult:nil]];
                }
                return [resolveLaziness continueWithBlock:^id(BFTask *task) {
                    if (task.cancelled || task.faulted) {
                        [currentUser.authData removeObjectForKey:authType];
                        [currentUser.linkedServiceNames removeObject:authType];
                        [currentUser restoreAnonymity:oldAnonymousData];
                        return task;
                    }
                    return task.result;
                }];
            } else {
                return [[currentUser linkWithAuthTypeInBackground:authType authData:authData] continueWithBlock:^id(BFTask *task) {
                    NSError *error = task.error;
                    if (error) {
                        if (error.code == kPFErrorAccountAlreadyLinked) {
                            // An account that's linked to the given authData already exists,
                            // so log in instead of trying to claim.
                            return [self.dataSource.userController logInCurrentUserAsyncWithAuthType:authType
                                                                                            authData:authData
                                                                                    revocableSession:[PFUser _isRevocableSessionEnabled]];
                        } else {
                            return task;
                        }
                    }
                    return currentUser;
                }];
            }
        }
        return [self.dataSource.userController logInCurrentUserAsyncWithAuthType:authType
                                                                        authData:authData
                                                                revocableSession:[PFUser _isRevocableSessionEnabled]];
    }];
}

@end
