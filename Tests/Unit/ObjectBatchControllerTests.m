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
#import "PFObject.h"
#import "PFObjectBatchController.h"
#import "PFRESTCommand.h"
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
    XCTAssertTrue([object isDataAvailable]);
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
    XCTAssertTrue([object isDataAvailable]);
    OCMVerifyAll(commandRunner);
}

- (void)testUniqueObjects {
    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:@"123"];
    PFObject *fetchedObject = [PFObject objectWithClassName:@"Yarr"];
    fetchedObject.objectId = @"yarr";

    NSArray *array = [PFObjectBatchController uniqueObjectsArrayFromArray:@[ object, object, fetchedObject]
                                                      omitObjectsWithData:NO];
    XCTAssertEqual(array.count, 2);
    XCTAssertTrue([array containsObject:object]);
    XCTAssertTrue([array containsObject:fetchedObject]);
}

- (void)testUniqueObjectsOmittingFetched {
    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:@"yolo"];
    PFObject *fetchedObject = [PFObject objectWithClassName:@"Yarr"];
    fetchedObject.objectId = @"yarr";

    NSArray *array = [PFObjectBatchController uniqueObjectsArrayFromArray:@[ object, object, fetchedObject]
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

@end
