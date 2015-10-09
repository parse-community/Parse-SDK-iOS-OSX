/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLConstructor.h"

#import "PFAssert.h"

@implementation PFURLConstructor

///--------------------------------------
#pragma mark - Basic
///--------------------------------------

+ (NSURL *)URLFromAbsoluteString:(NSString *)string
                            path:(nullable NSString *)path
                           query:(nullable NSString *)query {
    NSURLComponents *components = [NSURLComponents componentsWithString:string];
    if (path) {
        components.path = path;
    }
    if (query) {
        components.query = query;
    }
    return components.URL;
}

@end
