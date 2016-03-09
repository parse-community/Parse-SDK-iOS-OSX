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
#import "OCMock+Parse.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFHTTPRequest.h"
#import "PFObjectPrivate.h"
#import "PFObjectBatchController.h"
#import "PFObjectState.h"
#import "PFRESTCommand.h"
#import "PFRESTObjectBatchCommand.h"
#import "PFUnitTestCase.h"

@interface ObjectBatchControllerTests : PFUnitTestCase

@end

@implementation ObjectBatchControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (id<PFCommandRunnerProvider>)mockedDataSource {
    id<PFCommandRunnerProvider> dataSource = PFStrictProtocolMock(@protocol(PFCommandRunnerProvider));
    id runner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    OCMStub(dataSource.commandRunner).andReturn(runner);
    return dataSource;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id<PFCommandRunnerProvider> dataSource = [self mockedDataSource];

    PFObjectBatchController *controller = [[PFObjectBatchController alloc] initWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);

    controller = [PFObjectBatchController controllerWithDataSource:dataSource];
    XCTAssertNotNil(controller);
    XCTAssertEqual((id)controller.dataSource, dataSource);
}

#pragma mark Fetch

- (void)testFetchAll {
    id<PFCommandRunnerProvider> dataSource = [self mockedDataSource];
    id commandRunner = dataSource.commandRunner;

    NSDictionary *result = @{ @"results" : @[ @{@"objectId" : @"abc", @"a" : @"b"} ] };
    [commandRunner mockCommandResult:result forCommandsPassingTest:^BOOL(id obj) {
        PFRESTCommand *command = obj;
        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
        XCTAssertEqualObjects(command.parameters, (@{@"where" : @{ @"objectId" : @{ @"$in": @[ @"abc" ] } },
                                                     @"limit" : @"1" }));
        XCTAssertNil(command.sessionToken);
        return YES;
    }];

    PFObjectBatchController *controller = [[PFObjectBatchController alloc] initWithDataSource:dataSource];

    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:@"abc"];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller fetchObjectsAsync:@[ object ] withSessionToken:nil] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertFalse(task.cancelled);
        XCTAssertFalse(task.faulted);
        XCTAssertNil(task.result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTAssertEqualObjects(object[@"a"], @"b");
    XCTAssertTrue(object.dataAvailable);
    OCMVerifyAll(commandRunner);
}

- (void)testFetchAllWithoutObjects {
    id dataSource = [self mockedDataSource];
    PFObjectBatchController *controller = [PFObjectBatchController controllerWithDataSource:dataSource];

    XCTAssertEqualObjects([[controller fetchObjectsAsync:@[] withSessionToken:nil] waitForResult:nil], @[]);
    XCTAssertNil([[controller fetchObjectsAsync:nil withSessionToken:nil] waitForResult:nil]);
}

- (void)testFetchAllWithMissingObjects {
    id<PFCommandRunnerProvider> dataSource = [self mockedDataSource];
    id commandRunner = dataSource.commandRunner;

    NSDictionary *result = @{ @"results" : @[ @{@"objectId" : @"abc", @"a" : @"b"} ] };
    [commandRunner mockCommandResult:result forCommandsPassingTest:^BOOL(id obj) {
        PFRESTCommand *command = obj;
        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodGET);
        XCTAssertEqualObjects(command.parameters, (@{@"where" : @{ @"objectId" : @{ @"$in": @[ @"abc", @"def" ] } },
                                                     @"limit" : @"2" }));
        XCTAssertNil(command.sessionToken);
        return YES;
    }];

    PFObjectBatchController *controller = [[PFObjectBatchController alloc] initWithDataSource:dataSource];

    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:@"abc"];
    PFObject *missingObject = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:@"def"];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller fetchObjectsAsync:@[ object, missingObject ]
                  withSessionToken:nil] continueWithBlock:^id(BFTask *task) {
        NSError *error = task.error;
        XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
        XCTAssertEqual(error.code, kPFErrorObjectNotFound);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    XCTAssertEqualObjects(object[@"a"], @"b");
    XCTAssertTrue(object.dataAvailable);
    OCMVerifyAll(commandRunner);
}

