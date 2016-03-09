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
#import "PFObject.h"
#import "PFObjectFilePersistenceController.h"
#import "PFTestCase.h"
#import "PFPersistenceController.h"

@interface ObjectFilePersistenceControllerTests : PFTestCase

@end

@implementation ObjectFilePersistenceControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id)mockedDataSource {
    id dataSource = PFStrictProtocolMock(@protocol(PFPersistenceControllerProvider));
    OCMStub([dataSource persistenceController]).andReturn([self mockedPersistenceController]);
    return dataSource;
}

- (PFPersistenceController *)mockedPersistenceController {
    id controller = PFStrictClassMock([PFPersistenceController class]);
    id group = PFStrictProtocolMock(@protocol(PFPersistenceGroup));
    OCMStub([controller getPersistenceGroupAsync]).andReturn([BFTask taskWithResult:group]);
    return controller;
}

- (NSString *)testFilePathForSelector:(SEL)cmd {
    NSString *configPath = [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(cmd)];
    [[NSFileManager defaultManager] removeItemAtPath:configPath error:NULL];
    return configPath;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id dataSource = [self mockedDataSource];
    PFObjectFilePersistenceController *controller = [[PFObjectFilePersistenceController alloc] initWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);

    controller = [PFObjectFilePersistenceController controllerWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);
}

- (void)testLoadPersistentObject {
    id dataSource = [self mockedDataSource];
    id group = [[[dataSource persistenceController] getPersistenceGroupAsync] waitForResult:nil];

    PFObjectFilePersistenceController *controller = [PFObjectFilePersistenceController controllerWithDataSource:dataSource];

    NSDictionary *dictionary = @{ @"classname" : @"Yolo",
                                  @"data" : @{@"objectId" : @"100500", @"yarr" : @"pff"} };
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];

    OCMExpect([group beginLockedContentAccessAsyncToDataForKey:@"object"]).andReturn([BFTask taskWithResult:nil]);
    OCMExpect([group getDataAsyncForKey:@"object"]).andReturn([BFTask taskWithResult:data]);
    OCMExpect([group endLockedContentAccessAsyncToDataForKey:@"object"]).andReturn([BFTask taskWithResult:nil]);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller loadPersistentObjectAsyncForKey:@"object"] continueWithSuccessBlock:^id(BFTask *task) {
        PFObject *object = task.result;
        XCTAssertNotNil(object);
        XCTAssertEqualObjects(object.parseClassName, @"Yolo");
        XCTAssertEqualObjects(object.objectId, @"100500");
        XCTAssertEqualObjects(object[@"yarr"], @"pff");

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(group);
}

- (void)testPersistObjectForKey {
    id dataSource = [self mockedDataSource];
    id group = [[[dataSource persistenceController] getPersistenceGroupAsync] waitForResult:nil];

    OCMExpect([group beginLockedContentAccessAsyncToDataForKey:@"object"]).andReturn([BFTask taskWithResult:nil]);
    OCMExpect([group setDataAsync:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:obj options:0 error:nil];
        XCTAssertNotNil(dictionary);
        XCTAssertEqualObjects(dictionary[@"classname"], @"Yolo");
        XCTAssertEqualObjects(dictionary[@"data"][@"objectId"], @"100500");
        return YES;
    }] forKey:@"object"]).andReturn([BFTask taskWithResult:nil]);
    OCMExpect([group endLockedContentAccessAsyncToDataForKey:@"object"]).andReturn([BFTask taskWithResult:nil]);

    PFObjectFilePersistenceController *controller = [PFObjectFilePersistenceController controllerWithDataSource:dataSource];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    object.objectId = @"100500";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller persistObjectAsync:object forKey:@"object"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(group);
}

- (void)testRemovePersistenceObjectForKey {
    id dataSource = [self mockedDataSource];
    id group = [[[dataSource persistenceController] getPersistenceGroupAsync] waitForResult:nil];

    OCMExpect([group beginLockedContentAccessAsyncToDataForKey:@"object"]).andReturn([BFTask taskWithResult:nil]);
    OCMExpect([group removeDataAsyncForKey:@"object"]).andReturn([BFTask taskWithResult:nil]);
    OCMExpect([group endLockedContentAccessAsyncToDataForKey:@"object"]).andReturn([BFTask taskWithResult:nil]);

    PFObjectFilePersistenceController *controller = [PFObjectFilePersistenceController controllerWithDataSource:dataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller removePersistentObjectAsyncForKey:@"object"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(group);
}

@end
