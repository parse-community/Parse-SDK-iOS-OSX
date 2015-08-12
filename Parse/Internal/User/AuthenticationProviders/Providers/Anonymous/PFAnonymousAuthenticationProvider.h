/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFAuthenticationProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFAnonymousAuthenticationProvider : NSObject <PFAuthenticationProvider>

/*!
 Gets auth data with a fresh UUID.
 */
@property (nonatomic, copy, readonly) NSDictionary *authData;

@end

NS_ASSUME_NONNULL_END
