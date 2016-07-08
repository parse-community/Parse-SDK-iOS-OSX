/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "BFTask+Private.h"
#import "PFObjectPrivate.h"
#import "PFOfflineQueryLogic.h"
#import "PFQueryPrivate.h"
#import "PFSQLiteDatabase.h"
#import "PFUnitTestCase.h"

@interface OfflineQueryLogicUnitTests : PFUnitTestCase {
    PFUser *_user;
}

@end

@implementation OfflineQueryLogicUnitTests

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    _user = [PFUser user];
}

- (void)tearDown {
    _user = nil;

    [super tearDown];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testQueryEqual {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;

    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];
    BFTask *task = [BFTask taskWithResult:nil];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" equalTo:@"bar"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" equalTo:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" equalTo:@"bar"];
    [query whereKey:@"sum" equalTo:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    // Check double
    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" equalTo:@"bar"];
    [query whereKey:@"sum" equalTo:@1337.0];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    // Check float
    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" equalTo:@"bar"];
    [query whereKey:@"sum" equalTo:@1337.0f];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" equalTo:@"bar"];
    [query whereKey:@"sum" equalTo:@101];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryNotEqual {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;

    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];
    BFTask *task = [BFTask taskWithResult:nil];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" notEqualTo:@"bar"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" notEqualTo:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" notEqualTo:@"bar"];
    [query whereKey:@"sum" notEqualTo:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" notEqualTo:@"bar"];
    [query whereKey:@"sum" notEqualTo:@101];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" notEqualTo:@"gundam"];
    [query whereKey:@"sum" notEqualTo:@101];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryLessThan {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;
    object[@"today"] = [NSDate dateWithTimeIntervalSince1970:1337];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"foo" lessThan:@"bar"];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" lessThan:@"barz"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" lessThan:@"appa yip yip"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" lessThan:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" lessThan:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" lessThan:@2331];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" lessThan:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    // while Date in PFObject is vanila NSDate. Is this problem also exists in Android?
    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" lessThan:[NSDate dateWithTimeIntervalSince1970:1337]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" lessThan:[NSDate dateWithTimeIntervalSince1970:2133]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" lessThan:@"appa yip yip"];
    [query whereKey:@"sum" lessThan:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" lessThan:@"gokil"];
    [query whereKey:@"sum" lessThan:@3333];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryLessThanEqual {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;
    object[@"today"] = [NSDate dateWithTimeIntervalSince1970:1337];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"foo" lessThanOrEqualTo:@"bar"];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" lessThanOrEqualTo:@"barz"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" lessThanOrEqualTo:@"appa yip yip"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" lessThanOrEqualTo:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" lessThanOrEqualTo:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" lessThanOrEqualTo:@2331];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" lessThanOrEqualTo:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" lessThanOrEqualTo:[NSDate dateWithTimeIntervalSince1970:1337]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" lessThanOrEqualTo:[NSDate dateWithTimeIntervalSince1970:2133]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" lessThanOrEqualTo:@"appa yip yip"];
    [query whereKey:@"sum" lessThanOrEqualTo:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" lessThanOrEqualTo:@"gokil"];
    [query whereKey:@"sum" lessThanOrEqualTo:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryGreaterThan {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;
    object[@"today"] = [NSDate dateWithTimeIntervalSince1970:1337];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"foo" greaterThan:@"bar"];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" greaterThan:@"barz"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" greaterThan:@"appa yip yip"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" greaterThan:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" greaterThan:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" greaterThan:@1331];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" greaterThan:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" greaterThan:[NSDate dateWithTimeIntervalSince1970:1337]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" greaterThan:[NSDate dateWithTimeIntervalSince1970:133]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" greaterThan:@"appa yip yip"];
    [query whereKey:@"sum" greaterThan:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" greaterThan:@"appa yip yip"];
    [query whereKey:@"sum" greaterThan:@1331];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryGreaterThanEqual {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;
    object[@"today"] = [NSDate dateWithTimeIntervalSince1970:1337];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"foo" greaterThanOrEqualTo:@"bar"];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" greaterThanOrEqualTo:@"barz"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" greaterThanOrEqualTo:@"appa yip yip"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" greaterThanOrEqualTo:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" greaterThanOrEqualTo:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" greaterThanOrEqualTo:@1331];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" greaterThanOrEqualTo:@"1337"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" greaterThanOrEqualTo:[NSDate dateWithTimeIntervalSince1970:1337]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"today" greaterThanOrEqualTo:[NSDate dateWithTimeIntervalSince1970:133]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" greaterThanOrEqualTo:@"appa yip yip"];
    [query whereKey:@"sum" greaterThanOrEqualTo:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" greaterThanOrEqualTo:@"gokil"];
    [query whereKey:@"sum" greaterThanOrEqualTo:@1337];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryIn {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;
    object[@"ArrezTheGodOfWar"] = @[@"bar", @1337];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"foo" containedIn:@[@"bar", @"bir", @"barz"]];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" containedIn:@[@"ber", @YES, @"barz"]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" containedIn:@[@"1337", @123, @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" containedIn:@[@1337, @123, @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"ArrezTheGodOfWar" containedIn:@[@1337, @"bar", @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"ArrezTheGodOfWar" containedIn:@[@1337, @"barz", @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"ArrezTheGodOfWar" containedIn:@[@"1337", @"barz", @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryNotIn {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;
    object[@"ArrezTheGodOfWar"] = @[@"bar", @1337];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"foo" notContainedIn:@[@"bar", @"bir", @"barz"]];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" notContainedIn:@[@"ber", @YES, @"barz"]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" notContainedIn:@[@"1337", @123, @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" notContainedIn:@[@1337, @123, @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"ArrezTheGodOfWar" notContainedIn:@[@1337, @"bar", @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"ArrezTheGodOfWar" notContainedIn:@[@1337, @"barz", @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"ArrezTheGodOfWar" notContainedIn:@[@"1337", @"barz", @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryAll {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;
    object[@"ArrezTheGodOfWar"] = @[@"bar", @1337, @"awesome"];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"foo" containsAllObjectsInArray:@[@"bar"]];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"foo" containsAllObjectsInArray:@[@"bar", @YES, @"barz"]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"sum" containsAllObjectsInArray:@[@1337]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"ArrezTheGodOfWar" containsAllObjectsInArray:@[@1337, @"bar", @456]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"ArrezTheGodOfWar" containsAllObjectsInArray:@[@1337, @"bar", @"awesome", @"more awesome"]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"ArrezTheGodOfWar" containsAllObjectsInArray:@[@1337, @"bar"]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryRegex {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"barney"] = @"barney stinson";
    object[@"stinson"] = @"stinson";
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"barney" matchesRegex:@"stinson"];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"stinson" matchesRegex:@"stinson"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"stinson" matchesRegex:@"barney"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryRegexWithModifier {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"barney"] = @"barney stinson";
    object[@"stinson"] = @"stinson";
    object[@"GreatMaster"] = @"Stinson";
    object[@"SomethingWithNewline"] = @"Something\nwith\nnewline";
    object[@"dika"] = @"Gandira Putra Prahandika";
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"stinson" matchesRegex:@"stinson" modifiers:@"i"];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"GreatMaster" matchesRegex:@"stinson" modifiers:@"i"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"GreatMaster" matchesRegex:@"stinsonz" modifiers:@"i"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"SomethingWithNewline" matchesRegex:@"^newline$" modifiers:nil];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"SomethingWithNewline" matchesRegex:@"^newline$" modifiers:@"m"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"SomethingWithNewline" matchesRegex:@"^Newline$" modifiers:@"im"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"SomethingWithNewline" matchesRegex:@"^Newline$" modifiers:@"m"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"SomethingWithNewline" matchesRegex:@"^Newline$" modifiers:@"i"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"SomethingWithNewline" matchesRegex:@"with.*newline" modifiers:nil];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"SomethingWithNewline" matchesRegex:@"with.*newline" modifiers:@"s"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"SomethingWithNewline" matchesRegex:@"with.*Newline" modifiers:@"is"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"dika" matchesRegex:@"Pu tra .*dika" modifiers:nil];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"dika" matchesRegex:@"Pu tra.*dika" modifiers:@"x"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryExists {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = [NSNull null];
    object[@"ArrezTheGodOfWar"] = @[ ];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKeyExists:@"foo"];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKeyExists:@"sum"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKeyExists:@"ArrezTheGodOfWar"];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryNearSphere {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"point1"] = [PFGeoPoint geoPointWithLatitude:10 longitude:10];
    object[@"point2"] = [PFGeoPoint geoPointWithLatitude:70 longitude:70];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"point1" nearGeoPoint:[PFGeoPoint geoPointWithLatitude:15 longitude:15] withinRadians:50];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"point2" nearGeoPoint:[PFGeoPoint geoPointWithLatitude:-15 longitude:-15] withinRadians:1];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryWithin {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"point1"] = [PFGeoPoint geoPointWithLatitude:10 longitude:10];
    object[@"point2"] = [PFGeoPoint geoPointWithLatitude:70 longitude:70];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    BFTask *task = [BFTask taskWithResult:nil];

    [query whereKey:@"point1" withinGeoBoxFromSouthwest:[PFGeoPoint geoPointWithLatitude:5 longitude:5]
        toNortheast:[PFGeoPoint geoPointWithLatitude:15 longitude:15]];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"point2" withinGeoBoxFromSouthwest:[PFGeoPoint geoPointWithLatitude:5 longitude:5]
        toNortheast:[PFGeoPoint geoPointWithLatitude:15 longitude:15]];
    matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertFalse([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testQueryOr {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];
    PFSQLiteDatabase *database = [[PFSQLiteDatabase alloc] init];

    PFObject *object = [PFObject objectWithClassName:@"Object"];
    object[@"foo"] = @"bar";
    object[@"sum"] = @1337;
    object[@"ArrezTheGodOfWar"] = @[@"bar", @1337];
    PFQuery *query = nil;
    BFTask *task = [BFTask taskWithResult:nil];

    PFQuery *query1 = [PFQuery queryWithClassName:@"Object"];
    [query1 whereKey:@"foo" containedIn:@[@"bar", @"bir", @"barz"]];
    PFQuery *query2 = [PFQuery queryWithClassName:@"Object"];
    [query2 whereKey:@"foo" containedIn:@[@123, @456, @"barz"]];
    query = [PFQuery orQueryWithSubqueries:@[query1, query2]];
    PFConstraintMatcherBlock matcherBlock = [logic createMatcherForQueryState:query.state user:_user];

    // Check matcher
    task = [[task continueWithBlock:^id(BFTask *task) {
        return matcherBlock(object, database);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue([task.result boolValue]);
        return nil;
    }];

    [task waitUntilFinished];
}

- (void)testSortDate {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];

    NSMutableArray *objects = [NSMutableArray array];
    for (int i = 0; i < 10; ++i) {
        PFObject *object = [PFObject objectWithClassName:@"Object"];
        object[@"num"] = @(10 - i);
        [objects addObject:object];
    }
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    [query orderByAscending:@"createdAt"];

    NSArray *sorted = [logic resultsByApplyingOptions:PFOfflineQueryOptionOrder
                                         ofQueryState:query.state
                                            toResults:objects];
    for (int i = 0; i < 10; ++i) {
        XCTAssertEqual(10 - i, [sorted[i][@"num"] intValue]);
    }
}

- (void)testSortNumber {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];

    NSMutableArray *objects = [NSMutableArray array];
    for (int i = 0; i < 10; ++i) {
        PFObject *object = [PFObject objectWithClassName:@"Object"];
        object[@"num"] = @(10 - i);
        [objects addObject:object];
    }
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    [query orderByAscending:@"num"];

    NSArray *sorted = [logic resultsByApplyingOptions:PFOfflineQueryOptionOrder
                                         ofQueryState:query.state
                                            toResults:objects];
    for (int i = 0; i < 10; ++i) {
        XCTAssertEqual(i + 1, [sorted[i][@"num"] intValue]);
    }
}

