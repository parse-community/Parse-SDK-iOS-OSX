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
#import "PFCloudCodeController.h"
#import "PFCoreManager.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@protocol CloudCodeMockedObserver <NSObject>

- (void)callbackWithResult:(id)result error:(id)error;

@end

@interface CloudUnitTests : PFUnitTestCase

@end

@implementation CloudUnitTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (PFCloudCodeController *)cloudCodeControllerWithResult:(id)result error:(NSError *)error {
    BFTask *task = nil;
    if (error) {
        task = [BFTask taskWithError:error];
    } else {
        task = [BFTask taskWithResult:result];
    }

    id controllerMock = PFClassMock([PFCloudCodeController class]);
    OCMStub([controllerMock callCloudCodeFunctionAsync:OCMOCK_ANY
                                        withParameters:OCMOCK_ANY
                                          sessionToken:OCMOCK_ANY]).andReturn(task);
    return controllerMock;
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testCallFunction {
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:@{ @"a" : @"b" }
                                                                                            error:nil];
    id result = [PFCloud callFunction:@"a" withParameters:nil];
    XCTAssertEqualObjects(result, @{ @"a" : @"b" });

    NSError *error = nil;
    result = [PFCloud callFunction:@"a" withParameters:nil error:&error];
    XCTAssertEqualObjects(result, @{ @"a" : @"b" });
    XCTAssertNil(error);
}

- (void)testCallFunctionError {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:nil error:error];

    id result = [PFCloud callFunction:@"a" withParameters:nil];
    XCTAssertNil(result);

    NSError *cloudError = nil;
    result = [PFCloud callFunction:@"a" withParameters:nil error:&cloudError];
    XCTAssertEqualObjects(error, cloudError);
    XCTAssertNil(result);
}

- (void)testCallFunctionViaTask {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:result error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo" withParameters:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, result);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionViaBlock {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:result error:nil];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFCloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id cloudResult, NSError *error) {
        XCTAssertEqualObjects(cloudResult, result);
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionViaTargetSelector {
    NSDictionary *result = @{ @"a" : @{@"b" : @"c"} };
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:result error:nil];

    id mock = PFProtocolMock(@protocol(CloudCodeMockedObserver));

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    OCMStub([mock callbackWithResult:[OCMArg isEqual:result]
                               error:[OCMArg isNil]]).andCall(expectation, @selector(fulfill));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                               target:mock
                             selector:@selector(callbackWithResult:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testCallFunctionErrorViaTask {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:nil error:error];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFCloud callFunctionInBackground:@"yolo" withParameters:nil] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, error);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionErrorViaBlock {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:nil error:error];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFCloud callFunctionInBackground:@"yolo" withParameters:nil block:^(id result, NSError *cloudError) {
        XCTAssertNil(result);
        XCTAssertEqualObjects(error, cloudError);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];
}

- (void)testCallFunctionErrorViaTargetSelector {
    NSError *error = [NSError errorWithDomain:@"ParseTestDomain" code:100500 userInfo:nil];
    [Parse _currentManager].coreManager.cloudCodeController = [self cloudCodeControllerWithResult:nil error:error];

    id mock = PFProtocolMock(@protocol(CloudCodeMockedObserver));

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    OCMStub([mock callbackWithResult:[OCMArg isNil]
                               error:[OCMArg isEqual:error]]).andCall(expectation, @selector(fulfill));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [PFCloud callFunctionInBackground:@"yolo"
                       withParameters:nil
                               target:mock
                             selector:@selector(callbackWithResult:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testCallFunctionParameters {
    id controllerMock = PFClassMock([PFCloudCodeController class]);
    [Parse _currentManager].coreManager.cloudCodeController = controllerMock;

    NSDictionary *parameters = @{ @"a" : @{@"b" : @YES} };
    [PFCloud callFunction:@"yolo" withParameters:parameters];

    OCMVerify([controllerMock callCloudCodeFunctionAsync:[OCMArg isEqual:@"yolo"]
                                          withParameters:[OCMArg isEqual:parameters]
                                            sessionToken:[OCMArg isNil]]);
}

@end
