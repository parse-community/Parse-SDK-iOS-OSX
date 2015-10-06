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

@interface PFJSONSerialization : NSObject

/*!
 The object passed in must be one of:
 * NSString
 * NSNumber
 * NSDictionary
 * NSArray
 * NSNull

 @returns NSData of JSON representing the passed in object.
 */
+ (nullable NSData *)dataFromJSONObject:(id)object;

/*!
 The object passed in must be one of:
 * NSString
 * NSNumber
 * NSDictionary
 * NSArray
 * NSNull

 @returns NSString of JSON representing the passed in object.
 */
+ (nullable NSString *)stringFromJSONObject:(id)object;

/*!
 Takes a JSON string and returns the NSDictionaries and NSArrays in it.
 You should still call decodeObject if you want Parse types.
 */
+ (nullable id)JSONObjectFromData:(NSData *)data;

/*!
 Takes a JSON string and returns the NSDictionaries and NSArrays in it.
 You should still call decodeObject if you want Parse types.
 */
+ (nullable id)JSONObjectFromString:(NSString *)string;

/*!
 @abstract Takes a file path to json file and returns the NSDictionaries and NSArrays in it.

 @description You should still call decodeObject if you want Parse types.

 @param filePath File path to a file.

 @return Decoded object.
 */
+ (nullable id)JSONObjectFromFileAtPath:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
