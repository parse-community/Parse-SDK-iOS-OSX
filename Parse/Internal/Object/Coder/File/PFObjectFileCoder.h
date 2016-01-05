/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class PFDecoder;
@class PFEncoder;
@class PFObject;

NS_ASSUME_NONNULL_BEGIN

/**
 Handles encoding/decoding of `PFObject`s into a /2 JSON format.
 /2 format is only used for persisting `currentUser`, `currentInstallation` to disk when LDS is not enabled.
 */
@interface PFObjectFileCoder : NSObject

///--------------------------------------
#pragma mark - Encode
///--------------------------------------

+ (NSData *)dataFromObject:(PFObject *)object usingEncoder:(PFEncoder *)encoder;

///--------------------------------------
#pragma mark - Decode
///--------------------------------------

+ (PFObject *)objectFromData:(NSData *)data usingDecoder:(PFDecoder *)decoder;

@end

NS_ASSUME_NONNULL_END
