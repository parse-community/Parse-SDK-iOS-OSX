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

#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <Parse/PFConstants.h>

#import "PFFacebookPrivateUtilities.h"

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
            taskCompletionSource.result = [PFFacebookPrivateUtilities userAuthenticationDataFromAccessToken:result.token];
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
