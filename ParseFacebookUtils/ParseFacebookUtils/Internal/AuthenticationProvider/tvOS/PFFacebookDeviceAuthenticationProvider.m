/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFacebookDeviceAuthenticationProvider.h"

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTaskCompletionSource.h>

#import <FBSDKCoreKit/FBSDKApplicationDelegate.h>
#import <FBSDKCoreKit/FBSDKAccessToken.h>
#import <FBSDKCoreKit/FBSDKConstants.h>
#import <FBSDKTVOSKit/FBSDKDeviceLoginViewController.h>

#import "PFFacebookPrivateUtilities.h"

@interface PFFacebookDeviceAuthenticationProvider () <FBSDKDeviceLoginViewControllerDelegate> {
    BFTaskCompletionSource *_loginTaskCompletionSource;
    FBSDKDeviceLoginViewController *_loginViewController;
}

@end

@implementation PFFacebookDeviceAuthenticationProvider

///--------------------------------------
#pragma mark - PFFacebookAuthenticationProvider
///--------------------------------------

- (BFTask<NSDictionary<NSString *, NSString *>*> *)authenticateAsyncWithReadPermissions:(nullable NSArray<NSString *> *)readPermissions
                                                                     publishPermissions:(nullable NSArray<NSString *> *)publishPermissions
                                                                     fromViewComtroller:(UIViewController *)viewController {
    return [BFTask taskFromExecutor:[BFExecutor mainThreadExecutor] withBlock:^id _Nonnull{
        if (_loginTaskCompletionSource) {
            return [NSError errorWithDomain:FBSDKErrorDomain
                                       code:FBSDKDialogUnavailableErrorCode
                                   userInfo:@{ NSLocalizedDescriptionKey : @"Another login attempt is already in progress." }];
        }
        _loginTaskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
        _loginViewController = [[FBSDKDeviceLoginViewController alloc] init];
        _loginViewController.delegate = self;
        _loginViewController.readPermissions = readPermissions;
        _loginViewController.publishPermissions = publishPermissions;

        [viewController presentViewController:_loginViewController animated:YES completion:nil];

        return _loginTaskCompletionSource.task;
    }];
}

///--------------------------------------
#pragma mark - PFUserAuthenticationDelegate
///--------------------------------------

- (BOOL)restoreAuthenticationWithAuthData:(nullable NSDictionary<NSString *, NSString *> *)authData {
    if (!authData) {
        [FBSDKAccessToken setCurrentAccessToken:nil];
    }
    return [super restoreAuthenticationWithAuthData:authData];
}

///--------------------------------------
#pragma mark - FBSDKDeviceLoginViewController
///--------------------------------------

- (void)deviceLoginViewControllerDidCancel:(FBSDKDeviceLoginViewController *)viewController {
    [_loginTaskCompletionSource trySetCancelled];
    _loginViewController = nil;
    _loginTaskCompletionSource = nil;
}

- (void)deviceLoginViewControllerDidFinish:(FBSDKDeviceLoginViewController *)viewController {
    FBSDKAccessToken *accessToken = [FBSDKAccessToken currentAccessToken];
    NSDictionary<NSString *,NSString*> *result = [PFFacebookPrivateUtilities userAuthenticationDataFromAccessToken:accessToken];
    [_loginTaskCompletionSource trySetResult:result];
    _loginViewController = nil;
    _loginTaskCompletionSource = nil;
}

- (void)deviceLoginViewControllerDidFail:(FBSDKDeviceLoginViewController *)viewController error:(NSError *)error {
    [_loginTaskCompletionSource trySetError:error];
    _loginViewController = nil;
    _loginTaskCompletionSource = nil;
}

@end
