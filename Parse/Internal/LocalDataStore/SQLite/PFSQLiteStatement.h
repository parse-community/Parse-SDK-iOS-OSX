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

/**
 PFSQLiteStatement is sqlite3_stmt wrapper class.
 */
typedef struct sqlite3_stmt sqlite3_stmt;

@interface PFSQLiteStatement : NSObject

@property (nonatomic, assign, readonly) sqlite3_stmt *sqliteStatement;
@property (nonatomic, strong, readonly) dispatch_queue_t databaseQueue;

- (instancetype)initWithStatement:(sqlite3_stmt *)stmt queue:(dispatch_queue_t)databaseQueue;

- (BOOL)close;
- (BOOL)reset;

@end

NS_ASSUME_NONNULL_END
