/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@interface PFBase64Encoder : NSObject

+ (NSData *)dataFromBase64String:(NSString *)string;
+ (NSString *)base64StringFromData:(NSData *)data;

@end