#pragma mark Delete

- (void)testDeleteAll {
    id<PFCommandRunnerProvider> dataSource = [self mockedDataSource];
    id commandRunner = dataSource.commandRunner;
    OCMStub([commandRunner serverURL]).andReturn([NSURL URLWithString:@"https://api.parse.com/1"]);

    NSString *sessionToken = [[NSUUID UUID] UUIDString];

    NSArray *result = @[ @{ @"success" : @{} }, @{ @"success" : @{} } ];
    [commandRunner mockCommandResult:result forCommandsPassingTest:^BOOL(PFRESTCommand *command) {
        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
        XCTAssertEqualObjects(command.parameters, (@{ @"requests" : @[ @{ @"method" : @"DELETE",
                                                                          @"path" : @"/1/classes/Yolo/id1" },
                                                                       @{ @"method" : @"DELETE",
                                                                          @"path" : @"/1/classes/Yolo/id2" }] }));
        XCTAssertEqualObjects(command.sessionToken, sessionToken);
        return YES;
    }];

    PFObjectBatchController *controller = [[PFObjectBatchController alloc] initWithDataSource:dataSource];
    NSArray *objects = @[ [PFObject objectWithoutDataWithClassName:@"Yolo" objectId:@"id1"],
                          [PFObject objectWithoutDataWithClassName:@"Yolo" objectId:@"id2"] ];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller deleteObjectsAsync:objects withSessionToken:sessionToken] continueWithSuccessBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, objects);
        for (PFObject *object in objects) {
            XCTAssertTrue(object._state.deleted);
        }
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testDeleteAllWithoutObjects {
    id dataSource = [self mockedDataSource];
    PFObjectBatchController *controller = [PFObjectBatchController controllerWithDataSource:dataSource];

    XCTAssertEqualObjects([[controller deleteObjectsAsync:@[] withSessionToken:nil] waitForResult:nil], @[]);
    XCTAssertNil([[controller deleteObjectsAsync:nil withSessionToken:nil] waitForResult:nil]);
}

- (void)testDeleteAllError {
    id<PFCommandRunnerProvider> dataSource = [self mockedDataSource];
    id commandRunner = dataSource.commandRunner;
    OCMStub([commandRunner serverURL]).andReturn([NSURL URLWithString:@"https://api.parse.com/1"]);

    NSString *sessionToken = [[NSUUID UUID] UUIDString];

    NSMutableArray *result = [NSMutableArray arrayWithCapacity:PFRESTObjectBatchCommandSubcommandsLimit];
    while (result.count < PFRESTObjectBatchCommandSubcommandsLimit) {
        [result addObject:@{ @"error" : @{@"code" : @(kPFErrorObjectNotFound), @"error" : @"yolo"} }];
    }
    [commandRunner mockCommandResult:result forCommandsPassingTest:^BOOL(PFRESTCommand *command) {
        XCTAssertEqualObjects(command.httpMethod, PFHTTPRequestMethodPOST);
        XCTAssertEqual([command.parameters[@"requests"] count], PFRESTObjectBatchCommandSubcommandsLimit);
        XCTAssertEqualObjects(command.sessionToken, sessionToken);
        return YES;
    }];

    PFObjectBatchController *controller = [[PFObjectBatchController alloc] initWithDataSource:dataSource];

    NSMutableArray *objects = [NSMutableArray arrayWithCapacity:PFRESTObjectBatchCommandSubcommandsLimit * 3];
    while (objects.count < PFRESTObjectBatchCommandSubcommandsLimit * 3) {
        PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yolo" objectId:[[NSUUID UUID] UUIDString]];
        [objects addObject:object];
    }

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[controller deleteObjectsAsync:objects withSessionToken:sessionToken] continueWithBlock:^id(BFTask *task) {
        NSError *error = task.error;
        XCTAssertNotNil(error);
        XCTAssertEqualObjects(error.domain, BFTaskErrorDomain);
        XCTAssertEqual([error.userInfo[@"errors"] count], objects.count);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

#pragma mark Utilities

- (void)testUniqueObjects {
    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:@"123"];
    PFObject *fetchedObject = [PFObject objectWithClassName:@"Yarr"];
    fetchedObject.objectId = @"yarr";

    NSArray *array = [PFObjectBatchController uniqueObjectsArrayFromArray:@[ object, object, fetchedObject ]
                                                      omitObjectsWithData:NO];
    XCTAssertEqual(array.count, 2);
    XCTAssertTrue([array containsObject:object]);
    XCTAssertTrue([array containsObject:fetchedObject]);
}

- (void)testUniqueObjectsOmittingFetched {
    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:@"yolo"];
    PFObject *fetchedObject = [PFObject objectWithClassName:@"Yarr"];
    fetchedObject.objectId = @"yarr";

    NSArray *array = [PFObjectBatchController uniqueObjectsArrayFromArray:@[ object, object, fetchedObject ]
                                                      omitObjectsWithData:YES];
    XCTAssertEqualObjects(array, @[ object ]);
}

