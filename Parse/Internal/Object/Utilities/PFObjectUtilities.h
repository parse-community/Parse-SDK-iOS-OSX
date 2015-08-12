/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PFFieldOperation;
@class PFOperationSet;

@interface PFObjectUtilities : NSObject

///--------------------------------------
/// @name Operations
///--------------------------------------

+ (id)newValueByApplyingFieldOperation:(PFFieldOperation *)operation
                          toDictionary:(NSMutableDictionary *)dictionary
                                forKey:(NSString *)key;
+ (void)applyOperationSet:(PFOperationSet *)operationSet toDictionary:(NSMutableDictionary *)dictionary;

///--------------------------------------
/// @name Equality
///--------------------------------------

+ (BOOL)isObject:(nullable id<NSObject>)objectA equalToObject:(nullable id<NSObject>)objectB;

@end

NS_ASSUME_NONNULL_END
