/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFacebookUtils.h"

#import <Bolts/BFExecutor.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Parse/Parse.h>

#import "PFFacebookPrivateUtilities.h"

#if TARGET_OS_IOS
#import "PFFacebookMobileAuthenticationProvider.h"
#elif TARGET_OS_TV
#import "PFFacebookDeviceAuthenticationProvider.h"
#endif

@implementation PFFacebookUtils

///--------------------------------------
#pragma mark - Authentication Provider
///--------------------------------------

static PFFacebookAuthenticationProvider *authenticationProvider_;

+ (void)_assertFacebookInitialized {
    if (!authenticationProvider_) {
        [NSException raise:NSInternalInconsistencyException format:@"You must initialize PFFacebookUtils with a call to +initializeFacebookWithApplicationLaunchOptions"];
    }
}

+ (PFFacebookAuthenticationProvider *)_authenticationProvider {
    return authenticationProvider_;
}

+ (void)_setAuthenticationProvider:(PFFacebookAuthenticationProvider *)provider {
    authenticationProvider_ = provider;
}

///--------------------------------------
#pragma mark - Interacting With Facebook
///--------------------------------------

+ (void)initializeFacebookWithApplicationLaunchOptions:(NSDictionary *)launchOptions {
    if (![Parse currentConfiguration]) {
        // TODO: (nlutsenko) Remove this when Parse SDK throws on every access to Parse._currentManager
        [NSException raise:NSInternalInconsistencyException format:@"PFFacebookUtils must be initialized after initializing Parse."];
    }
    if (!authenticationProvider_) {
        Class providerClass = nil;
#if TARGET_OS_IOS
        providerClass = [PFFacebookMobileAuthenticationProvider class];
#elif TARGET_OS_TV
        providerClass = [PFFacebookDeviceAuthenticationProvider class];
#endif
        PFFacebookAuthenticationProvider *provider = [providerClass providerWithApplication:[UIApplication sharedApplication]
                                                                              launchOptions:launchOptions];
        [PFUser registerAuthenticationDelegate:provider forAuthType:PFFacebookUserAuthenticationType];

        [self _setAuthenticationProvider:provider];
    }
}

#pragma mark iOS
#if TARGET_OS_IOS

+ (FBSDKLoginManager *)facebookLoginManager {
    PFFacebookMobileAuthenticationProvider *provider = (PFFacebookMobileAuthenticationProvider *)[self _authenticationProvider];
    return provider.loginManager;
}

#endif

///--------------------------------------
#pragma mark - Logging In
///--------------------------------------

+ (BFTask<PFUser *> *)logInInBackgroundWithReadPermissions:(nullable NSArray<NSString *> *)permissions {
    return [self _logInAsyncWithReadPermissions:permissions publishPermissions:nil];
}

+ (void)logInInBackgroundWithReadPermissions:(nullable NSArray<NSString *> *)permissions
                                       block:(nullable PFUserResultBlock)block {
    [[self logInInBackgroundWithReadPermissions:permissions] pffb_continueWithMainThreadUserBlock:block];
}

+ (BFTask *)logInInBackgroundWithPublishPermissions:(nullable NSArray<NSString *> *)permissions {
    return [self _logInAsyncWithReadPermissions:nil publishPermissions:permissions];
}

+ (void)logInInBackgroundWithPublishPermissions:(nullable NSArray<NSString *> *)permissions
                                          block:(nullable PFUserResultBlock)block {
    [[self logInInBackgroundWithPublishPermissions:permissions] pffb_continueWithMainThreadUserBlock:block];
}

+ (BFTask<PFUser *> *)_logInAsyncWithReadPermissions:(NSArray<NSString *> *)readPermissions
                                  publishPermissions:(NSArray<NSString *> *)publishPermissions {
    [self _assertFacebookInitialized];

    PFFacebookAuthenticationProvider *provider = [self _authenticationProvider];
    return [[provider authenticateAsyncWithReadPermissions:readPermissions
                                        publishPermissions:publishPermissions] continueWithSuccessBlock:^id(BFTask *task) {
        return [PFUser logInWithAuthTypeInBackground:PFFacebookUserAuthenticationType authData:task.result];
    }];
}

