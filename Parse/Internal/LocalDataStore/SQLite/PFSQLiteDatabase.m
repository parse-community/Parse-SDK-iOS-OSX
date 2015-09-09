/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSQLiteDatabase.h"
#import "PFSQLiteDatabase_Private.h"

#import <sqlite3.h>

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFFileManager.h"
#import "PFInternalUtils.h"
#import "PFMacros.h"
#import "PFMultiProcessFileLockController.h"
#import "PFSQLiteDatabaseResult.h"
#import "PFSQLiteStatement.h"
#import "Parse_Private.h"

NSString *const PFSQLiteDatabaseBeginExclusiveOperationCommand = @"BEGIN EXCLUSIVE";
NSString *const PFSQLiteDatabaseCommitOperationCommand = @"COMMIT";
NSString *const PFSQLiteDatabaseRollbackOperationCommand = @"ROLLBACK";

NSString *const PFSQLiteDatabaseErrorSQLiteDomain = @"SQLite";
NSString *const PFSQLiteDatabaseErrorPFSQLiteDatabaseDomain = @"PFSQLiteDatabase";

int const PFSQLiteDatabaseInvalidArgumenCountErrorCode = 1;
int const PFSQLiteDatabaseInvalidSQL = 2;
int const PFSQLiteDatabaseDatabaseAlreadyOpened = 3;
int const PFSQLiteDatabaseDatabaseAlreadyClosed = 4;

@interface PFSQLiteDatabase () {
    BFTaskCompletionSource *_databaseClosedTaskCompletionSource;
    dispatch_queue_t _databaseQueue;
    BFExecutor *_databaseExecutor;
    NSMutableDictionary *_cachedStatements;
}

/*!
 Database instance
 */
@property (nonatomic, assign) sqlite3 *database;

/*!
 Database path
 */
@property (nonatomic, copy) NSString *databasePath;

@end

@implementation PFSQLiteDatabase

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (!self) return nil;

    _databaseClosedTaskCompletionSource = [[BFTaskCompletionSource alloc] init];
    _databasePath = [path copy];
    _databaseQueue = dispatch_queue_create("com.parse.sqlite.db.queue", DISPATCH_QUEUE_SERIAL);
    _databaseExecutor = [BFExecutor executorWithDispatchQueue:_databaseQueue];
    _cachedStatements = [[NSMutableDictionary alloc] init];

    return self;
}

+ (instancetype)databaseWithPath:(NSString *)path {
    return [[self alloc] initWithPath:path];
}

///--------------------------------------
#pragma mark - Connection
///--------------------------------------

- (BFTask *)isOpenAsync {
    return [BFTask taskFromExecutor:_databaseExecutor withBlock:^id {
        return @(self.database != nil);
    }];
}

- (BFTask *)openAsync {
    return [BFTask taskFromExecutor:_databaseExecutor withBlock:^id {
        if (self.database) {
            NSError *error = [self _errorWithErrorCode:PFSQLiteDatabaseDatabaseAlreadyOpened
                                          errorMessage:@"Database is opened already."
                                                domain:PFSQLiteDatabaseErrorPFSQLiteDatabaseDomain];
            return [BFTask taskWithError:error];
        }

        // Check if this database have already been opened before.
        if (_databaseClosedTaskCompletionSource.task.completed) {
            NSError *error = [self _errorWithErrorCode:PFSQLiteDatabaseDatabaseAlreadyClosed
                                          errorMessage:@"Closed database cannot be reopen."
                                                domain:PFSQLiteDatabaseErrorPFSQLiteDatabaseDomain];
            return [BFTask taskWithError:error];
        }

        // Lock the file to avoid multi-process access.
        [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:self.databasePath];

        sqlite3 *db;
        int resultCode = sqlite3_open([self.databasePath UTF8String], &db);
        if (resultCode != SQLITE_OK) {
            return [BFTask taskWithError:[self _errorWithErrorCode:resultCode]];
        }

        self.database = db;
        return [BFTask taskWithResult:nil];
    }];
}

