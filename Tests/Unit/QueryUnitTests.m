/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

@import Bolts.BFTask;

#import "PFCoreManager.h"
#import "PFMacros.h"
#import "PFMutableQueryState.h"
#import "PFQueryController.h"
#import "PFQueryPrivate.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface QueryUnitTestsInvocationVerifier : NSObject

@end

@implementation QueryUnitTestsInvocationVerifier

- (void)verifyNumber:(NSNumber *)number error:(NSError *)error {
}

- (void)verifyArray:(NSArray *)array error:(NSError *)error {
}

- (void)verifyObject:(PFObject *)object error:(NSError *)error {
}

@end

@interface QueryUnitTests : PFUnitTestCase

@end

@implementation QueryUnitTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFQueryController *)mockQueryControllerFindObjectsForQueryState:(PFQueryState *)state
                                                        withResult:(id)result
                                                             error:(NSError *)error {
    BFTask *task = (error ? [BFTask taskWithError:error] : [BFTask taskWithResult:result]);

    id controller = PFStrictClassMock([PFQueryController class]);
    OCMStub([controller findObjectsAsyncForQueryState:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [state isEqual:obj];
    }]
                                withCancellationToken:[OCMArg isNotNil]
                                                 user:[OCMArg isNil]]).andReturn(task);
    [Parse _currentManager].coreManager.queryController = controller;
    return controller;
}

- (PFQueryController *)mockQueryControllerCountObjectsForQueryState:(PFQueryState *)state
                                                         withResult:(id)result
                                                              error:(NSError *)error {
    BFTask *task = (error ? [BFTask taskWithError:error] : [BFTask taskWithResult:result]);

    id controller = PFStrictClassMock([PFQueryController class]);
    OCMStub([controller countObjectsAsyncForQueryState:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [state isEqual:obj];
    }]
                                 withCancellationToken:[OCMArg isNotNil]
                                                  user:[OCMArg isNil]]).andReturn(task);
    [Parse _currentManager].coreManager.queryController = controller;
    return controller;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

#pragma mark Constructors

- (void)testConstructors {
    PFQuery *query = [[PFQuery alloc] init];
    XCTAssertNotNil(query);

    query = [[PFQuery alloc] initWithClassName:@"a"];
    XCTAssertNotNil(query);
    XCTAssertEqualObjects(query.parseClassName, @"a");
    XCTAssertEqualObjects(query.state.parseClassName, @"a");

    query = [PFQuery queryWithClassName:@"b"];
    XCTAssertNotNil(query);
    XCTAssertEqualObjects(query.parseClassName, @"b");
    XCTAssertEqualObjects(query.state.parseClassName, @"b");
}

- (void)testPredicateConstructors {
    PFQuery *query = [PFQuery queryWithClassName:@"a" predicate:nil];
    XCTAssertNotNil(query);
    XCTAssertEqualObjects(query.parseClassName, @"a");
    XCTAssertEqualObjects(query.state.parseClassName, @"a");
}

- (void)testDefaultValues {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    XCTAssertNotNil(query);
    XCTAssertEqual(query.cachePolicy, kPFCachePolicyIgnoreCache);
    XCTAssertEqual(query.maxCacheAge, INFINITY);
    XCTAssertEqual(query.limit, -1);
}

- (void)testOrQuery {
    PFQuery *query1 = [PFQuery queryWithClassName:@"Yolo"];
    PFQuery *query2 = [PFQuery queryWithClassName:@"Yolo"];

    PFQuery *query = [PFQuery orQueryWithSubqueries:@[ query1, query2 ]];
    XCTAssertEqualObjects(query.state.conditions[@"$or"], (@[ query1, query2 ]));
}

#pragma mark Pagination

- (void)testLimit {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    query.limit = 100500;
    XCTAssertEqual(query.limit, 100500);
    XCTAssertEqual(query.state.limit, 100500);
}

- (void)testSkip {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    query.skip = 500;
    XCTAssertEqual(query.skip, 500);
    XCTAssertEqual(query.state.skip, 500);
}

#pragma mark Caching

- (void)testCachePolicy {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    query.cachePolicy = kPFCachePolicyNetworkOnly;
    XCTAssertEqual(query.cachePolicy, kPFCachePolicyNetworkOnly);
    XCTAssertEqual(query.state.cachePolicy, kPFCachePolicyNetworkOnly);
}

- (void)testCachePolicyWithLocalDatastore {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"a" clientKey:@"b"];

    PFQuery *query = [[PFQuery queryWithClassName:@"a"] fromLocalDatastore];
    PFAssertThrowsInconsistencyException([query setCachePolicy:kPFCachePolicyNetworkOnly]);

    query = [[PFQuery queryWithClassName:@"a"] fromPin];
    PFAssertThrowsInconsistencyException([query setCachePolicy:kPFCachePolicyNetworkOnly]);
}

- (void)testMaxCacheAge {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    query.maxCacheAge = 100500.0;
    XCTAssertEqual(query.maxCacheAge, 100500.0);
    XCTAssertEqual(query.state.maxCacheAge, 100500.0);
}

- (void)testHasCachedResult {
    id queryController = PFStrictClassMock([PFQueryController class]);
    [Parse _currentManager].coreManager.queryController = queryController;

    PFQuery *query = [PFQuery queryWithClassName:@"A"];

    OCMStub([queryController hasCachedResultForQueryState:query.state sessionToken:nil]).andReturn(YES);
    XCTAssertTrue([query hasCachedResult]);
}