- (void)testSortNumberDescending {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];

    NSMutableArray *objects = [NSMutableArray array];
    for (int i = 0; i < 10; ++i) {
        PFObject *object = [PFObject objectWithClassName:@"Object"];
        object[@"num"] = @(i);
        [objects addObject:object];
    }
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    [query orderByAscending:@"-num"];

    NSArray *sorted = [logic resultsByApplyingOptions:PFOfflineQueryOptionOrder
                                         ofQueryState:query.state
                                            toResults:objects];
    for (int i = 0; i < 10; ++i) {
        XCTAssertEqual(9 - i, [sorted[i][@"num"] intValue]);
    }
}

- (void)testSortGeoPoint {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];

    NSMutableArray *objects = [NSMutableArray array];
    for (int i = 1; i <= 10; ++i) {
        PFObject *object = [PFObject objectWithClassName:@"Object"];
        object[@"point"] = [PFGeoPoint geoPointWithLatitude:10 longitude:i];
        object[@"order"] = @(10 - i);
        [objects addObject:object];
    }
    PFGeoPoint *origin = [PFGeoPoint geoPointWithLatitude:10 longitude:0];
    PFQuery *query = [PFQuery queryWithClassName:@"Object"];
    [query whereKey:@"point" nearGeoPoint:origin];
    [query orderByAscending:@"order"];

    NSArray *sorted = [logic resultsByApplyingOptions:PFOfflineQueryOptionOrder
                                         ofQueryState:query.state
                                            toResults:objects];
    // It should not care about order. Instead it should sort based on how near it is to origin
    for (int i = 0; i < 10; ++i) {
        XCTAssertEqual(9 - i, [sorted[i][@"order"] intValue]);
    }
}

- (void)testUnderLimit {
    PFOfflineQueryLogic *logic = [[PFOfflineQueryLogic alloc] init];

    NSArray *results = @[ [PFObject objectWithClassName:@"Test"] ];

    PFQuery *query = [PFQuery queryWithClassName:@"Test"];
    query.limit = 25;

    NSArray *strippedArray = [logic resultsByApplyingOptions:PFOfflineQueryOptionLimit
                                                ofQueryState:query.state
                                                   toResults:results];
    XCTAssertEqual(results.count, strippedArray.count);
}

@end
