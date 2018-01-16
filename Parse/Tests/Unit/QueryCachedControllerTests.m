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

#import "PFCachedQueryController.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFJSONSerialization.h"
#import "PFKeyValueCache.h"
#import "PFMutableQueryState.h"
#import "PFObject.h"
#import "PFRESTQueryCommand.h"
#import "PFTestCase.h"

@protocol CachedQueryControllerDataSource <PFCommandRunnerProvider, PFKeyValueCacheProvider>

@end

@interface QueryCachedControllerTests : PFTestCase

@end

@implementation QueryCachedControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFCommandRunnerProvider, PFKeyValueCacheProvider>)mockedDataSource {
    id<CachedQueryControllerDataSource> dataSource = PFStrictProtocolMock(@protocol(CachedQueryControllerDataSource));

    id<PFCommandRunning> runner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    OCMStub(dataSource.commandRunner).andReturn(runner);

    PFKeyValueCache *keyValueCache = PFStrictClassMock([PFKeyValueCache class]);
    OCMStub(dataSource.keyValueCache).andReturn(keyValueCache);

    return dataSource;
}

- (PFQueryState *)sampleQueryStateWithCachePolicy:(PFCachePolicy)cachePolicy {
    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"Yolo"];
    [queryState setEqualityConditionWithObject:@"yarr" forKey:@"name"];
    [queryState selectKeys:@[ @"name" ]];
    queryState.cachePolicy = cachePolicy;
    return [queryState copy];
}

- (PFCommandResult *)sampleCommandResult {
    PFCommandResult *result = [PFCommandResult commandResultWithResult:@{ @"results" : @[ @{@"className" : @"Yolo",
                                                                                            @"name" : @"yarr",
                                                                                            @"objectId" : @"abc",
                                                                                            @"job" : @"pirate"} ],
                                                                          @"count" : @5 }
                                                          resultString:nil
                                                          httpResponse:nil];
    return result;
}

- (void)assertFindObjectsResult:(NSArray *)result {
    XCTAssertNotNil(result);
    XCTAssertEqual(result.count, 1);

    PFObject *object = [result lastObject];
    XCTAssertNotNil(object);
    XCTAssertEqualObjects(object.parseClassName, @"Yolo");
    XCTAssertEqualObjects(object.objectId, @"abc");
    XCTAssertEqualObjects(object[@"name"], @"yarr");
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];

    PFCachedQueryController *controller = [[PFCachedQueryController alloc] initWithCommonDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.commonDataSource, dataSource);

    controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.commonDataSource, dataSource);
}

