/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "PFFacebookMobileAuthenticationProvider.h"

@class FBSDKAccessToken;

@interface PFFacebookMobileAuthenticationProvider ()

@property (nonatomic, strong, readwrite) FBSDKLoginManager *loginManager;

@end
