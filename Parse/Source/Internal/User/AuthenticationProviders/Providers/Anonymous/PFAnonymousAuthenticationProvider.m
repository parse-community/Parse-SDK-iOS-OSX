/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAnonymousAuthenticationProvider.h"

#if SWIFT_PACKAGE
@import Bolts;
#else
#import <Bolts/BFTask.h>
#endif

NSString *const PFAnonymousUserAuthenticationType = @"anonymous";

@implementation PFAnonymousAuthenticationProvider

///--------------------------------------
#pragma mark - PFAnonymousAuthenticationProvider
///--------------------------------------

- (BOOL)restoreAuthenticationWithAuthData:(NSDictionary *)authData {
    return YES;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (NSDictionary *)authData {
    NSString *uuidString = [NSUUID UUID].UUIDString;
    uuidString = uuidString.lowercaseString;
    return @{ @"id" : uuidString };
}

@end
