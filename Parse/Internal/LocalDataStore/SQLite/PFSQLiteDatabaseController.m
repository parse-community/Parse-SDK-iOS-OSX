/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFSQLiteDatabaseController.h"

#import <Bolts/BFTask.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "PFAssert.h"
#import "PFAsyncTaskQueue.h"
#import "PFFileManager.h"
#import "PFSQLiteDatabase_Private.h"

@implementation PFSQLiteDatabaseController {
    PFAsyncTaskQueue *_openDatabaseQueue;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithFileManager:(PFFileManager *)fileManager {
    self = [super init];
    if (!self) return nil;

    _fileManager = fileManager;
    _openDatabaseQueue = [[PFAsyncTaskQueue alloc] init];

    return self;
}

+ (instancetype)controllerWithFileManager:(PFFileManager *)fileManager {
    return [[self alloc] initWithFileManager:fileManager];
}

///--------------------------------------
#pragma mark - Opening
///--------------------------------------

// TODO: (richardross) Implement connection pooling using NSCache or similar mechanism.
- (BFTask *)openDatabaseWithNameAsync:(NSString *)name {
    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    [_openDatabaseQueue enqueue:^id(BFTask *task) {
        NSString *databasePath = [self.fileManager parseDataItemPathForPathComponent:name];
        PFSQLiteDatabase *sqliteDatabase = [PFSQLiteDatabase databaseWithPath:databasePath];
        [[sqliteDatabase openAsync] continueWithBlock:^id(BFTask *task) {
            if (task.faulted) {
                NSError *error = task.error;
                if (error) {
                    [taskCompletionSource trySetError:error];
                }
            } else if (task.cancelled) {
                [taskCompletionSource trySetCancelled];
            } else {
                [taskCompletionSource trySetResult:sqliteDatabase];
            }

            return nil;
        }];

        return sqliteDatabase.databaseClosedTask;
    }];

    return taskCompletionSource.task;
}

@end
