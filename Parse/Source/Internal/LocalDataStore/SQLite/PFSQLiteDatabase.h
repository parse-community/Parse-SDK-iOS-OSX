/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

#import "PFMacros.h"

@class BFTask<__covariant BFGenericType>;
@class PFFileManager;
@class PFSQLiteDatabaseResult;

typedef id _Nullable(^PFSQLiteDatabaseQueryBlock)(PFSQLiteDatabaseResult *_Nonnull result);

/**
 Argument count given in executeSQLAsync or executeQueryAsync is invalid.
 */
extern int const PFSQLiteDatabaseInvalidArgumenCountErrorCode;

/**
 Method `executeSQL` cannot execute SELECT. Use `executeQuery` instead.
 */
extern int const PFSQLiteDatabaseInvalidSQL;

/**
 Database is opened already.
 */
extern int const PFSQLiteDatabaseDatabaseAlreadyOpened;

/**
 Database is closed already.
 */
extern int const PFSQLiteDatabaseDatabaseAlreadyClosed;

NS_ASSUME_NONNULL_BEGIN

@interface PFSQLiteDatabase : NSObject

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithPath:(NSString *)path;

///--------------------------------------
#pragma mark - Database Creation
///--------------------------------------

+ (instancetype)databaseWithPath:(NSString *)path;

///--------------------------------------
#pragma mark - Connection
///--------------------------------------

/**
 @return A `BFTask` that resolves to `YES` if the database is open.
 */
- (BFTask *)isOpenAsync;

/**
 Opens database. Database is one time use. Open > Close > Open is forbidden.
 */
- (BFTask *)openAsync;

/**
 Closes the database connection.
 */
- (BFTask *)closeAsync;

///--------------------------------------
#pragma mark - Transaction
///--------------------------------------

/**
 Begins a database transaction in EXCLUSIVE mode.
 */
- (BFTask *)beginTransactionAsync;

/**
 Commits running transaction.
 */
- (BFTask *)commitAsync;

/**
 Rollbacks running transaction.
 */
- (BFTask *)rollbackAsync;

///--------------------------------------
#pragma mark - Query Methods
///--------------------------------------

/**
 Runs a single SQL statement which return result (SELECT).
 */
- (BFTask *)executeQueryAsync:(NSString *)query withArgumentsInArray:(nullable NSArray *)args block:(PFSQLiteDatabaseQueryBlock)block;

/**
 Runs a single SQL statement, while caching the resulting statement for future use.
 */
- (BFTask *)executeCachedQueryAsync:(NSString *)sql withArgumentsInArray:(nullable NSArray *)args;

/**
 Runs a single SQL statement which doesn't return result (UPDATE/INSERT/DELETE).
 */
- (BFTask *)executeSQLAsync:(NSString *)sql withArgumentsInArray:(nullable NSArray *)args;

@end

NS_ASSUME_NONNULL_END
