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
@class PFFieldOperation;

NS_ASSUME_NONNULL_BEGIN

@interface PFFieldOperationDecoder : NSObject

///--------------------------------------
/// @name Init
///--------------------------------------

+ (instancetype)defaultDecoder;

///--------------------------------------
/// @name Decoding
///--------------------------------------

/*!
 Converts a parsed JSON object into a PFFieldOperation.

 @param encoded An NSDictionary containing an __op field.
 @returns An NSObject that conforms to PFFieldOperation.
 */
- (PFFieldOperation *)decode:(NSDictionary *)encoded withDecoder:(PFDecoder *)decoder;

@end

NS_ASSUME_NONNULL_END
