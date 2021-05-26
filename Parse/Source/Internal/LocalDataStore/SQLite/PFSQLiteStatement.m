/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSQLiteStatement.h"

#import <sqlite3.h>

#import "PFThreadsafety.h"

@implementation PFSQLiteStatement

- (instancetype)initWithStatement:(sqlite3_stmt *)stmt queue:(dispatch_queue_t)databaseQueue {
    self = [super init];
    if (!stmt || !self) return nil;

    _sqliteStatement = stmt;
    _databaseQueue = databaseQueue;

    return self;
}

- (void)dealloc {
    [self close];
}

- (BOOL)close {
    return PFThreadSafetyPerform(_databaseQueue, ^BOOL{
        if (!self->_sqliteStatement) {
            return YES;
        }

        int resultCode = sqlite3_finalize(self->_sqliteStatement);
        self->_sqliteStatement = NULL;

        return (resultCode == SQLITE_OK || resultCode == SQLITE_DONE);
    });
}

- (BOOL)reset {
    return PFThreadSafetyPerform(_databaseQueue, ^BOOL{
        if (!self->_sqliteStatement) {
            return YES;
        }

        int resultCode = sqlite3_reset(self->_sqliteStatement);
        return (resultCode == SQLITE_OK || resultCode == SQLITE_DONE);
    });
}

@end
