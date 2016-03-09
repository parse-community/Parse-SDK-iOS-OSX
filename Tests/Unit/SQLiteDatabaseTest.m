/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Bolts.BFTask;

#import "BFTask+Private.h"
#import "PFFileManager.h"
#import "PFSQLiteDatabase.h"
#import "PFSQLiteDatabaseResult.h"
#import "PFTestCase.h"

@interface SQLiteDatabaseTest : PFTestCase {
    PFSQLiteDatabase *database;
}
@end

@implementation SQLiteDatabaseTest

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (NSString *)databasePath {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"test.db"];
}

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    database = [PFSQLiteDatabase databaseWithPath:[self databasePath]];
}

- (void)tearDown {
    if (database != NULL) {
        [[[database isOpenAsync] continueWithBlock:^id(BFTask *task) {
            BOOL isOpen = [task.result boolValue];

            if (isOpen) {
                return [database closeAsync];
            }
            return task;
        }] waitUntilFinished];
    }
    // delete DB file;
    [[NSFileManager defaultManager] removeItemAtPath:[self databasePath] error:NULL];

    [super tearDown];
}

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

// Should return BFTask to not waste `waitUntilFinished`
- (BFTask *)createDatabaseAsync {
    // Drop existing database first if any.
    return [[[[database openAsync] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"DROP TABLE test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        return [database openAsync];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"CREATE TABLE test (a text, b text, c integer, d double)"
                    withArgumentsInArray:nil];
    }];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testOpen {
    [[[[[[[[[database openAsync] continueWithBlock:^id(BFTask *task) {
        return [database isOpenAsync];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return [database openAsync];
    }] continueWithBlock:^id(BFTask *task) {
        // Should error because DB is opened
        XCTAssertNotNil(task.error);
        return [database closeAsync];
    }] continueWithBlock:^id(BFTask *task) {
        return [database isOpenAsync];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return [database closeAsync];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        return [database openAsync];
    }] continueWithBlock:^id(BFTask *task) {
        // Should fail because database was closed already, and reopened.
        XCTAssertNotNil(task.error);
        return task;
    }] waitUntilFinished];
}

- (void)testCRUD {
    [[[[[[[[[[[[database openAsync] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"CREATE TABLE test (a text, b text, c integer, d double)"
                    withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        // Make sure it success
        XCTAssertNil(task.error);
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"one", @"two", @3, @4.4 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        // Check values
        XCTAssertEqualObjects(@"one", [result stringForColumnIndex:0]);
        XCTAssertEqualObjects(@"two", [result stringForColumnIndex:1]);
        XCTAssertEqual(3, [result intForColumnIndex:2]);
        // Make sure there's nothing more
        XCTAssertFalse([result next]);

        // Test the cached statement
        // TODO (hallucinogen): how can we be sure we're getting this from cached statement?
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        // Check values
        XCTAssertEqualObjects(@"one", [result stringForColumnIndex:0]);
        XCTAssertEqualObjects(@"two", [result stringForColumnIndex:1]);
        XCTAssertEqual(3, [result intForColumnIndex:2]);

        // Make sure there's nothing more
        XCTAssertFalse([result next]);

        return [database executeSQLAsync:@"UPDATE test SET a = ?, c = ? WHERE c = ?"
                    withArgumentsInArray:@[ @"onenew", @5, @3 ]];
    }] continueWithBlock:^id(BFTask *task) {
        // Make sure there's nothing wrong
        XCTAssertNil(task.error);
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        // Check values
        XCTAssertEqualObjects(@"onenew", [result stringForColumnIndex:0]);
        XCTAssertEqualObjects(@"two", [result stringForColumnIndex:1]);
        XCTAssertEqual(5, [result intForColumnIndex:2]);

        // Make sure there's nothing more
        XCTAssertFalse([result next]);

        return [database executeSQLAsync:@"DELETE FROM test WHERE c = ?"
                    withArgumentsInArray:@[ @5 ]];
    }] continueWithBlock:^id(BFTask *task) {
        // Make sure there's nothing wrong
        XCTAssertNil(task.error);
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        // Make sure there's nothing wrong
        XCTAssertNil(task.error);
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure there's nothing more
        XCTAssertFalse(result.next);

        // Clean up
        return [database executeSQLAsync:@"DROP TABLE test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        // Make sure there's nothing wrong
        XCTAssertNil(task.error);
        return task;
    }] waitUntilFinished];
}

// TODO (hallucinogen): this test consists of three units which can be separated.
- (void)testTransaction {
    [[[[[[[[[[[[[[[[[self createDatabaseAsync] continueWithBlock:^id(BFTask *task) {
        return [database beginTransactionAsync];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"one", @"two", @3, @4.4 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        // Check values
        XCTAssertEqualObjects(@"one", [result stringForColumnIndex:0]);
        XCTAssertEqualObjects(@"two", [result stringForColumnIndex:1]);
        XCTAssertEqual(3, [result intForColumnIndex:2]);

        // Make sure there's nothing more
        XCTAssertFalse(result.next);

        // Commit
        return [database commitAsync];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        // Check values
        XCTAssertEqualObjects(@"one", [result stringForColumnIndex:0]);
        XCTAssertEqualObjects(@"two", [result stringForColumnIndex:1]);
        XCTAssertEqual(3, [result intForColumnIndex:2]);

        // Make sure there's nothing more
        XCTAssertFalse(result.next);

        return [database beginTransactionAsync];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"oneone", @"twotwo", @33, @44.44 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        // should have two results
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        BOOL nextResult = [result next];
        // There's second element
        XCTAssertTrue(nextResult);
        nextResult = [result next];
        // There's nothing more
        XCTAssertFalse(nextResult);

        // Rollback
        return [database rollbackAsync];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        // Should have one result
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        BOOL nextResult = [result next];
        // There's nothing more
        XCTAssertFalse(nextResult);

        // Now let's try making transaction, then close the database wbile it's in transaction
        return [database beginTransactionAsync];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"oneone", @"twotwo", @33, @44.44 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        // Should have two results
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        BOOL nextResult = [result next];
        XCTAssertTrue(nextResult);
        nextResult = [result next];
        XCTAssertFalse(nextResult);

        // Let's close the database while in transaction
        // The expected result: close successfully and the transaction would be rolled back
        return [database closeAsync];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        return [BFTask taskWithResult:nil];
    }] waitUntilFinished];

    database = [PFSQLiteDatabase databaseWithPath:[self databasePath]];
    [[[[[[[database openAsync] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"oneone", @"twotwo", @33, @44.44 ]];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        // Should have two results because the last one is rolled back
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        BOOL nextResult = [result next];
        XCTAssertTrue(nextResult);
        nextResult = [result next];
        XCTAssertFalse(nextResult);

        // Try rolling back previous transaction (which should fail because the database has been
        // closed and currently there's no transaction)
        return [database rollbackAsync];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        // Should still have two results
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        BOOL nextResult = [result next];
        XCTAssertTrue(nextResult);
        nextResult = [result next];
        XCTAssertFalse(nextResult);

        return [database closeAsync];
    }] waitUntilFinished];
}

- (void)testOperationOnNonExistentTable {
    [[[[[[[self createDatabaseAsync] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO testFake (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"one", @"two", @3, @4.4 ]];
    }]  continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"one", @"two", @3, @4.4 ]];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        return [database executeCachedQueryAsync:@"SELECT * FROM testFake" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        // Should have one result
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        BOOL nextResult = [result next];
        XCTAssertFalse(nextResult);

        // Clean up
        return [database closeAsync];
    }] waitUntilFinished];
}

- (void)testQuery {
    [[[[[[[[[self createDatabaseAsync] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"one", @"two", @3, @4.4 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"oneone", @"twotwo", @33, @44.44 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        // Should have two results
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        BOOL nextResult = [result next];
        XCTAssertTrue(nextResult);
        nextResult = [result next];
        XCTAssertFalse(nextResult);

        return [database executeCachedQueryAsync:@"SELECT * FROM test WHERE c = ?"
                      withArgumentsInArray:@[ @3 ]];
    }] continueWithBlock:^id(BFTask *task) {
        // Check result
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        // Check values
        XCTAssertEqualObjects(@"one", [result stringForColumnIndex:0]);
        XCTAssertEqualObjects(@"two", [result stringForColumnIndex:1]);
        XCTAssertEqual(3, [result intForColumnIndex:2]);

        // Should have one result
        BOOL nextResult = [result next];
        XCTAssertFalse(nextResult);

        return [database executeSQLAsync:@"UPDATE test SET a = ?, c = ? WHERE c = ?"
                    withArgumentsInArray:@[ @"onenew", @5, @3 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test WHERE c = ?"
                      withArgumentsInArray:@[ @5 ]];
    }] continueWithBlock:^id(BFTask *task) {
        // Check result
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        // Check values
        XCTAssertEqualObjects(@"onenew", [result stringForColumn:@"a"]);
        XCTAssertEqualObjects(@"two", [result stringForColumnIndex:1]);
        XCTAssertEqual(5, [result intForColumnIndex:2]);

        // Should have one result
        BOOL nextResult = [result next];
        XCTAssertFalse(nextResult);

        // Clean up
        return [database closeAsync];
    }] waitUntilFinished];
}

- (void)testCursorAndOperationOnDifferentThread {
    BFTask *taskWithCursor = [[[[[self createDatabaseAsync] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"one", @"two", @3, @4.4 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"oneone", @"twotwo", @33, @44.44 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id(BFTask *task) {
        // Execute this in background
        PFSQLiteDatabaseResult *result = task.result;
        // Make sure first element exists
        XCTAssertTrue([result next]);

        // Check values
        XCTAssertEqualObjects(@"one", [result stringForColumnIndex:0]);
        XCTAssertEqualObjects(@"two", [result stringForColumnIndex:1]);
        XCTAssertEqual(3, [result intForColumnIndex:2]);

        return result;
    }];

    // Make sure we can read result from main thread
    [taskWithCursor waitUntilFinished];
    PFSQLiteDatabaseResult *result = taskWithCursor.result;

    // Try to access result in main thread
    XCTAssertEqualObjects(@"one", [result stringForColumnIndex:0]);
    XCTAssertEqualObjects(@"two", [result stringForColumnIndex:1]);
    XCTAssertEqual(3, [result intForColumnIndex:2]);
    XCTAssertTrue([result next]);
    XCTAssertEqualObjects(@"oneone", [result stringForColumnIndex:0]);
    XCTAssertEqualObjects(@"twotwo", [result stringForColumnIndex:1]);
    XCTAssertEqual(33, [result intForColumnIndex:2]);

    // Test clean up fail
    [[[[[[database executeSQLAsync:@"DROP TABLE test" withArgumentsInArray:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        return task;
    }] continueWithExecutor:[BFExecutor defaultExecutor] withBlock:^id(BFTask *task) {
        // `result` should not increase
        XCTAssertFalse([result next]);

        return [database executeSQLAsync:@"DROP TABLE test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        return task;
        //return [database2 closeAsync];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        return [database closeAsync];
    }] waitUntilFinished];
}

- (void)testInvalidArgumentCount {
    [[[[self createDatabaseAsync] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?)"
                    withArgumentsInArray:@[ @"one", @"two", @3, @4.4 ]];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqual(PFSQLiteDatabaseInvalidArgumenCountErrorCode, [task.error.userInfo[@"code"] integerValue]);
        return [database closeAsync];
    }] waitUntilFinished];
}

- (void)testInvalidSQL {
    [[[[[self createDatabaseAsync] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @"one", @"two", @3, @4.4 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        XCTAssertEqual(PFSQLiteDatabaseInvalidSQL, [task.error.userInfo[@"code"] integerValue]);
        return [database closeAsync];
    }] waitUntilFinished];
}

- (void)testColumnTypes {
    [[[[[self createDatabaseAsync] continueWithBlock:^id(BFTask *task) {
        return [database executeSQLAsync:@"INSERT INTO test (a, b, c, d) VALUES (?, ?, ?, ?)"
                    withArgumentsInArray:@[ @1, [NSNull null], @"string", @13.37 ]];
    }] continueWithBlock:^id(BFTask *task) {
        return [database executeCachedQueryAsync:@"SELECT * FROM test" withArgumentsInArray:nil];
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        PFSQLiteDatabaseResult *result = task.result;
        XCTAssertTrue([result next]);

        XCTAssertEqual([result intForColumn:@"a"], 1);
        XCTAssertEqual([result intForColumn:@"b"], 0);
        XCTAssertEqual([result intForColumn:@"c"], 0);
        XCTAssertEqual([result intForColumn:@"d"], 13);

        XCTAssertEqual([result intForColumnIndex:0], 1);
        XCTAssertEqual([result intForColumnIndex:1], 0);
        XCTAssertEqual([result intForColumnIndex:2], 0);
        XCTAssertEqual([result intForColumnIndex:3], 13);

        XCTAssertEqual([result longForColumn:@"a"], 1);
        XCTAssertEqual([result longForColumn:@"b"], 0);
        XCTAssertEqual([result longForColumn:@"c"], 0);
        XCTAssertEqual([result longForColumn:@"d"], 13);

        XCTAssertEqual([result longForColumnIndex:0], 1);
        XCTAssertEqual([result longForColumnIndex:1], 0);
        XCTAssertEqual([result longForColumnIndex:2], 0);
        XCTAssertEqual([result longForColumnIndex:3], 13);

        XCTAssertEqual([result boolForColumn:@"a"], YES);
        XCTAssertEqual([result boolForColumn:@"b"], NO);
        XCTAssertEqual([result boolForColumn:@"c"], NO);
        XCTAssertEqual([result boolForColumn:@"d"], YES);

        XCTAssertEqual([result boolForColumnIndex:0], YES);
        XCTAssertEqual([result boolForColumnIndex:1], NO);
        XCTAssertEqual([result boolForColumnIndex:2], NO);
        XCTAssertEqual([result boolForColumnIndex:3], YES);

        XCTAssertEqual([result doubleForColumn:@"a"], 1);
        XCTAssertEqual([result doubleForColumn:@"b"], 0);
        XCTAssertEqual([result doubleForColumn:@"c"], 0);
        XCTAssertEqual([result doubleForColumn:@"d"], 13.37);

        XCTAssertEqual([result doubleForColumnIndex:0], 1);
        XCTAssertEqual([result doubleForColumnIndex:1], 0);
        XCTAssertEqual([result doubleForColumnIndex:2], 0);
        XCTAssertEqual([result doubleForColumnIndex:3], 13.37);

        XCTAssertEqualObjects([result stringForColumn:@"a"], @"1");
        XCTAssertEqualObjects([result stringForColumn:@"b"], nil);
        XCTAssertEqualObjects([result stringForColumn:@"c"], @"string");
        XCTAssertEqualObjects([result stringForColumn:@"d"], @"13.37");

        XCTAssertEqualObjects([result stringForColumnIndex:0], @"1");
        XCTAssertEqualObjects([result stringForColumnIndex:1], nil);
        XCTAssertEqualObjects([result stringForColumnIndex:2], @"string");
        XCTAssertEqualObjects([result stringForColumnIndex:3], @"13.37");

        XCTAssertEqualObjects([result dateForColumn:@"a"], [NSDate dateWithTimeIntervalSince1970:1]);
        XCTAssertEqualObjects([result dateForColumn:@"b"], [NSDate dateWithTimeIntervalSince1970:0]);
        XCTAssertEqualObjects([result dateForColumn:@"c"], [NSDate dateWithTimeIntervalSince1970:0]);
        XCTAssertEqualObjects([result dateForColumn:@"d"], [NSDate dateWithTimeIntervalSince1970:13.37]);

        XCTAssertEqualObjects([result dateForColumnIndex:0], [NSDate dateWithTimeIntervalSince1970:1]);
        XCTAssertEqualObjects([result dateForColumnIndex:1], [NSDate dateWithTimeIntervalSince1970:0]);
        XCTAssertEqualObjects([result dateForColumnIndex:2], [NSDate dateWithTimeIntervalSince1970:0]);
        XCTAssertEqualObjects([result dateForColumnIndex:3], [NSDate dateWithTimeIntervalSince1970:13.37]);

        XCTAssertEqualObjects([result dataForColumn:@"a"], [NSData dataWithBytes:(char[]) { '1' } length:1]);
        XCTAssertEqualObjects([result dataForColumn:@"b"], nil);
        XCTAssertEqualObjects([result dataForColumn:@"c"], [NSData dataWithBytes:"string"length:6]);
        XCTAssertEqualObjects([result dataForColumn:@"d"], [NSData dataWithBytes:"13.37" length:5]);

        XCTAssertEqualObjects([result dataForColumnIndex:0], [NSData dataWithBytes:(char[]) { '1' } length:1]);
        XCTAssertEqualObjects([result dataForColumnIndex:1], nil);
        XCTAssertEqualObjects([result dataForColumnIndex:2], [NSData dataWithBytes:"string"length:6]);
        XCTAssertEqualObjects([result dataForColumnIndex:3], [NSData dataWithBytes:"13.37" length:5]);

        XCTAssertEqualObjects([result objectForColumn:@"a"], @"1");
        XCTAssertEqualObjects([result objectForColumn:@"b"], nil);
        XCTAssertEqualObjects([result objectForColumn:@"c"], @"string");
        XCTAssertEqualObjects([result objectForColumn:@"d"], @13.37);

        XCTAssertEqualObjects([result objectForColumnIndex:0], @"1");
        XCTAssertEqualObjects([result objectForColumnIndex:1], nil);
        XCTAssertEqualObjects([result objectForColumnIndex:2], @"string");
        XCTAssertEqualObjects([result objectForColumnIndex:3], @13.37);

        XCTAssertFalse([result columnIsNull:@"a"]);
        XCTAssertTrue([result columnIsNull:@"b"]);
        XCTAssertFalse([result columnIsNull:@"c"]);
        XCTAssertFalse([result columnIsNull:@"d"]);

        XCTAssertFalse([result columnIndexIsNull:0]);
        XCTAssertTrue([result columnIndexIsNull:1]);
        XCTAssertFalse([result columnIndexIsNull:2]);
        XCTAssertFalse([result columnIndexIsNull:3]);

        return [database closeAsync];
    }] waitUntilFinished];
}

@end