- (void)testClearCachedResult {
    id queryController = PFStrictClassMock([PFQueryController class]);
    [Parse _currentManager].coreManager.queryController = queryController;

    PFQuery *query = [PFQuery queryWithClassName:@"A"];

    OCMExpect([queryController clearCachedResultForQueryState:query.state sessionToken:nil]);

    [query clearCachedResult];
    OCMVerifyAll(queryController);
}

- (void)testClearAllCachedResults {
    id queryController = PFStrictClassMock([PFQueryController class]);
    [Parse _currentManager].coreManager.queryController = queryController;
    OCMExpect([queryController clearAllCachedResults]);

    [PFQuery clearAllCachedResults];
    OCMVerifyAll(queryController);
}

#pragma mark Other Properties

- (void)testParseClassName {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    XCTAssertEqualObjects(query.parseClassName, @"a");

    query.parseClassName = @"b";
    XCTAssertEqualObjects(query.parseClassName, @"b");
}

- (void)testTrace {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    query.trace = YES;
    XCTAssertTrue(query.trace);
    XCTAssertTrue(query.state.trace);
}

- (void)testIncludeKey {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query includeKey:@"yolo"];
    XCTAssertEqualObjects(query.state.includedKeys, (PF_SET(@"yolo")));

    [query includeKey:@"yolo1"];
    XCTAssertEqualObjects(query.state.includedKeys, (PF_SET(@"yolo", @"yolo1")));
    XCTAssertTrue([query.state.includedKeys containsObject:@"yolo"]);
    XCTAssertTrue([query.state.includedKeys containsObject:@"yolo1"]);
}

- (void)testSelectKeys {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query selectKeys:@[ @"a", @"a" ]];
    XCTAssertEqualObjects(query.state.selectedKeys, (PF_SET(@"a")));

    [query selectKeys:@[ @"a", @"b" ]];
    XCTAssertEqualObjects(query.state.selectedKeys, (PF_SET(@"a", @"b")));
}

#pragma mark Order

- (void)testOrderByAscending {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query orderByAscending:@"yarr"];
    XCTAssertEqualObjects(query.state.sortKeys, @[ @"yarr" ]);
    [query orderByAscending:@"yarr1"];
    XCTAssertEqualObjects(query.state.sortKeys, @[ @"yarr1" ]);
}

- (void)testAddAscendingOrder {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query addAscendingOrder:@"yarr"];
    XCTAssertEqualObjects(query.state.sortKeys, @[ @"yarr" ]);
    [query addAscendingOrder:@"yarr1"];
    XCTAssertEqualObjects(query.state.sortKeys, (@[ @"yarr", @"yarr1" ]));
}

- (void)testOrderByDescending {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query orderByDescending:@"yarr"];
    XCTAssertEqualObjects(query.state.sortKeys, @[ @"-yarr" ]);
    [query orderByDescending:@"yarr1"];
    XCTAssertEqualObjects(query.state.sortKeys, @[ @"-yarr1" ]);
}

- (void)testAddDescendingOrder {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query addDescendingOrder:@"yarr"];
    XCTAssertEqualObjects(query.state.sortKeys, @[ @"-yarr" ]);
    [query addDescendingOrder:@"yarr1"];
    XCTAssertEqualObjects(query.state.sortKeys, (@[ @"-yarr", @"-yarr1" ]));
}

- (void)testSortBySortDescriptors {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query orderBySortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"yarr" ascending:YES]];
    XCTAssertEqualObjects(query.state.sortKeys, @[ @"yarr" ]);

    [query orderBySortDescriptor:[NSSortDescriptor sortDescriptorWithKey:@"yarr" ascending:NO]];
    XCTAssertEqualObjects(query.state.sortKeys, @[ @"-yarr" ]);

    [query orderBySortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"yarr" ascending:YES],
                                     [NSSortDescriptor sortDescriptorWithKey:@"yarr1" ascending:NO] ]];
    XCTAssertEqualObjects(query.state.sortKeys, (@[ @"yarr", @"-yarr1" ]));
}

#pragma mark Conditions

- (void)testWhereKeyExists {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKeyExists:@"yolo"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$exists" : @YES} });
}

- (void)testWhereKeyDoesNotExist {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKeyDoesNotExist:@"yolo"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$exists" : @NO} });
}

- (void)testWhereKeyEqualTo {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" equalTo:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @"yarr" });
}

- (void)testWhereKeyNotEqualTo {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" notEqualTo:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$ne" : @"yarr"} });
}

- (void)testWhereEqualityValidation {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    XCTAssertNoThrow([query whereKey:@"a" equalTo:@"b"]);
    XCTAssertNoThrow([query whereKey:@"a" equalTo:@1]);
    XCTAssertNoThrow([query whereKey:@"a" equalTo:[NSDate date]]);
    XCTAssertNoThrow([query whereKey:@"a" equalTo:[NSNull null]]);
    XCTAssertNoThrow([query whereKey:@"a" equalTo:[[PFGeoPoint alloc] init]]);
    XCTAssertNoThrow([query whereKey:@"a" equalTo:[PFObject objectWithClassName:@"Yolo"]]);

    PFAssertThrowsInvalidArgumentException([query whereKey:@"a" equalTo:[NSValue valueWithNonretainedObject:@1]]);
}

