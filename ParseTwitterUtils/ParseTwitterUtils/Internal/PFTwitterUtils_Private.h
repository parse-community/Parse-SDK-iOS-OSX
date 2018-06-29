/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTwitterUtils.h"

@class PFTwitterAuthenticationProvider;

@interface PFTwitterUtils ()

+ (PFTwitterAuthenticationProvider *)_authenticationProvider;
+ (void)_setAuthenticationProvider:(PFTwitterAuthenticationProvider *)provider;

@end
