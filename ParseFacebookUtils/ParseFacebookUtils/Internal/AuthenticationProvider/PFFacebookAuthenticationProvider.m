/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFacebookAuthenticationProvider.h"

#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKApplicationDelegate.h>

#import "PFFacebookPrivateUtilities.h"

NSString *const PFFacebookUserAuthenticationType = @"facebook";

@implementation PFFacebookAuthenticationProvider

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithApplication:(UIApplication *)application
                      launchOptions:(nullable NSDictionary *)launchOptions {
    self = [super init];
    if (!self) return self;

    [[FBSDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication]
                             didFinishLaunchingWithOptions:launchOptions];

    return self;
}

+ (instancetype)providerWithApplication:(UIApplication *)application
                          launchOptions:(nullable NSDictionary *)launchOptions {
    return [[self alloc] initWithApplication:application launchOptions:launchOptions];
}

///--------------------------------------
#pragma mark - Authenticate
///--------------------------------------

- (BFTask<NSDictionary<NSString *, NSString *>*> *)authenticateAsyncWithReadPermissions:(nullable NSArray<NSString *> *)readPermissions
                                                                     publishPermissions:(nullable NSArray<NSString *> *)publishPermissions {
    return [self authenticateAsyncWithReadPermissions:readPermissions
                                   publishPermissions:publishPermissions
                                   fromViewComtroller:[PFFacebookPrivateUtilities applicationTopViewController]];
}

- (BFTask<NSDictionary<NSString *, NSString *>*> *)authenticateAsyncWithReadPermissions:(nullable NSArray<NSString *> *)readPermissions
                                                                     publishPermissions:(nullable NSArray<NSString *> *)publishPermissions
                                                                     fromViewComtroller:(UIViewController *)viewController {
    return [BFTask taskWithError:[NSError pffb_invalidFacebookSessionError]];
}

///--------------------------------------
#pragma mark - PFUserAuthenticationDelegate
///--------------------------------------

- (BOOL)restoreAuthenticationWithAuthData:(nullable NSDictionary<NSString *, NSString *> *)authData {
    FBSDKAccessToken *token = [PFFacebookPrivateUtilities facebookAccessTokenFromUserAuthenticationData:authData];
    if (!token) {
        return !authData; // Only deauthenticate if authData was nil, otherwise - return failure (`NO`).
    }

    FBSDKAccessToken *currentToken = [FBSDKAccessToken currentAccessToken];
    // Do not reset the current token if we have the same token already set.
    if (![currentToken.userID isEqualToString:token.userID] ||
        ![currentToken.tokenString isEqualToString:token.tokenString]) {
        [FBSDKAccessToken setCurrentAccessToken:token];
    }

    return YES;
}

@end