- (void)testWhereKeyLessThan {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" lessThan:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$lt" : @"yarr"} });
}

- (void)testWhereKeyLessThanOrEqualTo {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" lessThanOrEqualTo:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$lte" : @"yarr"} });
}

- (void)testWhereKeyGreaterThan {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" greaterThan:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$gt" : @"yarr"} });
}

- (void)testWhereKeyGreaterThanOrEqualTo {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" greaterThanOrEqualTo:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$gte" : @"yarr"} });
}

- (void)testWhereOrderingClauseValidation {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    XCTAssertNoThrow([query whereKey:@"a" lessThanOrEqualTo:@"b"]);
    XCTAssertNoThrow([query whereKey:@"a" lessThan:@1]);
    XCTAssertNoThrow([query whereKey:@"a" greaterThan:[NSDate date]]);
    PFAssertThrowsInvalidArgumentException([query whereKey:@"a" lessThanOrEqualTo:[NSNull null]]);
    PFAssertThrowsInvalidArgumentException([query whereKey:@"a" lessThan:[[PFGeoPoint alloc] init]]);
    PFAssertThrowsInvalidArgumentException([query whereKey:@"a" greaterThan:[PFObject objectWithClassName:@"Yolo"]]);
}

- (void)testWhereContainedIn {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" containedIn:@[ @"yarr" ]];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$in" : @[ @"yarr" ]} });
}

- (void)testWhereNotContainedIn {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" notContainedIn:@[ @"yarr" ]];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$nin" : @[ @"yarr" ]} });
}

- (void)testWhereContainsAllObjectsInArray {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" containsAllObjectsInArray:@[ @"yarr" ]];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$all" : @[ @"yarr" ]} });
}

- (void)testWhereKeyNearGeoPoint {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:10.0 longitude:20.0];

    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" nearGeoPoint:geoPoint];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$nearSphere" : geoPoint} });
}

- (void)testWhereKeyNearGeoPointWithinMiles {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:10.0 longitude:20.0];

    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" nearGeoPoint:geoPoint withinMiles:3958.8];

    // $maxDistance is the max distance in radians relative to radius of earth?
    XCTAssertEqualObjects(query.state.conditions, (@{ @"yolo" : @{@"$nearSphere" : geoPoint, @"$maxDistance" : @1} }));
}

- (void)testWhereKeyNearGeoPointWithinKilometers {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:10.0 longitude:20.0];

    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" nearGeoPoint:geoPoint withinKilometers:6371.0];

    // $maxDistance is the max distance in radians relative to radius of earth?
    XCTAssertEqualObjects(query.state.conditions, (@{ @"yolo" : @{@"$nearSphere" : geoPoint, @"$maxDistance" : @1} }));
}

- (void)testWhereKeyNearGeoPointWithinRadians {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:10.0 longitude:20.0];

    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" nearGeoPoint:geoPoint withinRadians:10.0];
    XCTAssertEqualObjects(query.state.conditions, (@{ @"yolo" : @{@"$nearSphere" : geoPoint, @"$maxDistance" : @10} }));
}

- (void)testWhereKeyWithinGeobox {
    PFGeoPoint *geoPoint1 = [PFGeoPoint geoPointWithLatitude:10.0 longitude:20.0];
    PFGeoPoint *geoPoint2 = [PFGeoPoint geoPointWithLatitude:20.0 longitude:30.0];

    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" withinGeoBoxFromSouthwest:geoPoint1 toNortheast:geoPoint2];
    XCTAssertEqualObjects(query.state.conditions, (@{ @"yolo" : @{@"$within" : @{@"$box" : @[ geoPoint1, geoPoint2 ]}} }));
}

- (void)testWhereKeyMatchesRegex {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" matchesRegex:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$regex" : @"yarr"} });
}

- (void)testWhereKeyMatchesRegexModifiers {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" matchesRegex:@"yarr" modifiers:@"i"];
    XCTAssertEqualObjects(query.state.conditions, (@{ @"yolo" : @{@"$regex" : @"yarr", @"$options" : @"i"} }));
}

- (void)testWhereKeyContainsString {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" containsString:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$regex" : @"\\Qyarr\\E"} });
}

- (void)testWhereKeyHasPrefix {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" hasPrefix:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$regex" : @"^\\Qyarr\\E"} });
}

- (void)testWhereKeyHasSuffix {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" hasSuffix:@"yarr"];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$regex" : @"\\Qyarr\\E$"} });
}

- (void)testWhereKeyMatchesKeyInQuery {
    PFQuery *inQuery = [PFQuery queryWithClassName:@"b"];
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" matchesKey:@"yolo1" inQuery:inQuery];
    XCTAssertEqualObjects(query.state.conditions, (@{ @"yolo" : @{@"$select" : @{@"key" : @"yolo1", @"query" : inQuery}} }));
}

- (void)testWhereKeyDoesNotMatchKeyInQuery {
    PFQuery *inQuery = [PFQuery queryWithClassName:@"b"];
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" doesNotMatchKey:@"yolo1" inQuery:inQuery];
    XCTAssertEqualObjects(query.state.conditions, (@{ @"yolo" : @{@"$dontSelect" : @{@"key" : @"yolo1", @"query" : inQuery}} }));
}