- (void)testFindObjectsIgnoreCache {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id runner = dataSource.commandRunner;
    BFTask *commandTask = [BFTask taskWithResult:[self sampleCommandResult]];
    OCMStub([[runner ignoringNonObjectArgs] runCommandAsync:[OCMArg isNotNil]
                                                withOptions:0
                                          cancellationToken:[OCMArg isNil]]).andReturn(commandTask);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyIgnoreCache];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        [self assertFindObjectsResult:task.result];
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsCacheOnly {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id cache = dataSource.keyValueCache;

    NSString *jsonString = [PFJSONSerialization stringFromJSONObject:[self sampleCommandResult].result];
    OCMStub([[cache ignoringNonObjectArgs] objectForKey:[OCMArg isNotNil] maxAge:0]).andReturn(jsonString);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyCacheOnly];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        [self assertFindObjectsResult:task.result];
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsCacheOnlyCorruptJSON {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id cache = dataSource.keyValueCache;
    OCMStub([[cache ignoringNonObjectArgs] objectForKey:[OCMArg isNotNil] maxAge:0]).andReturn(@"blah blah");

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyCacheOnly];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        NSError *error = task.error;
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
        XCTAssertEqual(error.code, kPFErrorCacheMiss);

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsNetworkOnly {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];

    id keyValueCache = dataSource.keyValueCache;
    OCMStub([keyValueCache setObject:[OCMArg isEqual:@"yolo"] forKey:[OCMArg isNotNil]]);

    id runner = dataSource.commandRunner;
    BFTask *commandTask = [BFTask taskWithResult:[self sampleCommandResult]];
    OCMStub([[runner ignoringNonObjectArgs] runCommandAsync:[OCMArg isNotNil]
                                                withOptions:0
                                          cancellationToken:[OCMArg isNil]]).andReturn(commandTask);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyNetworkOnly];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        [self assertFindObjectsResult:task.result];
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsCacheElseNetwork {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id cache = dataSource.keyValueCache;
    OCMStub([[cache ignoringNonObjectArgs] objectForKey:[OCMArg isNotNil] maxAge:0]).andReturn(nil);
    OCMStub([[cache ignoringNonObjectArgs] setObject:[OCMArg isEqual:@"yolo"] forKey:[OCMArg isNotNil]]);

    id runner = dataSource.commandRunner;
    BFTask *commandTask = [BFTask taskWithResult:[self sampleCommandResult]];
    OCMStub([[runner ignoringNonObjectArgs] runCommandAsync:[OCMArg isNotNil]
                                                withOptions:0
                                          cancellationToken:[OCMArg isNil]]).andReturn(commandTask);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyCacheElseNetwork];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        [self assertFindObjectsResult:task.result];
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsCacheElseNetworkCacheResult {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];

    id cache = dataSource.keyValueCache;
    NSString *jsonString = [PFJSONSerialization stringFromJSONObject:[self sampleCommandResult].result];
    OCMStub([[cache ignoringNonObjectArgs] objectForKey:[OCMArg isNotNil] maxAge:0]).andReturn(jsonString);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyCacheElseNetwork];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        [self assertFindObjectsResult:task.result];
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsNetworkElseCache {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];

    id cache = dataSource.keyValueCache;
    NSString *jsonString = [PFJSONSerialization stringFromJSONObject:[self sampleCommandResult].result];
    OCMStub([[cache ignoringNonObjectArgs] objectForKey:[OCMArg isNotNil] maxAge:0]).andReturn(jsonString);

    id runner = dataSource.commandRunner;
    BFTask *commandTask = [BFTask taskWithError:[NSError errorWithDomain:@"TestErrorDomain" code:100500 userInfo:nil]];
    OCMStub([[runner ignoringNonObjectArgs] runCommandAsync:[OCMArg isNotNil]
                                                withOptions:0
                                          cancellationToken:[OCMArg isNil]]).andReturn(commandTask);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyNetworkElseCache];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        [self assertFindObjectsResult:task.result];
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsNetworkElseCacheNetworkResult {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];

    id keyValueCache = dataSource.keyValueCache;
    OCMStub([keyValueCache setObject:[OCMArg isEqual:@"yolo"] forKey:[OCMArg isNotNil]]);

    id runner = dataSource.commandRunner;
    BFTask *commandTask = [BFTask taskWithResult:[self sampleCommandResult]];
    OCMStub([[runner ignoringNonObjectArgs] runCommandAsync:[OCMArg isNotNil]
                                                withOptions:0
                                          cancellationToken:[OCMArg isNil]]).andReturn(commandTask);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyNetworkElseCache];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        [self assertFindObjectsResult:task.result];
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsCacheThenNetwork {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyCacheThenNetwork];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFindObjectsUnknownPolicy {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:100];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller findObjectsAsyncForQueryState:state
                         withCancellationToken:nil
                                          user:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertNotNil(task.error);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCountObjectsIgnoreCache {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id runner = dataSource.commandRunner;
    BFTask *commandTask = [BFTask taskWithResult:[self sampleCommandResult]];
    OCMStub([[runner ignoringNonObjectArgs] runCommandAsync:[OCMArg isNotNil]
                                                withOptions:0
                                          cancellationToken:[OCMArg isNil]]).andReturn(commandTask);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyIgnoreCache];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller countObjectsAsyncForQueryState:state
                          withCancellationToken:nil
                                           user:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @5);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCountObjectsCacheOnly {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id cache = dataSource.keyValueCache;
    NSString *jsonString = [PFJSONSerialization stringFromJSONObject:[self sampleCommandResult].result];
    OCMStub([[cache ignoringNonObjectArgs] objectForKey:[OCMArg isNotNil] maxAge:0]).andReturn(jsonString);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:kPFCachePolicyCacheOnly];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller countObjectsAsyncForQueryState:state
                          withCancellationToken:nil
                                           user:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @5);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCacheKey {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id cache = dataSource.keyValueCache;

    NSString *jsonString = [PFJSONSerialization stringFromJSONObject:[self sampleCommandResult].result];
    OCMStub([[cache ignoringNonObjectArgs] objectForKey:[OCMArg isNotNil] maxAge:0]).andReturn(jsonString);

    PFQueryState *state = [self sampleQueryStateWithCachePolicy:0];
    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];

    NSString *cacheKey = [PFRESTQueryCommand findCommandForQueryState:state withSessionToken:@"a"].cacheKey;
    XCTAssertEqualObjects([controller cacheKeyForQueryState:state sessionToken:@"a"], cacheKey);
}

- (void)testHasCachedResult {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id cache = dataSource.keyValueCache;

    PFQueryState *state = [self sampleQueryStateWithCachePolicy:0];
    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];

    NSString *cacheKey = [PFRESTQueryCommand findCommandForQueryState:state withSessionToken:@"a"].cacheKey;

    NSString *jsonString = [PFJSONSerialization stringFromJSONObject:[self sampleCommandResult].result];
    OCMStub([[cache ignoringNonObjectArgs] objectForKey:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isEqual:cacheKey];
    }] maxAge:0]).andReturn(jsonString);

    XCTAssertTrue([controller hasCachedResultForQueryState:state sessionToken:@"a"]);

    cacheKey = [PFRESTQueryCommand findCommandForQueryState:state withSessionToken:nil].cacheKey;
    OCMStub([[cache ignoringNonObjectArgs] objectForKey:[OCMArg checkWithBlock:^BOOL(id obj) {
        return [obj isEqual:cacheKey];
    }] maxAge:0]).andReturn(nil);

    controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    XCTAssertFalse([controller hasCachedResultForQueryState:state sessionToken:nil]);
}

- (void)testClearCachedResult {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id cache = dataSource.keyValueCache;
    OCMExpect([cache removeObjectForKey:[OCMArg isNotNil]]);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    PFQueryState *state = [self sampleQueryStateWithCachePolicy:0];
    [controller clearCachedResultForQueryState:state sessionToken:@"a"];

    OCMVerifyAll(cache);
}

- (void)testClearAllCachedResults {
    id<PFCommandRunnerProvider, PFKeyValueCacheProvider> dataSource = [self mockedDataSource];
    id cache = dataSource.keyValueCache;
    OCMExpect([cache removeAllObjects]);

    PFCachedQueryController *controller = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
    [controller clearAllCachedResults];

    OCMVerifyAll(cache);
}

@end
