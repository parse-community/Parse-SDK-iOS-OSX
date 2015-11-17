/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSQLiteDatabaseResult.h"

#import <sqlite3.h>

#import "PFSQLiteStatement.h"
#import "PFThreadsafety.h"

@interface PFSQLiteDatabaseResult ()

@property (nonatomic, copy, readonly) NSDictionary *columnNameToIndexMap;
@property (nonatomic, strong, readonly) PFSQLiteStatement *statement;
@property (nonatomic, strong, readonly) dispatch_queue_t databaseQueue;

@end

@implementation PFSQLiteDatabaseResult

@synthesize columnNameToIndexMap = _columnNameToIndexMap;

- (instancetype)initWithStatement:(PFSQLiteStatement *)stmt queue:(dispatch_queue_t)queue {
    if ((self = [super init])) {
        _statement = stmt;
        _databaseQueue = queue;
    }
    return self;
}

- (BOOL)next {
    return [self step] == SQLITE_ROW;
}

- (int)step {
    return PFThreadSafetyPerform(_databaseQueue, ^{
        return sqlite3_step([self.statement sqliteStatement]);
    });
}

- (BOOL)close {
    return [self.statement close];
}

- (int)intForColumn:(NSString *)columnName {
    return [self intForColumnIndex:[self columnIndexForName:columnName]];
}

- (int)intForColumnIndex:(int)columnIndex {
    return PFThreadSafetyPerform(_databaseQueue, ^{
        return sqlite3_column_int([self.statement sqliteStatement], columnIndex);
    });
}

- (long)longForColumn:(NSString *)columnName {
    return [self longForColumnIndex:[self columnIndexForName:columnName]];
}

- (long)longForColumnIndex:(int)columnIndex {
    return PFThreadSafetyPerform(_databaseQueue, ^{
        return (long)sqlite3_column_int64([self.statement sqliteStatement], columnIndex);
    });
}

- (BOOL)boolForColumn:(NSString *)columnName {
    return [self boolForColumnIndex:[self columnIndexForName:columnName]];
}

- (BOOL)boolForColumnIndex:(int)columnIndex {
    return PFThreadSafetyPerform(_databaseQueue, ^BOOL{
        return ([self intForColumnIndex:columnIndex] != 0);
    });
}

- (double)doubleForColumn:(NSString *)columnName {
    return [self doubleForColumnIndex:[self columnIndexForName:columnName]];
}

- (double)doubleForColumnIndex:(int)columnIndex {
    return PFThreadSafetyPerform(_databaseQueue, ^{
        return sqlite3_column_double([self.statement sqliteStatement], columnIndex);
    });
}

- (NSString *)stringForColumn:(NSString *)columnName {
    return [self stringForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSString *)stringForColumnIndex:(int)columnIndex {
    return PFThreadSafetyPerform(_databaseQueue, ^NSString *{
        if ([self columnIndexIsNull:columnIndex]) {
            return nil;
        }

        const char *str = (const char *)sqlite3_column_text([self.statement sqliteStatement], columnIndex);
        if (!str) {
            return nil;
        }
        return [NSString stringWithUTF8String:str];
    });
}

- (NSDate *)dateForColumn:(NSString *)columnName {
    return [self dateForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSDate *)dateForColumnIndex:(int)columnIndex {
    // TODO: (nlutsenko) probably use formatter
    return [NSDate dateWithTimeIntervalSince1970:[self doubleForColumnIndex:columnIndex]];
}

- (NSData *)dataForColumn:(NSString *)columnName {
    return [self dataForColumnIndex:[self columnIndexForName:columnName]];
}

- (NSData *)dataForColumnIndex:(int)columnIndex {
    return PFThreadSafetyPerform(_databaseQueue, ^NSData *{
        if ([self columnIndexIsNull:columnIndex]) {
            return nil;
        }

        int size = sqlite3_column_bytes([self.statement sqliteStatement], columnIndex);
        const char *buffer = sqlite3_column_blob([self.statement sqliteStatement], columnIndex);
        if (buffer == nil) {
            return nil;
        }
        return [NSData dataWithBytes:buffer length:size];
    });
}

- (id)objectForColumn:(NSString *)columnName {
    return [self objectForColumnIndex:[self columnIndexForName:columnName]];
}

- (id)objectForColumnIndex:(int)columnIndex {
    return PFThreadSafetyPerform(_databaseQueue, ^id{
        int columnType = sqlite3_column_type([self.statement sqliteStatement], columnIndex);
        switch (columnType) {
            case SQLITE_INTEGER:
                return @([self longForColumnIndex:columnIndex]);
            case SQLITE_FLOAT:
                return @([self doubleForColumnIndex:columnIndex]);
            case SQLITE_BLOB:
                return [self dataForColumnIndex:columnIndex];
            default:
                return [self stringForColumnIndex:columnIndex];
        }
    });
}

- (BOOL)columnIsNull:(NSString *)columnName {
    return [self columnIndexIsNull:[self columnIndexForName:columnName]];
}

- (BOOL)columnIndexIsNull:(int)columnIndex {
    return PFThreadSafetyPerform(_databaseQueue, ^BOOL{
        return (sqlite3_column_type([self.statement sqliteStatement], columnIndex) == SQLITE_NULL);
    });
}

- (int)columnIndexForName:(NSString *)columnName {
    NSNumber *index = self.columnNameToIndexMap[[columnName lowercaseString]];
    if (index) {
        return [index intValue];
    }
    // not found
    return -1;
}

- (NSDictionary *)columnNameToIndexMap {
    if (!_columnNameToIndexMap) {
        PFThreadsafetySafeDispatchSync(_databaseQueue, ^{
            int columnCount = sqlite3_column_count([self.statement sqliteStatement]);
            NSMutableDictionary *mutableColumnNameToIndexMap = [[NSMutableDictionary alloc] initWithCapacity:columnCount];
            for (int i = 0; i < columnCount; ++i) {
                NSString *key = [NSString stringWithUTF8String:sqlite3_column_name([self.statement sqliteStatement], i)];
                mutableColumnNameToIndexMap[[key lowercaseString]] = @(i);
            }
            _columnNameToIndexMap = mutableColumnNameToIndexMap;
        });
    }
    return _columnNameToIndexMap;
}

@end