- (void)testUniqueObjectsWithoutObjects {
    XCTAssertNil([PFObjectBatchController uniqueObjectsArrayFromArray:nil omitObjectsWithData:NO]);
    XCTAssertNil([PFObjectBatchController uniqueObjectsArrayFromArray:nil omitObjectsWithData:YES]);
    XCTAssertEqualObjects([PFObjectBatchController uniqueObjectsArrayFromArray:@[] omitObjectsWithData:NO], @[]);
    XCTAssertEqualObjects([PFObjectBatchController uniqueObjectsArrayFromArray:@[] omitObjectsWithData:YES], @[]);
}

- (void)testUniqueObjectsValidation {
    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:nil];
    PFAssertThrowsInvalidArgumentException([PFObjectBatchController uniqueObjectsArrayFromArray:@[ object ]
                                                                            omitObjectsWithData:NO]);
    PFAssertThrowsInvalidArgumentException([PFObjectBatchController uniqueObjectsArrayFromArray:@[ object ]
                                                                            omitObjectsWithData:YES]);

    object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:@"123"];
    PFObject *object2 = [PFObject objectWithoutDataWithClassName:@"Yolo" objectId:@"321"];
    PFAssertThrowsInvalidArgumentException(([PFObjectBatchController uniqueObjectsArrayFromArray:@[ object, object2 ]
                                                                             omitObjectsWithData:NO]));
    PFAssertThrowsInvalidArgumentException(([PFObjectBatchController uniqueObjectsArrayFromArray:@[ object, object2 ]
                                                                             omitObjectsWithData:YES]));
}

- (void)testUniqueObjectsUsingFilter {
    PFObject *nonUniqueObject = [PFObject objectWithClassName:@"Yolo"];
    NSArray *array = @[ nonUniqueObject,
                        [PFObject objectWithClassName:@"Yarr"],
                        nonUniqueObject ];
    NSArray *filteredArray = [PFObjectBatchController uniqueObjectsArrayFromArray:array usingFilter:^BOOL(PFObject *object) {
        return [object.parseClassName isEqualToString:@"Yolo"];
    }];

    XCTAssertNotNil(filteredArray);
    XCTAssertEqualObjects(filteredArray, @[ nonUniqueObject ]);

    filteredArray = [PFObjectBatchController uniqueObjectsArrayFromArray:@[] usingFilter:^BOOL(PFObject *object) {
        return YES;
    }];
    XCTAssertNotNil(filteredArray);
    XCTAssertEqualObjects(filteredArray, @[]);
}

@end
