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
@class PFObject;

NS_ASSUME_NONNULL_BEGIN

@interface PFObjectFileCodingLogic : NSObject

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)codingLogic;

///--------------------------------------
#pragma mark - Logic
///--------------------------------------

- (void)updateObject:(PFObject *)object fromDictionary:(NSDictionary *)dictionary usingDecoder:(PFDecoder *)decoder;

@end

NS_ASSUME_NONNULL_END
