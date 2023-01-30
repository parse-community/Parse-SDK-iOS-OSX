/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFacebookUtilsDevice.h"
#if __has_include(<Bolts/BFExecutor.h>)
#import <Bolts/BFExecutor.h>
#else
#import "BFExecutor.h"
#endif

#if __has_include(<Parse/Parse.h>)
#import <Parse/Parse.h>
#else
#import "Parse.h"
#endif

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import "PFFacebookMobileAuthenticationProvider.h"

@implementation PFFacebookUtilsDevice

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

        providerClass = [PFFacebookMobileAuthenticationProvider class];

        PFFacebookAuthenticationProvider *provider = [providerClass providerWithApplication:[UIApplication sharedApplication]
                                                                              launchOptions:launchOptions];
        [PFUser registerAuthenticationDelegate:provider forAuthType:PFFacebookUserAuthenticationType];

        [self _setAuthenticationProvider:provider];
    }
}

+ (FBSDKLoginManager *)facebookLoginManager {
    PFFacebookMobileAuthenticationProvider *provider = (PFFacebookMobileAuthenticationProvider *)[self _authenticationProvider];
    return provider.loginManager;
}

@end
