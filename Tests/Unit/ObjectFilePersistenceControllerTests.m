/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Bolts.BFTask;

#import "PFFileManager.h"
#import "PFObject.h"
#import "PFObjectFilePersistenceController.h"
#import "PFUnitTestCase.h"

@interface ObjectFilePersistenceControllerTests : PFUnitTestCase

@end

@implementation ObjectFilePersistenceControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id)mockedDataSource {
    id dataSource = PFStrictProtocolMock(@protocol(PFFileManagerProvider));
    OCMStub([dataSource fileManager]).andReturn(PFStrictClassMock([PFFileManager class]));
    return dataSource;
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

    PFAssertThrowsInconsistencyException([PFObjectFilePersistenceController new]);
}

- (void)testLoadPersistentObject {
    id dataSource = [self mockedDataSource];
    id fileManager = [dataSource fileManager];

    NSString *path = [self testFilePathForSelector:_cmd];
    OCMStub([fileManager parseDataItemPathForPathComponent:@"object"]).andReturn(path);

    PFObjectFilePersistenceController *controller = [PFObjectFilePersistenceController controllerWithDataSource:dataSource];

    NSDictionary *dictionary = @{ @"classname" : @"Yolo",
                                  @"data" : @{@"objectId" : @"100500", @"yarr" : @"pff"} };
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    [data writeToFile:path atomically:YES];

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
}

- (void)testPersistObjectForKey {
    id dataSource = [self mockedDataSource];
    id fileManager = [dataSource fileManager];

    NSString *path = [self testFilePathForSelector:_cmd];
    OCMStub([fileManager parseDataItemPathForPathComponent:@"object"]).andReturn(path);

    PFObjectFilePersistenceController *controller = [PFObjectFilePersistenceController controllerWithDataSource:dataSource];

    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    object.objectId = @"100500";

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller persistObjectAsync:object forKey:@"object"] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertNil(task.result);
        NSData *data = [NSData dataWithContentsOfFile:path];
        XCTAssertNotNil(data);

        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        XCTAssertNotNil(dictionary);
        XCTAssertEqualObjects(dictionary[@"classname"], @"Yolo");
        XCTAssertEqualObjects(dictionary[@"data"][@"objectId"], @"100500");

        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

@end
