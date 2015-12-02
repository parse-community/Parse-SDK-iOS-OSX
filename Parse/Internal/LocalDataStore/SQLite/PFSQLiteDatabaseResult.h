/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class PFSQLiteStatement;

NS_ASSUME_NONNULL_BEGIN

@interface PFSQLiteDatabaseResult : NSObject

- (instancetype)initWithStatement:(PFSQLiteStatement *)statement queue:(dispatch_queue_t)queue;

/**
 Move current result to next row. Returns true if next result exists. False if current result
 is the end of result set.
 */
- (BOOL)next;

/**
 Move the current result to next row, and returns the raw SQLite return code for the cursor.
 Useful for detecting end of cursor vs. error.
 */
- (int)step;

/**
 Closes the database result.
 */
- (BOOL)close;

///--------------------------------------
/// @name Get Column Value
///--------------------------------------

- (int)intForColumn:(NSString *)columnName;
- (int)intForColumnIndex:(int)columnIndex;

- (long)longForColumn:(NSString *)columnName;
- (long)longForColumnIndex:(int)columnIndex;

- (BOOL)boolForColumn:(NSString *)columnName;
- (BOOL)boolForColumnIndex:(int)columnIndex;

- (double)doubleForColumn:(NSString *)columnName;
- (double)doubleForColumnIndex:(int)columnIndex;

- (nullable NSString *)stringForColumn:(NSString *)columnName;
- (nullable NSString *)stringForColumnIndex:(int)columnIndex;

- (nullable NSDate *)dateForColumn:(NSString *)columnName;
- (nullable NSDate *)dateForColumnIndex:(int)columnIndex;

- (nullable NSData *)dataForColumn:(NSString *)columnName;
- (nullable NSData *)dataForColumnIndex:(int)columnIndex;

- (nullable id)objectForColumn:(NSString *)columnName;
- (nullable id)objectForColumnIndex:(int)columnIndex;

- (BOOL)columnIsNull:(NSString *)columnName;
- (BOOL)columnIndexIsNull:(int)columnIndex;

@end

NS_ASSUME_NONNULL_END