- (void)testWhereKeyMatchesQuery {
    PFQuery *inQuery = [PFQuery queryWithClassName:@"b"];
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" matchesQuery:inQuery];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$inQuery" : inQuery} });
}

- (void)testWhereKeyDoesNotMatchQuery {
    PFQuery *inQuery = [PFQuery queryWithClassName:@"b"];
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"yolo" doesNotMatchQuery:inQuery];
    XCTAssertEqualObjects(query.state.conditions, @{ @"yolo" : @{@"$notInQuery" : inQuery} });
}

- (void)testWhereRelatedToObject {
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereRelatedToObject:object fromKey:@"yolo"];
    XCTAssertEqualObjects(query.state.conditions, (@{ @"$relatedTo" : @{@"key" : @"yolo", @"object" : object} }));
}

- (void)testRedirectClassNameForKey {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query redirectClassNameForKey:@"yolo"];
    XCTAssertEqualObjects(query.state.extraOptions, @{ @"redirectClassNameForKey" : @"yolo" });
}

#pragma mark Get Objects by Id

- (void)testGetObjectOfClassObjectId {
    PFMutableQueryState *state = [PFMutableQueryState stateWithParseClassName:@"Yolo"];
    state.limit = 1;
    state.skip = 0;
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];

    PFObject *result = [PFQuery getObjectOfClass:@"Yolo" objectId:@"yarr"];
    XCTAssertEqual(result, object);
}

- (void)testGetObjectOfClassObjectIdError {
    PFMutableQueryState *state = [PFMutableQueryState stateWithParseClassName:@"Yolo"];
    state.limit = 1;
    state.skip = 0;
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    NSError *originalError = [NSError errorWithDomain:@"TestDomain" code:100500 userInfo:nil];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:originalError];

    NSError *error = nil;
    PFObject *result = [PFQuery getObjectOfClass:@"Yolo" objectId:@"yarr" error:&error];
    XCTAssertNil(result);
    XCTAssertEqualObjects(error, originalError);
}

- (void)testGetObjectWithId {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state mutableCopy];
    [state removeAllConditions];
    state.limit = 1;
    state.skip = 0;
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];
    PFObject *result = [query getObjectWithId:@"yarr"];
    XCTAssertEqual(result, object);
}

- (void)testGetObjectWithIdError {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state mutableCopy];
    [state removeAllConditions];
    state.limit = 1;
    state.skip = 0;
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];
    NSError *originalError = [NSError errorWithDomain:@"TestDomain" code:100500 userInfo:nil];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ @"yolo" ] error:originalError];

    NSError *error = nil;
    PFObject *result = [query getObjectWithId:@"yarr" error:&error];
    XCTAssertNil(result);
    XCTAssertEqualObjects(error, originalError);
}

- (void)testGetObjectWithIdNotFoundError {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state mutableCopy];
    [state removeAllConditions];
    state.limit = 1;
    state.skip = 0;
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];
    [self mockQueryControllerFindObjectsForQueryState:state
                                           withResult:@[]
                                                error:nil];

    NSError *error = nil;
    PFObject *result = [query getObjectWithId:@"yarr" error:&error];
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
    XCTAssertEqual(error.code, kPFErrorObjectNotFound);
}

- (void)testGetObjectWithNilId {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    [Parse _currentManager].coreManager.queryController = PFStrictClassMock([PFQueryController class]);
    NSError *error = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertNil([query getObjectWithId:nil error:&error]);
#pragma clang diagnostic pop
    XCTAssertNil(error);
}

- (void)testGetObjectWithIdViaTask {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state mutableCopy];
    [state removeAllConditions];
    state.limit = 1;
    state.skip = 0;
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[query getObjectInBackgroundWithId:@"yarr"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, object);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testGetObjectWithIdViaBlock {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state mutableCopy];
    [state removeAllConditions];
    state.limit = 1;
    state.skip = 0;
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [query getObjectInBackgroundWithId:@"yarr" block:^(PFObject *result, NSError *error) {
        XCTAssertEqual(object, result);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testGetObjectWithIdViaBlockCacheThenNetwork {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query whereKey:@"a" equalTo:@"b"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];

    id controller = PFStrictClassMock([PFQueryController class]);
    [OCMStub([controller findObjectsAsyncForQueryState:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFMutableQueryState *state = [query.state mutableCopy];
        [state removeAllConditions];
        state.limit = 1;
        state.skip = 0;
        [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];
        state.cachePolicy = kPFCachePolicyCacheOnly;
        if ([state isEqual:obj]) {
            return YES;
        }
        state.cachePolicy = kPFCachePolicyNetworkOnly;
        if ([state isEqual:obj]) {
            return YES;
        }
        return NO;
    }] withCancellationToken:OCMOCK_ANY user:nil]) andReturn:[BFTask taskWithResult:@[ object ]]];
    [Parse _currentManager].coreManager.queryController = controller;

    XCTestExpectation *cacheExpectation = [self expectationWithDescription:@"cacheExpectation"];
    XCTestExpectation *networkExpectation = [self expectationWithDescription:@"networkExpectation"];
    __block NSUInteger counter = 0;
    [query getObjectInBackgroundWithId:@"yarr" block:^(PFObject *result, NSError *error) {
        if (counter == 0) {
            XCTAssertEqual(result, object);
            XCTAssertNil(error);
            [cacheExpectation fulfill];
        } else if (counter == 1) {
            XCTAssertEqual(result, object);
            XCTAssertNil(error);
            [networkExpectation fulfill];
        } else {
            XCTFail(@"PFQuery.countObjectsInBackgroundWithBlock called more than twice.");
        }
        counter++;
    }];
    [self waitForTestExpectations];
}

