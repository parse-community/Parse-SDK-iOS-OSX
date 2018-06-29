/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@interface PFQueryUtilities : NSObject

///--------------------------------------
#pragma mark - Predicate
///--------------------------------------

/**
 Takes an arbitrary predicate and normalizes it to a form that can easily be converted to a `PFQuery`.
 */
+ (NSPredicate *)predicateByNormalizingPredicate:(NSPredicate *)predicate;

///--------------------------------------
#pragma mark - Regex
///--------------------------------------

/**
 Converts a string into a regex that matches it.

 @param string String to convert from.

 @return Query regex string from a string.
 */
+ (NSString *)regexStringForString:(NSString *)string;

///--------------------------------------
#pragma mark - Errors
///--------------------------------------

+ (NSError *)objectNotFoundError;

@end
