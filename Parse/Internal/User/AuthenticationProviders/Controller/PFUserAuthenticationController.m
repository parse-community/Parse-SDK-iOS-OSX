/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFUserAuthenticationController.h"

#import <Bolts/BFTask.h>

#import "PFMacros.h"
#import "PFUserPrivate.h"

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
    NSString *authType = [[provider class] authType];
    if (!authType) {
        return;
    }
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

- (BFTask *)authenticateAsyncWithProviderForAuthType:(NSString *)authType {
    id<PFAuthenticationProvider> provider = [self authenticationProviderForAuthType:authType];
    return [provider authenticateAsync];
}

- (BFTask *)deauthenticateAsyncWithProviderForAuthType:(NSString *)authType {
    id<PFAuthenticationProvider> provider = [self authenticationProviderForAuthType:authType];
    if (provider) {
        return [provider deauthenticateAsync];
    }
    return [BFTask taskWithResult:nil];
}

- (BOOL)restoreAuthenticationWithAuthData:(NSDictionary *)authData withProviderForAuthType:(NSString *)authType {
    id<PFAuthenticationProvider> provider = [self authenticationProviderForAuthType:authType];
    if (!provider) {
        return YES;
    }
    return [provider restoreAuthenticationWithAuthData:authData];
}

///--------------------------------------
#pragma mark - Log In
///--------------------------------------

- (BFTask *)logInUserAsyncWithAuthType:(NSString *)authType {
    @weakify(self);
    return [[self authenticateAsyncWithProviderForAuthType:authType] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        return [self logInUserAsyncWithAuthType:authType authData:task.result];
    }];
}

- (BFTask *)logInUserAsyncWithAuthType:(NSString *)authType authData:(NSDictionary *)authData {
    return [PFUser _logInWithAuthTypeInBackground:authType authData:authData];
}

///--------------------------------------
#pragma mark - Link
///--------------------------------------

- (BFTask *)linkUserAsync:(PFUser *)user withAuthType:(NSString *)authType {
    @weakify(self);
    return [[self authenticateAsyncWithProviderForAuthType:authType] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        return [self linkUserAsync:user withAuthType:authType authData:task.result];
    }];
}

- (BFTask *)linkUserAsync:(PFUser *)user withAuthType:(NSString *)authType authData:(NSDictionary *)authData {
    return [user _linkWithAuthTypeInBackground:authType authData:authData];
}

@end
