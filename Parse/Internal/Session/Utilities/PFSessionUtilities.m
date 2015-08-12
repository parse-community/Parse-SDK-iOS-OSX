/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSessionUtilities.h"

@implementation PFSessionUtilities

///--------------------------------------
#pragma mark - Session Token
///--------------------------------------

+ (BOOL)isSessionTokenRevocable:(NSString *)sessionToken {
    return (sessionToken && [sessionToken rangeOfString:@"r:"].location != NSNotFound);
}

@end
