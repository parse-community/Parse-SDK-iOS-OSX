/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

@import Bolts.BFCancellationTokenSource;
@import Bolts.BFTask;

#import "OCMock+Parse.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFCoreManager.h"
#import "PFMutableQueryState.h"
#import "PFObjectPrivate.h"
#import "PFOfflineQueryController.h"
#import "PFOfflineStore.h"
#import "PFPin.h"
#import "PFPinningObjectStore.h"
#import "PFRelationPrivate.h"
#import "PFTestCase.h"
#import "PFUser.h"

@interface OfflineQueryControllerTests : PFTestCase

@end

@implementation OfflineQueryControllerTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    OCMStub(mockedProvider.offlineStore).andReturn(nil);
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    PFOfflineQueryController *offlineQueryController = [[PFOfflineQueryController alloc] initWithCommonDataSource:mockedProvider
                                                                                                   coreDataSource:objectStoreProvider];
    XCTAssertNotNil(offlineQueryController);
    XCTAssertEqual((id)offlineQueryController.commonDataSource, mockedProvider);
    XCTAssertEqual((id)offlineQueryController.coreDataSource, objectStoreProvider);

    offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                       coreDataSource:objectStoreProvider];
    XCTAssertNotNil(offlineQueryController);
    XCTAssertEqual((id)offlineQueryController.commonDataSource, mockedProvider);
    XCTAssertEqual((id)offlineQueryController.coreDataSource, objectStoreProvider);
}

- (void)testFindObjectsLDS {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    PFOfflineStore *mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    PFPinningObjectStore *pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);
    PFUser *mockedUser = PFStrictClassMock([PFUser class]);
    PFPin *mockedPin = PFStrictClassMock([PFPin class]);

    BFTask *pinTask = [BFTask taskWithResult:mockedPin];
    NSArray *mockedPinnedObjects = @[ @1, @2, @3 ];
    BFTask *resultsTask = [BFTask taskWithResult:mockedPinnedObjects];

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];
    queryState.queriesLocalDatastore = YES;
    queryState.localDatastorePinName = @"aPinName";

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);

    OCMStub([pinningObjectStore fetchPinAsyncWithName:@"aPinName"]).andReturn(pinTask);
    OCMStub([mockedOfflineStore findAsyncForQueryState:queryState
                                                  user:mockedUser
                                                   pin:mockedPin]).andReturn(resultsTask);

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[offlineQueryController findObjectsAsyncForQueryState:queryState
                                     withCancellationToken:nil
                                                      user:mockedUser] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(mockedPinnedObjects, task.result);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testFindObjectsLDSCancel {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    PFOfflineStore *mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    PFPinningObjectStore *pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];
    queryState.queriesLocalDatastore = YES;
    queryState.localDatastorePinName = @"aPinName";

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    [cancellationTokenSource cancel];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[offlineQueryController findObjectsAsyncForQueryState:queryState
                                     withCancellationToken:cancellationTokenSource.token
                                                      user:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testFindObjectsRelation {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    id mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    id pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);
    id mockedObject = PFStrictClassMock([PFObject class]);
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedRelation = PFStrictClassMock([PFRelation class]);
    id mockedRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];
    [queryState setRelationConditionWithObject:mockedObject forKey:@"relationKey"];

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);
    OCMStub(mockedProvider.commandRunner).andReturn(mockedRunner);

    OCMStub([mockedObject objectId]).andReturn(@"objectId");
    OCMStub([mockedObject parseClassName]).andReturn(@"MyClass");

    OCMStub([mockedObject isDataAvailableForKey:@"relationKey"]).andReturn(YES);
    OCMStub(mockedObject[@"relationKey"]).andReturn(mockedRelation);

    OCMStub([mockedUser sessionToken]).andReturn(@"sessionToken");

    OCMExpect([mockedRelation _addKnownObject:[OCMArg isKindOfClass:[PFObject class]]]);
    OCMExpect([mockedOfflineStore updateDataForObjectAsync:[OCMArg isKindOfClass:[PFObject class]]])
    .andDo(^(NSInvocation *invocation) {
        // Grab the argument passed in
        __unsafe_unretained id arg = nil;
        [invocation getArgument:&arg atIndex:2];

        // Create a task from it.
        __autoreleasing BFTask *resultTask = [BFTask taskWithResult:arg];
        [invocation setReturnValue:&resultTask];
    });

    NSDictionary *result = @{ @"results" : @[ @{@"className" : @"Yolo",
                                                @"name" : @"yarr",
                                                @"objectId" : @"abc",
                                                @"job" : @"pirate"} ],
                              @"count" : @5 };
    [mockedRunner mockCommandResult:result forCommandsPassingTest:^BOOL(id obj) {
        return YES;
    }];

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[offlineQueryController findObjectsAsyncForQueryState:queryState
                                     withCancellationToken:nil
                                                      user:mockedUser] continueWithBlock:^id(BFTask *task) {
        NSArray *results = task.result;

        XCTAssertNotNil(results);
        XCTAssertEqual(1, results.count);

        PFObject *object = [results firstObject];
        XCTAssertEqualObjects(object.parseClassName, @"Yolo");
        XCTAssertEqualObjects(object.objectId, @"abc");
        XCTAssertEqualObjects(object[@"name"], @"yarr");
        XCTAssertEqualObjects(object[@"job"], @"pirate");

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];

    OCMVerifyAll(mockedRelation);
    OCMVerifyAll(mockedOfflineStore);
}