- (BFTask *)closeAsync {
    return [BFTask taskFromExecutor:_databaseExecutor withBlock:^id {
        if (!self.database) {
            NSError *error = [self _errorWithErrorCode:PFSQLiteDatabaseDatabaseAlreadyClosed
                                          errorMessage:@"Database is closed already."
                                                domain:PFSQLiteDatabaseErrorPFSQLiteDatabaseDomain];
            return [BFTask taskWithError:error];
        }

        [self _clearCachedStatements];
        int resultCode = sqlite3_close(self.database);

        [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:self.databasePath];

        if (resultCode == SQLITE_OK) {

            self.database = nil;
            [_databaseClosedTaskCompletionSource setResult:nil];
        } else {
            // Returns error
            [_databaseClosedTaskCompletionSource setError:[self _errorWithErrorCode:resultCode]];
        }
        return _databaseClosedTaskCompletionSource.task;
    }];
}

///--------------------------------------
#pragma mark - Transaction
///--------------------------------------

- (BFTask *)beginTransactionAsync {
    return [self executeSQLAsync:PFSQLiteDatabaseBeginExclusiveOperationCommand
            withArgumentsInArray:nil];
}

- (BFTask *)commitAsync {
    return [self executeSQLAsync:PFSQLiteDatabaseCommitOperationCommand
            withArgumentsInArray:nil];
}

- (BFTask *)rollbackAsync {
    return [self executeSQLAsync:PFSQLiteDatabaseRollbackOperationCommand
            withArgumentsInArray:nil];
}

///--------------------------------------
#pragma mark - Query Methods
///--------------------------------------

- (BFTask *)_executeQueryAsync:(NSString *)sql withArgumentsInArray:(NSArray *)args cachingEnabled:(BOOL)enableCaching {
    int resultCode = 0;
    PFSQLiteStatement *statement = enableCaching ? [self _cachedStatementForQuery:sql] : nil;
    if (!statement) {
        sqlite3_stmt *sqliteStatement = nil;
        resultCode = sqlite3_prepare_v2(self.database, [sql UTF8String], -1, &sqliteStatement, 0);
        if (resultCode != SQLITE_OK) {
            sqlite3_finalize(sqliteStatement);
            return [BFTask taskWithError:[self _errorWithErrorCode:resultCode]];
        }
        statement = [[PFSQLiteStatement alloc] initWithStatement:sqliteStatement];

        if (enableCaching) {
            [self _cacheStatement:statement forQuery:sql];
        }
    } else {
        [statement reset];
    }

    // Make parameter
    int queryCount = sqlite3_bind_parameter_count([statement sqliteStatement]);
    int argumentCount = (int)[args count];
    if (queryCount != argumentCount) {
        if (!enableCaching) {
            [statement close];
        }

        NSError *error = [self _errorWithErrorCode:PFSQLiteDatabaseInvalidArgumenCountErrorCode
                                      errorMessage:@"Statement arguments count doesn't match "
                                                   @"given arguments count."
                                                domain:NSStringFromClass([self class])];
        return [BFTask taskWithError:error];
    }

    for (int idx = 0; idx < queryCount; ++idx) {
        [self _bindObject:args[idx] toColumn:(idx + 1) inStatement:statement];
    }

    PFSQLiteDatabaseResult *result = [[PFSQLiteDatabaseResult alloc] initWithStatement:statement];
    return [BFTask taskWithResult:result];
}

- (BFTask *)executeCachedQueryAsync:(NSString *)sql withArgumentsInArray:(NSArray *)args {
    return [BFTask taskFromExecutor:_databaseExecutor withBlock:^id {
        return [self _executeQueryAsync:sql withArgumentsInArray:args cachingEnabled:YES];
    }];
}

- (BFTask *)executeQueryAsync:(NSString *)sql withArgumentsInArray:(NSArray *)args {
    return [BFTask taskFromExecutor:_databaseExecutor withBlock:^id {
        return [self _executeQueryAsync:sql withArgumentsInArray:args cachingEnabled:NO];
    }];
}

