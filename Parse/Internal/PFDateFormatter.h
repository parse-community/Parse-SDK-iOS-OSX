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

@interface PFDateFormatter : NSObject

+ (instancetype)sharedFormatter;

///--------------------------------------
/// @name String from Date
///--------------------------------------

/*!
 Converts `NSDate` into `NSString` representation using the following format: yyyy-MM-dd'T'HH:mm:ss.SSS'Z'

 @param date `NSDate` to convert.

 @returns Formatted `NSString` representation.
 */
- (NSString *)preciseStringFromDate:(NSDate *)date;

///--------------------------------------
/// @name Date from String
///--------------------------------------

/*!
 Converts `NSString` representation of a date into `NSDate` object.

 @discussion Following date formats are supported:
 YYYY-MM-DD
 YYYY-MM-DD HH:MM'Z'
 YYYY-MM-DD HH:MM:SS'Z'
 YYYY-MM-DD HH:MM:SS.SSS'Z'
 YYYY-MM-DDTHH:MM'Z'
 YYYY-MM-DDTHH:MM:SS'Z'
 YYYY-MM-DDTHH:MM:SS.SSS'Z'

 @param string `NSString` representation to convert.

 @returns `NSDate` incapsulating the date.
 */
- (NSDate *)dateFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