- (void)testGetObjectWithIdViaInvocation {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state mutableCopy];
    [state removeAllConditions];
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];
    state.limit = 1;
    state.skip = 0;

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    id verifier = PFStrictClassMock([QueryUnitTestsInvocationVerifier class]);
    OCMStub([verifier verifyObject:object error:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [query getObjectInBackgroundWithId:@"yarr" target:verifier selector:@selector(verifyObject:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

#pragma mark Get User Objects

- (void)testGetUserObjectWithId {
    PFMutableQueryState *state = [PFMutableQueryState stateWithParseClassName:@"_User"];
    state.limit = 1;
    state.skip = 0;
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];

    PFObject *result = [PFQuery getUserObjectWithId:@"yarr"];
    XCTAssertEqual(result, object);
}

- (void)testGetUserObjectWithIdError {
    PFMutableQueryState *state = [PFMutableQueryState stateWithParseClassName:@"_User"];
    state.limit = 1;
    state.skip = 0;
    [state setEqualityConditionWithObject:@"yarr" forKey:@"objectId"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    NSError *originalError = [NSError errorWithDomain:@"TestDomain" code:100500 userInfo:nil];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:originalError];

    NSError *error = nil;
    PFObject *result = [PFQuery getUserObjectWithId:@"yarr" error:&error];
    XCTAssertNil(result);
    XCTAssertEqualObjects(error, originalError);
}

- (void)testQueryForUser {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    PFQuery *query = [PFQuery queryForUser];
#pragma clang diagnostic pop

    PFMutableQueryState *state = [PFMutableQueryState stateWithParseClassName:@"_User"];
    XCTAssertEqualObjects(query.state, state);
}

#pragma mark Find Objects

- (void)testFindObjects {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    [self mockQueryControllerFindObjectsForQueryState:query.state withResult:@[ @"yolo" ] error:nil];
    NSArray *result = [query findObjects];
    XCTAssertEqualObjects(result, @[ @"yolo" ]);
}

- (void)testFindObjectsError {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    NSError *originalError = [NSError errorWithDomain:@"TestDomain" code:100500 userInfo:nil];
    [self mockQueryControllerFindObjectsForQueryState:query.state withResult:@[ @"yolo" ] error:originalError];

    NSError *error = nil;
    NSArray *result = [query findObjects:&error];
    XCTAssertNil(result);
    XCTAssertEqualObjects(error, originalError);
}

- (void)testFindObjectsViaTask {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    [self mockQueryControllerFindObjectsForQueryState:query.state withResult:@[ @"yolo" ] error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @[ @"yolo" ]);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsViaBlock {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    [self mockQueryControllerFindObjectsForQueryState:query.state withResult:@[ @"yolo" ] error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        XCTAssertEqualObjects(results, @[ @"yolo" ]);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsViaBlockCacheThenNetwork {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query whereKey:@"a" equalTo:@"b"];

    id controller = PFStrictClassMock([PFQueryController class]);
    [OCMStub([controller findObjectsAsyncForQueryState:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFMutableQueryState *state = [query.state mutableCopy];
        state.cachePolicy = kPFCachePolicyCacheOnly;
        if ([state isEqual:obj]) {
            return YES;
        }
        state.cachePolicy = kPFCachePolicyNetworkOnly;
        if ([state isEqual:obj]) {
            return YES;
        }
        return NO;
    }] withCancellationToken:OCMOCK_ANY user:nil]) andReturn:[BFTask taskWithResult:@[ @"yolo1" ]]];
    [Parse _currentManager].coreManager.queryController = controller;

    XCTestExpectation *cacheExpectation = [self expectationWithDescription:@"cacheExpectation"];
    XCTestExpectation *networkExpectation = [self expectationWithDescription:@"networkExpectation"];
    __block NSUInteger counter = 0;
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error) {
        if (counter == 0) {
            XCTAssertEqualObjects(results, @[ @"yolo1" ]);
            XCTAssertNil(error);
            [cacheExpectation fulfill];
        } else if (counter == 1) {
            XCTAssertEqualObjects(results, @[ @"yolo1" ]);
            XCTAssertNil(error);
            [networkExpectation fulfill];
        } else {
            XCTFail(@"PFQuery.findObjectsInBackgroundWithBlock called more than twice.");
        }
        counter++;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsViaInvocation {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:query.state withResult:@[ object ] error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    id verifier = PFStrictClassMock([QueryUnitTestsInvocationVerifier class]);
    OCMStub([verifier verifyArray:@[ object ] error:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [query findObjectsInBackgroundWithTarget:verifier selector:@selector(verifyArray:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testFindObjectsViaTaskCancellation {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    id controller = PFStrictClassMock([PFQueryController class]);
    [[OCMStub([controller findObjectsAsyncForQueryState:query.state
                                 withCancellationToken:[OCMArg isNotNil]
                                                  user:nil]) andDo:^(NSInvocation *invocation) {
        [query cancel];

        __unsafe_unretained BFCancellationToken *cancellationToken = nil;
        [invocation getArgument:&cancellationToken atIndex:3];
        XCTAssertTrue(cancellationToken.cancellationRequested);
    }] andReturn:[BFTask cancelledTask]];
    [Parse _currentManager].coreManager.queryController = controller;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsConcurrently {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    id controller = PFStrictClassMock([PFQueryController class]);
    [[OCMStub([controller findObjectsAsyncForQueryState:query.state
                                  withCancellationToken:[OCMArg isNotNil]
                                                   user:nil]) andDo:^(NSInvocation *invocation) {
        XCTAssertThrows([query findObjects]);
    }] andReturn:[BFTask cancelledTask]];
    [Parse _currentManager].coreManager.queryController = controller;

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[query findObjectsInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

#pragma mark Get First Object

- (void)testGetFirstObject {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state copy];
    state.limit = 1;
    state.skip = 0;

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];
    PFObject *result = [query getFirstObject];
    XCTAssertEqual(result, object);
}

- (void)testGetFirstObjectError {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state copy];
    state.limit = 1;
    state.skip = 0;

    NSError *originalError = [NSError errorWithDomain:@"TestDomain" code:100500 userInfo:nil];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ @"yolo" ] error:originalError];

    NSError *error = nil;
    PFObject *result = [query getFirstObject:&error];
    XCTAssertNil(result);
    XCTAssertEqualObjects(error, originalError);
}

- (void)testGetFirstObjectNotFoundError {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state copy];
    state.limit = 1;
    state.skip = 0;
    [self mockQueryControllerFindObjectsForQueryState:state
                                           withResult:@[]
                                                error:nil];

    NSError *error = nil;
    PFObject *result = [query getFirstObject:&error];
    XCTAssertNil(result);
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
    XCTAssertEqual(error.code, kPFErrorObjectNotFound);
}

- (void)testGetFirstObjectViaTask {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state copy];
    state.limit = 1;
    state.skip = 0;

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[query getFirstObjectInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, object);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testGetFirstObjectViaBlock {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state copy];
    state.limit = 1;
    state.skip = 0;

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *result, NSError *error) {
        XCTAssertEqual(object, result);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testGetFirstObjectViaBlockCacheThenNetwork {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query whereKey:@"a" equalTo:@"b"];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];

    id controller = PFStrictClassMock([PFQueryController class]);
    [OCMStub([controller findObjectsAsyncForQueryState:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFMutableQueryState *state = [query.state mutableCopy];
        state.limit = 1;
        state.skip = 0;
        state.cachePolicy = kPFCachePolicyCacheOnly;
        if ([state isEqual:obj]) {
            return YES;
        }
        state.cachePolicy = kPFCachePolicyNetworkOnly;
        if ([state isEqual:obj]) {
            return YES;
        }
        return NO;
    }] withCancellationToken:OCMOCK_ANY user:nil]) andReturn:[BFTask taskWithResult:@[ object ]]];
    [Parse _currentManager].coreManager.queryController = controller;

    XCTestExpectation *cacheExpectation = [self expectationWithDescription:@"cacheExpectation"];
    XCTestExpectation *networkExpectation = [self expectationWithDescription:@"networkExpectation"];
    __block NSUInteger counter = 0;
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *result, NSError *error) {
        if (counter == 0) {
            XCTAssertEqual(result, object);
            XCTAssertNil(error);
            [cacheExpectation fulfill];
        } else if (counter == 1) {
            XCTAssertEqual(result, object);
            XCTAssertNil(error);
            [networkExpectation fulfill];
        } else {
            XCTFail(@"PFQuery.countObjectsInBackgroundWithBlock called more than twice.");
        }
        counter++;
    }];
    [self waitForTestExpectations];
}

