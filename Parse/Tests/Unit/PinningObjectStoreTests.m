/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

#import "BFTask+Private.h"
#import "PFOfflineStore.h"
#import "PFPin.h"
#import "PFPinningObjectStore.h"
#import "PFUnitTestCase.h"

@interface PinningObjectStoreTests : PFUnitTestCase

@end

@implementation PinningObjectStoreTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFOfflineStoreProvider>)mockedDataSource {
    id<PFOfflineStoreProvider> dataSource = PFStrictProtocolMock(@protocol(PFOfflineStoreProvider));
    PFOfflineStore *store = PFStrictClassMock([PFOfflineStore class]);
    OCMStub(dataSource.offlineStore).andReturn(store);
    return dataSource;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id dataSource = [self mockedDataSource];

    PFPinningObjectStore *store = [[PFPinningObjectStore alloc] initWithDataSource:dataSource];
    XCTAssertNotNil(dataSource);
    XCTAssertEqual((id)store.dataSource, dataSource);

    store = [PFPinningObjectStore storeWithDataSource:dataSource];
    XCTAssertNotNil(dataSource);
    XCTAssertEqual((id)store.dataSource, dataSource);
}

- (void)testFetchPin {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];

    PFPin *pin = [PFPin pinWithName:@"Yolo"];
    PFOfflineStore *offlineStore = dataSource.offlineStore;
    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:@[pin]]];

    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store fetchPinAsyncWithName:@"Yolo"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, pin);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFetchPinCaching {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];

    PFPin *pin = [PFPin pinWithName:@"Yolo"];
    PFOfflineStore *offlineStore = dataSource.offlineStore;
    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:@[pin]]];

    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[[store fetchPinAsyncWithName:@"Yolo"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, pin);
        return [store fetchPinAsyncWithName:@"Yolo"];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, pin);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testFetchNewPin {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];

    PFOfflineStore *offlineStore = dataSource.offlineStore;
    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:@[]]];

    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store fetchPinAsyncWithName:@"Yolo"] continueWithSuccessBlock:^id(BFTask *task) {
        PFPin *pin = task.result;
        XCTAssertEqualObjects(pin.name, @"Yolo");
        XCTAssertNil(pin.objects);
        [expectation fulfill];
        return [store fetchPinAsyncWithName:@"Yolo"];
    }];
    [self waitForTestExpectations];
}

- (void)testPinObjects {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];
    id offlineStore = dataSource.offlineStore;

    PFPin *pin = [PFPin pinWithName:@"Yolo"];
    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:@[ pin ]]];
    [OCMExpect([offlineStore saveObjectLocallyAsync:pin includeChildren:YES]) andReturn:[BFTask taskWithResult:nil]];

    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store pinObjectsAsync:@[ object ] withPinName:@"Yolo" includeChildren:YES] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        XCTAssertEqualObjects(pin.objects, @[ object ]);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(offlineStore);
}

- (void)testPinObjectsExistingPin {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];
    id offlineStore = dataSource.offlineStore;

    PFPin *pin = [PFPin pinWithName:@"Yolo"];

    PFObject *existingObject = [PFObject objectWithClassName:@"Yarr"];
    pin.objects = [@[ existingObject ] mutableCopy];

    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:@[ pin ]]];
    [OCMExpect([offlineStore saveObjectLocallyAsync:pin includeChildren:YES]) andReturn:[BFTask taskWithResult:nil]];

    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store pinObjectsAsync:@[ object ] withPinName:@"Yolo" includeChildren:YES] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        XCTAssertEqualObjects(pin.objects, (@[ existingObject, object ]));
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(offlineStore);
}

- (void)testPinZeroObjects {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];
    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store pinObjectsAsync:nil withPinName:@"Yolo" includeChildren:YES] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testPinObjectsWithoutChildren {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];
    id offlineStore = dataSource.offlineStore;

    PFPin *pin = [PFPin pinWithName:@"Yolo"];

    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:@[ pin ]]];
    [OCMExpect([offlineStore saveObjectLocallyAsync:pin withChildren:[OCMArg checkWithBlock:^BOOL(id obj) {
        return ([obj count] == 1);
    }]]) andReturn:[BFTask taskWithResult:nil]];

    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store pinObjectsAsync:@[ object ] withPinName:@"Yolo" includeChildren:NO] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        XCTAssertEqualObjects(pin.objects, (@[ object ]));
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(offlineStore);
}

- (void)testUnpinObjects {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];
    id offlineStore = dataSource.offlineStore;

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    PFPin *pin = [PFPin pinWithName:@"Yolo"];
    pin.objects = [@[ object, [PFObject objectWithClassName:@"Yarr"] ] mutableCopy];

    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:@[ pin ]]];
    [OCMExpect([offlineStore saveObjectLocallyAsync:pin includeChildren:YES]) andReturn:[BFTask taskWithResult:nil]];

    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store unpinObjectsAsync:@[ object ] withPinName:@"Yolo"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(offlineStore);
}

- (void)testUnpinObjectsEmptyPin {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];
    id offlineStore = dataSource.offlineStore;

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    PFPin *pin = [PFPin pinWithName:@"Yolo"];
    pin.objects = [@[ object ] mutableCopy];

    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:@[ pin ]]];
    [OCMExpect([offlineStore unpinObjectAsync:pin]) andReturn:[BFTask taskWithResult:nil]];

    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store unpinObjectsAsync:@[ object ] withPinName:@"Yolo"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(offlineStore);
}

- (void)testUnpinZeroObjects {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];
    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store unpinObjectsAsync:nil withPinName:@"Yolo"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testUnpinObjectsNoPin {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];
    id offlineStore = dataSource.offlineStore;
    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:nil]];
    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    PFObject *object = [PFObject objectWithClassName:@"Yarr"];
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store unpinObjectsAsync:@[ object ] withPinName:@"Yolo"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(offlineStore);
}

- (void)testUnpinAllObjects {
    id<PFOfflineStoreProvider> dataSource = [self mockedDataSource];

    PFPin *pin = [PFPin pinWithName:@"Yolo"];
    id offlineStore = dataSource.offlineStore;
    [OCMStub([offlineStore findAsyncForQueryState:[OCMArg isNotNil]
                                             user:nil
                                              pin:nil]) andReturn:[BFTask taskWithResult:@[pin]]];
    [OCMExpect([offlineStore unpinObjectAsync:pin]) andReturn:[BFTask taskWithResult:nil]];

    PFPinningObjectStore *store = [PFPinningObjectStore storeWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[store unpinAllObjectsAsyncWithPinName:@"Yolo"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
    OCMVerifyAll(offlineStore);
}

@end
