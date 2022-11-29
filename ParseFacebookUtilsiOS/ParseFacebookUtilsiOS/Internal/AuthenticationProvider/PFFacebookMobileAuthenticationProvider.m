/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFacebookMobileAuthenticationProvider.h"
#import "PFFacebookMobileAuthenticationProvider_Private.h"

#if __has_include(<Bolts/BFTask.h>)
#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>
#else
#import "BFTask.h"
#import "BFTaskCompletionSource.h"
#endif

#if __has_include(<Parse/PFConstants.h>)
#import <Parse/PFConstants.h>
#else
#import "PFConstants.h"
#endif

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#if __has_include(<ParseFacebookUtilsV4/PFFacebookUtils.h>)
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#else
#import "PFFacebookUtils.h"
#endif

@implementation PFFacebookMobileAuthenticationProvider

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithApplication:(UIApplication *)application
                      launchOptions:(nullable NSDictionary *)launchOptions {
    self = [super initWithApplication:application launchOptions:launchOptions];
    if (!self) return self;

    _loginManager = [[FBSDKLoginManager alloc] init];

    return self;
}

///--------------------------------------
#pragma mark - Authenticate
///--------------------------------------

- (BFTask<NSDictionary<NSString *, NSString *>*> *)authenticateAsyncWithReadPermissions:(nullable NSArray<NSString *> *)readPermissions
                                                                     publishPermissions:(nullable NSArray<NSString *> *)publishPermissions
                                                                     fromViewComtroller:(UIViewController *)viewController {
    
    NSArray *permissions = [readPermissions arrayByAddingObjectsFromArray:publishPermissions];
                                                                       
    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    FBSDKLoginManagerLoginResultBlock resultHandler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (result.isCancelled) {
            [taskCompletionSource cancel];
        } else if (error) {
            taskCompletionSource.error = error;
        } else {
            taskCompletionSource.result = [PFFacebookUtils userAuthenticationDataFromAccessToken:result.token];
        }
    };
    
    [self.loginManager logInWithPermissions:permissions fromViewController:viewController handler:resultHandler];
    
    return taskCompletionSource.task;
}

///--------------------------------------
#pragma mark - PFUserAuthenticationDelegate
///--------------------------------------

- (BOOL)restoreAuthenticationWithAuthData:(nullable NSDictionary<NSString *, NSString *> *)authData {
    if (!authData) {
        [self.loginManager logOut];
    }
    return [super restoreAuthenticationWithAuthData:authData];
}

@end