+ (BFTask<PFUser *> *)logInInBackgroundWithAccessToken:(FBSDKAccessToken *)accessToken {
    [self _assertFacebookInitialized];

    NSDictionary *authData = [PFFacebookPrivateUtilities userAuthenticationDataFromAccessToken:accessToken];
    if (!authData) {
        return [BFTask taskWithError:[NSError pffb_invalidFacebookSessionError]];
    }
    return [[PFUser logInWithAuthTypeInBackground:PFFacebookUserAuthenticationType
                                         authData:authData] continueWithSuccessBlock:^id(BFTask *task) {
        [FBSDKAccessToken setCurrentAccessToken:accessToken];
        return task; // Return the same result.
    }];
}

+ (void)logInInBackgroundWithAccessToken:(FBSDKAccessToken *)accessToken
                                   block:(nullable PFUserResultBlock)block {
    [[self logInInBackgroundWithAccessToken:accessToken] pffb_continueWithMainThreadUserBlock:block];
}

///--------------------------------------
#pragma mark - Linking Users
///--------------------------------------

+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user
                         withReadPermissions:(nullable NSArray<NSString *> *)permissions {
    return [self _linkUserAsync:user withReadPermissions:permissions publishPermissions:nil];
}

+ (void)linkUserInBackground:(PFUser *)user
         withReadPermissions:(nullable NSArray<NSString *> *)permissions
                       block:(nullable PFBooleanResultBlock)block {
    [[self linkUserInBackground:user withReadPermissions:permissions] pffb_continueWithMainThreadBooleanBlock:block];
}

+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user
                      withPublishPermissions:(NSArray<NSString *> *)permissions {
    return [self _linkUserAsync:user withReadPermissions:nil publishPermissions:permissions];
}

+ (void)linkUserInBackground:(PFUser *)user
      withPublishPermissions:(NSArray<NSString *> *)permissions
                       block:(nullable PFBooleanResultBlock)block {
    [[self linkUserInBackground:user withPublishPermissions:permissions] pffb_continueWithMainThreadBooleanBlock:block];
}

+ (BFTask<NSNumber *> *)linkUserInBackground:(PFUser *)user withAccessToken:(FBSDKAccessToken *)accessToken {
    [self _assertFacebookInitialized];

    NSDictionary *authData = [PFFacebookPrivateUtilities userAuthenticationDataFromAccessToken:accessToken];
    if (!authData) {
        return [BFTask taskWithError:[NSError pffb_invalidFacebookSessionError]];
    }
    return [user linkWithAuthTypeInBackground:PFFacebookUserAuthenticationType authData:authData];
}

+ (void)linkUserInBackground:(PFUser *)user
             withAccessToken:(FBSDKAccessToken *)accessToken
                       block:(nullable PFBooleanResultBlock)block {
    [[self linkUserInBackground:user withAccessToken:accessToken] pffb_continueWithMainThreadBooleanBlock:block];
}

+ (BFTask *)_linkUserAsync:(PFUser *)user
       withReadPermissions:(nullable NSArray<NSString *> *)readPermissions
        publishPermissions:(nullable NSArray<NSString *> *)publishPermissions {
    [self _assertFacebookInitialized];

    PFFacebookAuthenticationProvider *authenticationProvider = [self _authenticationProvider];
    return [[authenticationProvider authenticateAsyncWithReadPermissions:readPermissions
                                                      publishPermissions:publishPermissions] continueWithSuccessBlock:^id(BFTask *task) {
        return [user linkWithAuthTypeInBackground:PFFacebookUserAuthenticationType authData:task.result];
    }];
}

///--------------------------------------
#pragma mark - Unlinking
///--------------------------------------

+ (BFTask<NSNumber *> *)unlinkUserInBackground:(PFUser *)user {
    [self _assertFacebookInitialized];
    return [user unlinkWithAuthTypeInBackground:PFFacebookUserAuthenticationType];
}

+ (void)unlinkUserInBackground:(PFUser *)user block:(nullable PFBooleanResultBlock)block {
    [[self unlinkUserInBackground:user] pffb_continueWithMainThreadBooleanBlock:block];
}

///--------------------------------------
#pragma mark - Getting Linked State
///--------------------------------------

+ (BOOL)isLinkedWithUser:(PFUser *)user {
    return [user isLinkedWithAuthType:PFFacebookUserAuthenticationType];
}

@end
