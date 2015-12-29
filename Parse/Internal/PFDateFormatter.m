/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDateFormatter.h"

#import <sqlite3.h>
#import <sys/time.h>

@interface PFDateFormatter () {
    dispatch_queue_t _synchronizationQueue;

    sqlite3 *_sqliteDatabase;
    sqlite3_stmt *_stringToDateStatement;
    sqlite3_stmt *_dateToStringStatement;
}

@end

@implementation PFDateFormatter

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)sharedFormatter {
    static PFDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[self alloc] init];
    });
    return formatter;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _synchronizationQueue = dispatch_queue_create("com.parse.dateFormatter", DISPATCH_QUEUE_SERIAL);

    //TODO: (nlutsenko) Check for error here.
    sqlite3_open(":memory:", &_sqliteDatabase);
    sqlite3_prepare_v2(_sqliteDatabase,
                       "SELECT strftime('%s', ?), strftime('%f', ?);",
                       -1,
                       &_stringToDateStatement,
                       NULL);
    sqlite3_prepare_v2(_sqliteDatabase,
                       "SELECT strftime('%Y-%m-%dT%H:%M:%fZ', ?, 'unixepoch');",
                       -1,
                       &_dateToStringStatement,
                       NULL);

    return self;
}

- (void)dealloc {
    sqlite3_finalize(_stringToDateStatement);
    sqlite3_finalize(_dateToStringStatement);
    sqlite3_close(_sqliteDatabase);
}

///--------------------------------------
#pragma mark - String from Date
///--------------------------------------

- (NSString *)preciseStringFromDate:(NSDate *)date {
    __block NSString *string = nil;
    NSTimeInterval interval = date.timeIntervalSince1970;
    dispatch_sync(_synchronizationQueue, ^{
        sqlite3_bind_double(_dateToStringStatement, 1, interval);

        if (sqlite3_step(_dateToStringStatement) == SQLITE_ROW) {
            const char *sqliteString = (const char *)sqlite3_column_text(_dateToStringStatement, 0);
            string = [NSString stringWithUTF8String:sqliteString];
        }

        sqlite3_reset(_dateToStringStatement);
    });
    return string;
}

///--------------------------------------
#pragma mark - Date from String
///--------------------------------------

- (NSDate *)dateFromString:(NSString *)string {
    __block sqlite3_int64 interval = 0;
    __block double seconds = 0.0;
    dispatch_sync(_synchronizationQueue, ^{
        const char *utf8String = string.UTF8String;

        sqlite3_bind_text(_stringToDateStatement, 1, utf8String, -1, SQLITE_STATIC);
        sqlite3_bind_text(_stringToDateStatement, 2, utf8String, -1, SQLITE_STATIC);

        if (sqlite3_step(_stringToDateStatement) == SQLITE_ROW) {
            interval = sqlite3_column_int64(_stringToDateStatement, 0);
            seconds = sqlite3_column_double(_stringToDateStatement, 1);
        }

        sqlite3_reset(_stringToDateStatement);
        sqlite3_clear_bindings(_stringToDateStatement);
    });
    // Extract the fraction component of the seconds
    double sintegral = 0.0;
    double sfraction = modf(seconds, &sintegral);

    return [NSDate dateWithTimeIntervalSince1970:(double)interval + sfraction];
}

@end