- (BFTask *)executeSQLAsync:(NSString *)sql withArgumentsInArray:(NSArray *)args {
    return [BFTask taskFromExecutor:_databaseExecutor withBlock:^id {
        return [[self _executeQueryAsync:sql
                    withArgumentsInArray:args
                          cachingEnabled:NO] continueWithExecutor:[BFExecutor immediateExecutor] withSuccessBlock:^id(BFTask *task) {
            PFSQLiteDatabaseResult *databaseResult = task.result;
            int sqliteResultCode = [databaseResult step];
            [databaseResult close];

            switch (sqliteResultCode) {
                case SQLITE_DONE: {
                    return [BFTask taskWithResult:nil];
                }
                case SQLITE_ROW: {
                    NSError *error = [self _errorWithErrorCode:PFSQLiteDatabaseInvalidSQL
                                                  errorMessage:@"Cannot SELECT on executeSQLAsync."
                                                               @"Please use executeQueryAsync."
                                                        domain:NSStringFromClass([self class])];
                    return [BFTask taskWithError:error];
                }
                default: {
                    return [BFTask taskWithError:[self _errorWithErrorCode:sqliteResultCode]];
                }
            }
        }];
    }];
}

/*!
 bindObject will bind any object supported by PFSQLiteDatabase to query statement.
 Note: sqlite3 query index binding is one-based, while querying result is zero-based.
 */
- (void)_bindObject:(id)obj toColumn:(int)idx inStatement:(PFSQLiteStatement *)statement {
    if ((!obj) || ((NSNull *)obj == [NSNull null])) {
        sqlite3_bind_null([statement sqliteStatement], idx);
    } else if ([obj isKindOfClass:[NSData class]]) {
        const void *bytes = [obj bytes];
        if (!bytes) {
            // It's an empty NSData object, aka [NSData data].
            // Don't pass a NULL pointer, or sqlite will bind a SQL null instead of a blob.
            bytes = "";
        }
        sqlite3_bind_blob([statement sqliteStatement], idx, bytes, (int)[obj length], SQLITE_TRANSIENT);
    } else if ([obj isKindOfClass:[NSDate class]]) {
        sqlite3_bind_double([statement sqliteStatement], idx, [obj timeIntervalSince1970]);
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        if (CFNumberIsFloatType((__bridge CFNumberRef)obj)) {
            sqlite3_bind_double([statement sqliteStatement], idx, [obj doubleValue]);
        } else {
            sqlite3_bind_int64([statement sqliteStatement], idx, [obj longLongValue]);
        }
    } else {
        sqlite3_bind_text([statement sqliteStatement], idx, [[obj description] UTF8String], -1, SQLITE_TRANSIENT);
    }
}

///--------------------------------------
#pragma mark - Cached Statements
///--------------------------------------

- (void)_clearCachedStatements {
    for (PFSQLiteStatement *statement in [_cachedStatements allValues]) {
        [statement close];
    }

    [_cachedStatements removeAllObjects];
}

- (PFSQLiteStatement *)_cachedStatementForQuery:(NSString *)query {
    return _cachedStatements[query];
}

- (void)_cacheStatement:(PFSQLiteStatement *)statement forQuery:(NSString *)query {
    _cachedStatements[query] = statement;
}

///--------------------------------------
#pragma mark - Errors
///--------------------------------------

/*!
 Generates SQLite error. The details of the error code can be seen in: www.sqlite.org/c3ref/errcode.html
 */
- (NSError *)_errorWithErrorCode:(int)errorCode {
    return [self _errorWithErrorCode:errorCode
                        errorMessage:[NSString stringWithUTF8String:sqlite3_errmsg(self.database)]];
}

- (NSError *)_errorWithErrorCode:(int)errorCode errorMessage:(NSString *)errorMessage {
    return [self _errorWithErrorCode:errorCode
                        errorMessage:errorMessage
                              domain:PFSQLiteDatabaseErrorSQLiteDomain];
}

/*!
 Generates SQLite/PFSQLiteDatabase error.
 */
- (NSError *)_errorWithErrorCode:(int)errorCode
                    errorMessage:(NSString *)errorMessage
                          domain:(NSString *)domain {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"code"] = @(errorCode);
    result[@"error"] = errorMessage;
    return [[NSError alloc] initWithDomain:domain code:errorCode userInfo:result];
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

- (BFTask *)databaseClosedTask {
    return _databaseClosedTaskCompletionSource.task;
}

@end