- (void)testGetFirstObjectViaInvocation {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    PFMutableQueryState *state = [query.state copy];
    state.limit = 1;
    state.skip = 0;

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    [self mockQueryControllerFindObjectsForQueryState:state withResult:@[ object ] error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    id verifier = PFStrictClassMock([QueryUnitTestsInvocationVerifier class]);
    OCMStub([verifier verifyObject:object error:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [query getFirstObjectInBackgroundWithTarget:verifier selector:@selector(verifyObject:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

#pragma mark Count Objects

- (void)testCountObjects {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    [self mockQueryControllerCountObjectsForQueryState:query.state withResult:@100500 error:nil];
    NSInteger result = [query countObjects];
    XCTAssertEqual(result, 100500);
}

- (void)testCountObjectsError {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    NSError *originalError = [NSError errorWithDomain:@"TestDomain" code:100500 userInfo:nil];
    [self mockQueryControllerCountObjectsForQueryState:query.state withResult:@[ @"yolo" ] error:originalError];

    NSError *error = nil;
    NSInteger result = [query countObjects:&error];
    XCTAssertEqual(result, -1);
    XCTAssertEqualObjects(error, originalError);
}

- (void)testCountObjectsViaTask {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    [self mockQueryControllerCountObjectsForQueryState:query.state withResult:@100500 error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[query countObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @100500);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCountObjectsViaBlock {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    [self mockQueryControllerCountObjectsForQueryState:query.state withResult:@100500 error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [query countObjectsInBackgroundWithBlock:^(int result, NSError *error) {
        XCTAssertEqual(result, 100500);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testCountObjectsViaBlockCacheThenNetwork {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query whereKey:@"a" equalTo:@"b"];

    id controller = PFStrictClassMock([PFQueryController class]);
    [OCMStub([controller countObjectsAsyncForQueryState:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFMutableQueryState *state = [query.state mutableCopy];
        state.cachePolicy = kPFCachePolicyCacheOnly;
        if ([state isEqual:obj]) {
            return YES;
        }
        state.cachePolicy = kPFCachePolicyNetworkOnly;
        if ([state isEqual:obj]) {
            return YES;
        }
        return NO;
    }] withCancellationToken:OCMOCK_ANY user:nil]) andReturn:[BFTask taskWithResult:@100500]];
    [Parse _currentManager].coreManager.queryController = controller;

    XCTestExpectation *cacheExpectation = [self expectationWithDescription:@"cacheExpectation"];
    XCTestExpectation *networkExpectation = [self expectationWithDescription:@"networkExpectation"];
    __block NSUInteger counter = 0;
    [query countObjectsInBackgroundWithBlock:^(int result, NSError *error) {
        if (counter == 0) {
            XCTAssertEqual(result, 100500);
            XCTAssertNil(error);
            [cacheExpectation fulfill];
        } else if (counter == 1) {
            XCTAssertEqual(result, 100500);
            XCTAssertNil(error);
            [networkExpectation fulfill];
        } else {
            XCTFail(@"PFQuery.countObjectsInBackgroundWithBlock called more than twice.");
        }
        counter++;
    }];
    [self waitForTestExpectations];
}

- (void)testCountObjectsViaInvocation {
    PFQuery *query = [PFQuery queryWithClassName:@"a"];
    [query whereKey:@"a" equalTo:@"b"];

    [self mockQueryControllerCountObjectsForQueryState:query.state withResult:@100500 error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    id verifier = PFStrictClassMock([QueryUnitTestsInvocationVerifier class]);
    OCMStub([verifier verifyNumber:@100500 error:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [query countObjectsInBackgroundWithTarget:verifier selector:@selector(verifyNumber:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

#pragma mark Local Datastore

- (void)testFromLocalDatastore {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"a" clientKey:@"b"];

    PFQuery *query = [PFQuery queryWithClassName:@"Yarr"];
    [query fromLocalDatastore];

    XCTAssertTrue(query.state.queriesLocalDatastore);
    XCTAssertNil(query.state.localDatastorePinName);
}

- (void)testFromPin {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"a" clientKey:@"b"];

    PFQuery *query = [PFQuery queryWithClassName:@"Yarr"];
    [query fromPin];

    XCTAssertTrue(query.state.queriesLocalDatastore);
    XCTAssertEqualObjects(query.state.localDatastorePinName, PFObjectDefaultPin);
}

- (void)testFromPinWithName {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"a" clientKey:@"b"];

    PFQuery *query = [PFQuery queryWithClassName:@"Yarr"];
    [query fromPinWithName:@"Yolo"];

    XCTAssertTrue(query.state.queriesLocalDatastore);
    XCTAssertEqualObjects(query.state.localDatastorePinName, @"Yolo");
}

- (void)testIgnoreACLs {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"a" clientKey:@"b"];

    PFQuery *query = [PFQuery queryWithClassName:@"Yarr"];
    [query ignoreACLs];

    XCTAssertTrue(query.state.shouldIgnoreACLs);
}

- (void)testIgnoreACLsOnNetworkQuery {
    [[Parse _currentManager] clearEventuallyQueue];
    [Parse _clearCurrentManager];
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"a" clientKey:@"b"];

    PFQuery *query = [[PFQuery queryWithClassName:@"TestObject"] ignoreACLs];
    PFAssertThrowsInconsistencyException([query findObjectsInBackground]);
    PFAssertThrowsInconsistencyException([query findObjectsInBackgroundWithBlock:nil]);
    PFAssertThrowsInconsistencyException([query countObjectsInBackground]);
    PFAssertThrowsInconsistencyException([query countObjectsInBackgroundWithBlock:nil]);
    PFAssertThrowsInconsistencyException([query getObjectInBackgroundWithId:@"1234"]);
    PFAssertThrowsInconsistencyException([query getObjectInBackgroundWithId:@"1234" block:nil]);
    PFAssertThrowsInconsistencyException([query getFirstObjectInBackground]);
    PFAssertThrowsInconsistencyException([query getFirstObjectInBackgroundWithBlock:nil]);
}

#pragma mark Copying

- (void)testNSCopying {
    PFQuery *query = [PFQuery queryWithClassName:@"Yarr"];

    [query whereKey:@"a" equalTo:@"bar"];
    [query orderByAscending:@"b"];
    [query includeKey:@"c"];
    [query selectKeys:@[ @"d" ]];
    [query redirectClassNameForKey:@"e"];

    query.limit = 10;
    query.skip = 20;

    query.cachePolicy = kPFCachePolicyIgnoreCache;
    query.maxCacheAge = 30.0;

    query.trace = YES;

    PFQuery *queryCopy = [query copy];

    XCTAssertEqualObjects(queryCopy.parseClassName, query.parseClassName);

    XCTAssertEqualObjects(queryCopy.state.conditions[@"a"], query.state.conditions[@"a"]);
    XCTAssertEqualObjects(queryCopy.state.sortOrderString, query.state.sortOrderString);
    XCTAssertEqualObjects([queryCopy.state.includedKeys anyObject], [query.state.includedKeys anyObject]);
    XCTAssertEqualObjects([queryCopy.state.selectedKeys anyObject], [query.state.selectedKeys anyObject]);
    XCTAssertEqualObjects([[queryCopy.state.extraOptions allValues] lastObject],
                          [[query.state.extraOptions allValues] lastObject]);

    XCTAssertEqual(queryCopy.limit, query.limit);
    XCTAssertEqual(queryCopy.skip, query.skip);

    XCTAssertEqual(queryCopy.cachePolicy, query.cachePolicy);
    XCTAssertEqual(queryCopy.maxCacheAge, query.maxCacheAge);

    XCTAssertEqual(queryCopy.trace, query.trace);
}

#pragma mark Predicates

- (void)testQueryFromValidComparisonPredicate {
    PFQuery *query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a == \"b\""]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @"b");

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a != \"b\""]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$ne" : @"b" });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a < \"b\""]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$lt" : @"b" });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a <= \"b\""]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$lte" : @"b" });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a > \"b\""]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$gt" : @"b" });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a >= \"b\""]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$gte" : @"b" });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a BEGINSWITH \"b\""]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$regex" : @"^\\Qb\\E" });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"%@ IN a", @1]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @1);

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a IN %@", @[ @1, @2, @3 ]]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], (@{ @"$in" : @[ @1, @2, @3 ] }));

    PFQuery *inQuery = [PFQuery queryWithClassName:@"Yolo"];
    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a IN %@", inQuery]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$inQuery" : inQuery });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a IN { 1, 2, 3 }"]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], (@{ @"$in" : @[ @1, @2, @3 ] }));

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a IN SELF"]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$exists" : @YES });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"NOT (a IN %@)", inQuery]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$notInQuery" : inQuery });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"NOT (a IN %@)", @[ @1, @2, @3 ]]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], (@{ @"$nin" : @[ @1, @2, @3 ] }));

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"NOT (a IN { 1, 2, 3 })"]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], (@{ @"$nin" : @[ @1, @2, @3 ] }));

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"NOT (a IN SELF)"]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$exists" : @NO });
}