- (void)testFindObjectsRelationCancel {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    id mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    id pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);
    id mockedObject = PFStrictClassMock([PFObject class]);
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedRelation = PFStrictClassMock([PFRelation class]);

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];
    [queryState setRelationConditionWithObject:mockedObject forKey:@"relationKey"];

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);

    OCMStub([mockedObject objectId]).andReturn(@"objectId");
    OCMStub([mockedObject parseClassName]).andReturn(@"MyClass");

    OCMStub([mockedObject isDataAvailableForKey:@"relationKey"]).andReturn(YES);
    OCMStub(mockedObject[@"relationKey"]).andReturn(mockedRelation);

    OCMStub([mockedUser sessionToken]).andReturn(@"sessionToken");

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    [cancellationTokenSource cancel];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[offlineQueryController findObjectsAsyncForQueryState:queryState
                                     withCancellationToken:cancellationTokenSource.token
                                                      user:mockedUser] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testFindObjectsNormal {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    id mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    id pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedRelation = PFStrictClassMock([PFRelation class]);
    id mockedRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);
    OCMStub(mockedProvider.commandRunner).andReturn(mockedRunner);

    OCMStub([mockedUser sessionToken]).andReturn(@"sessionToken");

    OCMExpect([mockedRelation _addKnownObject:[OCMArg isKindOfClass:[PFObject class]]]);
    OCMExpect([mockedOfflineStore updateDataForObjectAsync:[OCMArg isKindOfClass:[PFObject class]]])
    .andDo(^(NSInvocation *invocation) {
        // Grab the argument passed in
        __unsafe_unretained id arg = nil;
        [invocation getArgument:&arg atIndex:2];

        // Create a task from it.
        __autoreleasing BFTask *resultTask = [BFTask taskWithResult:arg];
        [invocation setReturnValue:&resultTask];
    });

    NSDictionary *result = @{ @"results" : @[ @{@"className" : @"Yolo",
                                                @"name" : @"yarr",
                                                @"objectId" : @"abc",
                                                @"job" : @"pirate"} ],
                              @"count" : @5 };
    [mockedRunner mockCommandResult:result forCommandsPassingTest:^BOOL(id obj) {
        return YES;
    }];

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[offlineQueryController findObjectsAsyncForQueryState:queryState
                                     withCancellationToken:nil
                                                      user:mockedUser] continueWithBlock:^id(BFTask *task) {
        NSArray *results = task.result;

        XCTAssertNotNil(results);
        XCTAssertEqual(1, results.count);

        PFObject *object = [results firstObject];
        XCTAssertEqualObjects(object.parseClassName, @"Yolo");
        XCTAssertEqualObjects(object.objectId, @"abc");
        XCTAssertEqualObjects(object[@"name"], @"yarr");
        XCTAssertEqualObjects(object[@"job"], @"pirate");

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testFindObjectsNormalCancel {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    id mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    id pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);
    id mockedUser = PFStrictClassMock([PFUser class]);

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);

    OCMStub([mockedUser sessionToken]).andReturn(@"sessionToken");

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    [cancellationTokenSource cancel];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[offlineQueryController findObjectsAsyncForQueryState:queryState
                                     withCancellationToken:cancellationTokenSource.token
                                                      user:mockedUser] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testCountObjectsLDS {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    id mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    id pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);
    id mockedObject = PFStrictClassMock([PFObject class]);
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedPin = PFStrictClassMock([PFPin class]);

    BFTask *mockedCountPinTask = [BFTask taskWithResult:@1337];

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];
    queryState.queriesLocalDatastore = YES;
    queryState.localDatastorePinName = @"aPinName";

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);

    OCMStub([mockedObject objectId]).andReturn(@"objectId");
    OCMStub([mockedObject parseClassName]).andReturn(@"MyClass");

    OCMStub([mockedUser sessionToken]).andReturn(@"sessionToken");

    OCMStub([pinningObjectStore fetchPinAsyncWithName:@"aPinName"]).andReturn(mockedPin);

    OCMStub([mockedOfflineStore countAsyncForQueryState:queryState
                                                   user:mockedUser
                                                    pin:mockedPin]).andReturn(mockedCountPinTask);

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[offlineQueryController countObjectsAsyncForQueryState:queryState
                                      withCancellationToken:nil
                                                       user:mockedUser] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, @1337);

        [expectation fulfill];
        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testCountObjectsLDSCancel {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    id mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    id pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);
    id mockedObject = PFStrictClassMock([PFObject class]);
    id mockedUser = PFStrictClassMock([PFUser class]);

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];
    queryState.queriesLocalDatastore = YES;
    queryState.localDatastorePinName = @"aPinName";

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);

    OCMStub([mockedObject objectId]).andReturn(@"objectId");
    OCMStub([mockedObject parseClassName]).andReturn(@"MyClass");

    OCMStub([mockedUser sessionToken]).andReturn(@"sessionToken");

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    [cancellationTokenSource cancel];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[offlineQueryController countObjectsAsyncForQueryState:queryState
                                      withCancellationToken:cancellationTokenSource.token
                                                       user:mockedUser] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);

        [expectation fulfill];
        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testCountObjectsNormal {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    id mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    id pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);
    id mockedUser = PFStrictClassMock([PFUser class]);
    id mockedRelation = PFStrictClassMock([PFRelation class]);
    id mockedRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);
    OCMStub(mockedProvider.commandRunner).andReturn(mockedRunner);

    OCMStub([mockedUser sessionToken]).andReturn(@"sessionToken");

    OCMExpect([mockedRelation _addKnownObject:[OCMArg isKindOfClass:[PFObject class]]]);
    OCMExpect([mockedOfflineStore updateDataForObjectAsync:[OCMArg isKindOfClass:[PFObject class]]])
    .andDo(^(NSInvocation *invocation) {
        // Grab the argument passed in
        __unsafe_unretained id arg = nil;
        [invocation getArgument:&arg atIndex:2];

        // Create a task from it.
        __autoreleasing BFTask *resultTask = [BFTask taskWithResult:arg];
        [invocation setReturnValue:&resultTask];
    });

    NSDictionary *result = @{ @"results" : @[ @{@"className" : @"Yolo",
                                                @"name" : @"yarr",
                                                @"objectId" : @"abc",
                                                @"job" : @"pirate"} ],
                              @"count" : @5 };
    [mockedRunner mockCommandResult:result forCommandsPassingTest:^BOOL(id obj) {
        return YES;
    }];

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[offlineQueryController countObjectsAsyncForQueryState:queryState
                                      withCancellationToken:nil
                                                       user:mockedUser] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(@5, task.result);
        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testCountObjectsNormalCancel {
    id<PFCoreManagerDataSource> mockedProvider = PFStrictProtocolMock(@protocol(PFCoreManagerDataSource));
    id<PFPinningObjectStoreProvider> objectStoreProvider = PFStrictProtocolMock(@protocol(PFPinningObjectStoreProvider));

    id mockedOfflineStore = PFStrictClassMock([PFOfflineStore class]);
    id pinningObjectStore = PFStrictClassMock([PFPinningObjectStore class]);
    id mockedUser = PFStrictClassMock([PFUser class]);

    PFMutableQueryState *queryState = [PFMutableQueryState stateWithParseClassName:@"ClassName"];

    OCMStub(objectStoreProvider.pinningObjectStore).andReturn(pinningObjectStore);
    OCMStub(mockedProvider.offlineStore).andReturn(mockedOfflineStore);

    OCMStub([mockedUser sessionToken]).andReturn(@"sessionToken");

    PFOfflineQueryController *offlineQueryController = [PFOfflineQueryController controllerWithCommonDataSource:mockedProvider
                                                                                                 coreDataSource:objectStoreProvider];

    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    [cancellationTokenSource cancel];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[offlineQueryController countObjectsAsyncForQueryState:queryState
                                      withCancellationToken:cancellationTokenSource.token
                                                       user:mockedUser] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);

        [expectation fulfill];

        return nil;
    }];

    [self waitForTestExpectations];
}

@end
