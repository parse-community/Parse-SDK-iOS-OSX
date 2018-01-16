/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <FBSDKLoginKit/FBSDKLoginManager.h>

#import <Parse/PFConstants.h>
#import <Parse/PFUser.h>

#import "PFFacebookAuthenticationProvider.h"

@class BFTask<__covariant BFGenericType>;

NS_ASSUME_NONNULL_BEGIN

@interface PFFacebookMobileAuthenticationProvider : PFFacebookAuthenticationProvider

@property (nonatomic, strong, readonly) FBSDKLoginManager *loginManager;

@end

NS_ASSUME_NONNULL_END
