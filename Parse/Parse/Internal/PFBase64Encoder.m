/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFBase64Encoder.h"

@implementation PFBase64Encoder

+ (NSData *)dataFromBase64String:(NSString *)string {
    if (!string) {
        return [NSData data];
    }
    return [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

+ (NSString *)base64StringFromData:(NSData *)data {
    if (!data) {
        return [NSString string];
    }
    return [data base64EncodedStringWithOptions:0];
}

@end