- (void)testQueryFromInvalidComparisonPredicate {
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a = b"]]);
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a CONTAINS \"b\""]]);
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a ENDSWITH \"b\""]]);
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a MATCHES \"b\""]]);
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a LIKE \"b\""]]);
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a IN b"]]);
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"NOT (a IN b)"]]);

    NSComparisonPredicate *mockPredicate = PFClassMock([NSComparisonPredicate class]);
    OCMStub(mockPredicate.predicateOperatorType).andReturn(100500);
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:mockPredicate]);

    NSComparisonPredicate *predicate = [[NSComparisonPredicate alloc] initWithLeftExpression:[NSExpression expressionForAnyKey]
                                                                             rightExpression:[NSExpression expressionForAnyKey]
                                                                              customSelector:@selector(isEqual:)];
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:predicate]);
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:(NSPredicate *)@"Yolo"]);
}

- (void)testQueryFromValidCompoundPredicate {
    PFQuery *query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a != \"b\" AND a != \"c\""]];
    XCTAssertEqualObjects(query.state.conditions[@"a"], @{ @"$ne" : @"c" });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a != \"b\" OR a != \"c\""]];
    XCTAssertEqual([query.state.conditions[@"$or"] count], 2);
    XCTAssertEqualObjects([(PFQuery *)[query.state.conditions[@"$or"] firstObject] state].conditions[@"a"], @{ @"$ne" : @"b" });
    XCTAssertEqualObjects([(PFQuery *)[query.state.conditions[@"$or"] lastObject] state].conditions[@"a"], @{ @"$ne" : @"c" });

    query = [PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"(a != \"b\" AND b != \"c\") OR (a != \"b\" AND b != \"e\")"]];
    XCTAssertEqual([query.state.conditions[@"$or"] count], 2);
    XCTAssertEqualObjects([(PFQuery *)[query.state.conditions[@"$or"] firstObject] state].conditions[@"b"], @{ @"$ne" : @"c" });
    XCTAssertEqualObjects([(PFQuery *)[query.state.conditions[@"$or"] lastObject] state].conditions[@"b"], @{ @"$ne" : @"e" });
}

- (void)testQueryFromInvalidCompoundPredicate {
    PFAssertThrowsInconsistencyException([PFQuery queryWithClassName:@"A" predicate:[NSPredicate predicateWithFormat:@"a != \"b\" OR a != \"c\" OR a != \"d\" OR a != \"e\" OR a != \"f\""]]);
}

#pragma mark NSObject

- (void)testHash {
    PFQuery *queryA = [PFQuery queryWithClassName:@"aClass"];
    PFQuery *queryB = [PFQuery queryWithClassName:@"aClass"];
    XCTAssertEqual([queryA hash], [queryB hash]);
}

@end
