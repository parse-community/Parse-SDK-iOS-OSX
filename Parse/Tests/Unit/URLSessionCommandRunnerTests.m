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

#import "PFCommandResult.h"
#import "PFCommandRunningConstants.h"
#import "PFCommandURLRequestConstructor.h"
#import "PFRESTCommand.h"
#import "PFTestCase.h"
#import "PFObject.h"
#import "PFObjectPrivate.h"
#import "PFFieldOperation.h"
#import "PFURLSession.h"
#import "PFURLSessionCommandRunner_Private.h"

@interface URLSessionCommandRunnerTests : PFTestCase

@end

@implementation URLSessionCommandRunnerTests

- (void)testConstructors {
    id mockedDataSource = PFStrictProtocolMock(@protocol(PFInstallationIdentifierStoreProvider));
    NSURL *url = [NSURL URLWithString:@"https://parse.com/123"];

    PFURLSessionCommandRunner *commandRunner = [[PFURLSessionCommandRunner alloc] initWithDataSource:mockedDataSource
                                                                                       applicationId:@"appId"
                                                                                           clientKey:@"clientKey"
                                                                                           serverURL:url];
    XCTAssertNotNil(commandRunner);
    XCTAssertEqual(mockedDataSource, (id)commandRunner.dataSource);
    XCTAssertEqualObjects(@"appId", commandRunner.applicationId);
    XCTAssertEqualObjects(@"clientKey", commandRunner.clientKey);
    XCTAssertEqual(commandRunner.initialRetryDelay, PFCommandRunningDefaultRetryDelay);
    XCTAssertEqual(commandRunner.serverURL, url);

    commandRunner = [PFURLSessionCommandRunner commandRunnerWithDataSource:mockedDataSource
                                                             applicationId:@"appId"
                                                                 clientKey:@"clientKey"
                                                                 serverURL:url];
    XCTAssertNotNil(commandRunner);
    XCTAssertEqual(mockedDataSource, (id)commandRunner.dataSource);
    XCTAssertEqualObjects(@"appId", commandRunner.applicationId);
    XCTAssertEqualObjects(@"clientKey", commandRunner.clientKey);
    XCTAssertEqual(commandRunner.initialRetryDelay, PFCommandRunningDefaultRetryDelay);
    XCTAssertEqual(commandRunner.serverURL, url);
}

- (void)testRunCommand {
    id mockedDataSource = PFStrictProtocolMock(@protocol(PFInstallationIdentifierStoreProvider));
    id mockedSession = PFStrictClassMock([PFURLSession class]);
    id mockedRequestConstructor = PFStrictClassMock([PFCommandURLRequestConstructor class]);
    id mockedNotificationCenter = PFStrictClassMock([NSNotificationCenter class]);

    id mockedCommand = PFStrictClassMock([PFRESTCommand class]);
    id mockedCommandResult = PFStrictClassMock([PFCommandResult class]);

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://foo.bar"]];

    OCMStub([mockedCommand resolveLocalIds:(NSError * __autoreleasing *)[OCMArg anyPointer]]).andReturn(YES);

    OCMStub([mockedRequestConstructor getDataURLRequestAsyncForCommand:mockedCommand]).andReturn([BFTask taskWithResult:urlRequest]);
    [OCMExpect([mockedSession performDataURLRequestAsync:urlRequest
                                              forCommand:mockedCommand
                                       cancellationToken:nil]) andReturn:[BFTask taskWithResult:mockedCommandResult]];

    OCMStub([mockedSession invalidateAndCancel]);

    PFURLSessionCommandRunner *commandRunner = [[PFURLSessionCommandRunner alloc] initWithDataSource:mockedDataSource
                                                                                             session:mockedSession
                                                                                  requestConstructor:mockedRequestConstructor
                                                                                  notificationCenter:mockedNotificationCenter];

    XCTestExpectation *expecatation = [self currentSelectorTestExpectation];
    [[commandRunner runCommandAsync:mockedCommand withOptions:0] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, mockedCommandResult);

        [expecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedSession);
}

- (void)testRunCommandCancel {
    id mockedDataSource = PFStrictProtocolMock(@protocol(PFInstallationIdentifierStoreProvider));
    id mockedSession = PFStrictClassMock([PFURLSession class]);
    id mockedRequestConstructor = PFStrictClassMock([PFCommandURLRequestConstructor class]);
    id mockedNotificationCenter = PFStrictClassMock([NSNotificationCenter class]);

    id mockedCommand = PFStrictClassMock([PFRESTCommand class]);

    OCMStub([mockedSession invalidateAndCancel]);

    PFURLSessionCommandRunner *commandRunner = [[PFURLSessionCommandRunner alloc] initWithDataSource:mockedDataSource
                                                                                             session:mockedSession
                                                                                  requestConstructor:mockedRequestConstructor
                                                                                  notificationCenter:mockedNotificationCenter];

    BFCancellationTokenSource *cancellationToken = [BFCancellationTokenSource cancellationTokenSource];
    [cancellationToken cancel];

    XCTestExpectation *expecatation = [self currentSelectorTestExpectation];
    [[commandRunner runCommandAsync:mockedCommand
                        withOptions:0
                  cancellationToken:cancellationToken.token] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);

        [expecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];
}

- (void)testRunCommandRetry {
    id mockedDataSource = PFStrictProtocolMock(@protocol(PFInstallationIdentifierStoreProvider));
    id mockedSession = PFStrictClassMock([PFURLSession class]);
    id mockedRequestConstructor = PFStrictClassMock([PFCommandURLRequestConstructor class]);
    id mockedNotificationCenter = PFStrictClassMock([NSNotificationCenter class]);

    id mockedCommand = PFStrictClassMock([PFRESTCommand class]);

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://foo.bar"]];
    NSError *expectedError = [NSError errorWithDomain:PFParseErrorDomain
                                                 code:1337
                                             userInfo:@{ @"temporary" : @YES }];

    __block int performDataURLRequestCount = 0;

    OCMStub([mockedCommand resolveLocalIds:(NSError * __autoreleasing *)[OCMArg anyPointer]]).andReturn(YES);
    OCMStub([mockedRequestConstructor getDataURLRequestAsyncForCommand:mockedCommand]).andReturn([BFTask taskWithResult:urlRequest]);

    [OCMStub([mockedSession performDataURLRequestAsync:urlRequest
                                            forCommand:mockedCommand
                                     cancellationToken:nil]).andDo(^(NSInvocation *_) {
        performDataURLRequestCount++;
    }) andReturn:[BFTask taskWithError:expectedError]];

    OCMStub([mockedSession invalidateAndCancel]);

    PFURLSessionCommandRunner *commandRunner = [[PFURLSessionCommandRunner alloc] initWithDataSource:mockedDataSource
                                                                                             session:mockedSession
                                                                                  requestConstructor:mockedRequestConstructor
                                                                                  notificationCenter:mockedNotificationCenter];
    commandRunner.initialRetryDelay = DBL_MIN; // Lets not needlessly sleep here.

    XCTestExpectation *expecatation = [self currentSelectorTestExpectation];
    [[commandRunner runCommandAsync:mockedCommand
                        withOptions:PFCommandRunningOptionRetryIfFailed] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, expectedError);

        XCTAssertEqual(performDataURLRequestCount, PFCommandRunningDefaultMaxAttemptsCount);

        [expecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedSession);
}

- (void)testRunCommandInvalidSession {
    id mockedDataSource = PFStrictProtocolMock(@protocol(PFInstallationIdentifierStoreProvider));
    id mockedSession = PFStrictClassMock([PFURLSession class]);
    id mockedRequestConstructor = PFStrictClassMock([PFCommandURLRequestConstructor class]);
    id mockedNotificationCenter = PFStrictClassMock([NSNotificationCenter class]);

    id mockedCommand = PFStrictClassMock([PFRESTCommand class]);

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://foo.bar"]];
    NSError *expectedError = [NSError errorWithDomain:PFParseErrorDomain
                                                 code:kPFErrorInvalidSessionToken
                                             userInfo:nil];

    OCMStub([mockedCommand resolveLocalIds:(NSError * __autoreleasing *)[OCMArg anyPointer]]);
    OCMStub([mockedRequestConstructor getDataURLRequestAsyncForCommand:mockedCommand]).andReturn([BFTask taskWithResult:urlRequest]);

    [OCMStub([mockedSession performDataURLRequestAsync:urlRequest
                                            forCommand:mockedCommand
                                     cancellationToken:nil]).andDo(^(NSInvocation *_) {
    }) andReturn:[BFTask taskWithError:expectedError]];

    OCMExpect([mockedNotificationCenter postNotificationName:PFInvalidSessionTokenNotification object:[OCMArg any] userInfo:nil]);

    OCMStub([mockedSession invalidateAndCancel]);

    PFURLSessionCommandRunner *commandRunner = [[PFURLSessionCommandRunner alloc] initWithDataSource:mockedDataSource
                                                                                             session:mockedSession
                                                                                  requestConstructor:mockedRequestConstructor
                                                                                  notificationCenter:mockedNotificationCenter];
    commandRunner.initialRetryDelay = DBL_MIN; // Lets not needlessly sleep here.

    XCTestExpectation *expecatation = [self currentSelectorTestExpectation];
    [[commandRunner runCommandAsync:mockedCommand
                        withOptions:PFCommandRunningOptionRetryIfFailed] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.error, expectedError);
        OCMVerifyAll(mockedNotificationCenter);
        [expecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedSession);
}

- (void)testRunFileUpload {
    id mockedDataSource = PFStrictProtocolMock(@protocol(PFInstallationIdentifierStoreProvider));
    id mockedSession = PFStrictClassMock([PFURLSession class]);
    id mockedRequestConstructor = PFStrictClassMock([PFCommandURLRequestConstructor class]);
    id mockedNotificationCenter = PFStrictClassMock([NSNotificationCenter class]);

    id mockedCommand = PFStrictClassMock([PFRESTCommand class]);
    id mockedCommandResult = PFStrictClassMock([PFCommandResult class]);

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://foo.bar"]];

    __block int lastProgress = -1;
    PFProgressBlock progressBlock = [^(int progress) {
        XCTAssertGreaterThanOrEqual(progress, lastProgress);
        lastProgress = progress;
    } copy];

    OCMStub([mockedCommand resolveLocalIds:(NSError * __autoreleasing *)[OCMArg anyPointer]]).andReturn(YES);

    OCMExpect([mockedRequestConstructor getFileUploadURLRequestAsyncForCommand:mockedCommand
                                                               withContentType:@"content-type"
                                                         contentSourceFilePath:@"content-path"]).andReturn([BFTask taskWithResult:urlRequest]);

    [OCMExpect([mockedSession performFileUploadURLRequestAsync:urlRequest
                                                    forCommand:mockedCommand
                                     withContentSourceFilePath:@"content-path"
                                             cancellationToken:nil
                                                 progressBlock:progressBlock])
     andReturn:[BFTask taskWithResult:mockedCommandResult]];

    OCMStub([mockedSession invalidateAndCancel]);

    PFURLSessionCommandRunner *commandRunner = [[PFURLSessionCommandRunner alloc] initWithDataSource:mockedDataSource
                                                                                             session:mockedSession
                                                                                  requestConstructor:mockedRequestConstructor
                                                                                  notificationCenter:mockedNotificationCenter];

    XCTestExpectation *expecatation = [self currentSelectorTestExpectation];
    [[commandRunner runFileUploadCommandAsync:mockedCommand
                              withContentType:@"content-type"
                        contentSourceFilePath:@"content-path"
                                      options:0
                            cancellationToken:nil
                                progressBlock:progressBlock] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, mockedCommandResult);
        [expecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedSession);
}

- (void)testLocalIdResolution {
    id mockedDataSource = PFStrictProtocolMock(@protocol(PFInstallationIdentifierStoreProvider));
    id mockedSession = PFStrictClassMock([PFURLSession class]);
    id mockedRequestConstructor = PFStrictClassMock([PFCommandURLRequestConstructor class]);
    id mockedNotificationCenter = PFStrictClassMock([NSNotificationCenter class]);

    id mockedCommand = PFStrictClassMock([PFRESTCommand class]);
    id mockedCommandResult = PFStrictClassMock([PFCommandResult class]);

    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://foo.bar"]];

    OCMExpect([mockedCommand resolveLocalIds:(NSError * __autoreleasing *)[OCMArg anyPointer]]).andReturn(YES);

    OCMStub([mockedRequestConstructor getDataURLRequestAsyncForCommand:mockedCommand]).andReturn([BFTask taskWithResult:urlRequest]);
    [OCMStub([mockedSession performDataURLRequestAsync:urlRequest
                                            forCommand:mockedCommand
                                     cancellationToken:nil]) andReturn:[BFTask taskWithResult:mockedCommandResult]];

    OCMStub([mockedSession invalidateAndCancel]);

    PFURLSessionCommandRunner *commandRunner = [[PFURLSessionCommandRunner alloc] initWithDataSource:mockedDataSource
                                                                                             session:mockedSession
                                                                                  requestConstructor:mockedRequestConstructor
                                                                                  notificationCenter:mockedNotificationCenter];

    XCTestExpectation *expecatation = [self currentSelectorTestExpectation];
    [[commandRunner runCommandAsync:mockedCommand withOptions:0] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqual(task.result, mockedCommandResult);

        [expecatation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedCommand);
}

- (void)testLocalIdResolutionFailure {
    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yolo" localId:@"localId"];
    id command = [PFRESTCommand commandWithHTTPPath:@"" httpMethod:@"" parameters:@{@"object": object} sessionToken:nil error:nil];
    NSError *error;
    [command resolveLocalIds:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
    XCTAssertEqualObjects(error.localizedDescription, @"Tried to save an object with a pointer to a new, unsaved object. (Yolo)");
}

- (void)testLocalIdResolutionFailureWithNoLocalId {
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    id command = [PFRESTCommand commandWithHTTPPath:@"" httpMethod:@"" parameters:@{@"object": object} sessionToken:nil error:nil];
    NSError *error;
    [command resolveLocalIds:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
    XCTAssertEqualObjects(error.localizedDescription, @"Tried to resolve a localId for an object with no localId. (Yolo)");
}

- (void)testLocalIdResolutionWithArray {
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    id command = [PFRESTCommand commandWithHTTPPath:@"" httpMethod:@"" parameters:@{@"values":@[@(1), object]} sessionToken:nil error:nil];
    NSError *error;
    [command resolveLocalIds:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
    XCTAssertEqualObjects(error.localizedDescription, @"Tried to resolve a localId for an object with no localId. (Yolo)");
}

- (void)testLocalIdResolutionWithArrayAndMutlipleErrors {
    PFObject *objectWithLocalId = [PFObject objectWithoutDataWithClassName:@"Yolo" localId:@"localId"];
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    id command = [PFRESTCommand commandWithHTTPPath:@"" httpMethod:@"" parameters:@{@"values":@[objectWithLocalId, object]} sessionToken:nil error:nil];
    NSError *error;
    [command resolveLocalIds:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
    XCTAssertEqualObjects(error.localizedDescription, @"Tried to save an object with a pointer to a new, unsaved object. (Yolo)");
}

- (void)testLocalIdResolutionWithOperations {
    NSArray *possibleErrors = @[@"Tried to save an object with a pointer to a new, unsaved object. (Yolo)",
                                @"Tried to resolve a localId for an object with no localId. (Yolo)"];
    NSError *error;
    PFObject *objectWithLocalId = [PFObject objectWithoutDataWithClassName:@"Yolo" localId:@"localId"];
    PFObject *object = [PFObject objectWithClassName:@"Yolo"];
    PFAddOperation *addOperation = [PFAddOperation addWithObjects:@[objectWithLocalId, object]];
    id command = [PFRESTCommand commandWithHTTPPath:@"" httpMethod:@"" parameters:@{@"values":addOperation} sessionToken:nil error:nil];
    [command resolveLocalIds:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
    XCTAssertTrue([possibleErrors indexOfObject:error.localizedDescription] != NSNotFound);

    error = nil;

    PFAddUniqueOperation *addUniqueOperation = [PFAddUniqueOperation addUniqueWithObjects:@[objectWithLocalId, object]];
    command = [PFRESTCommand commandWithHTTPPath:@"" httpMethod:@"" parameters:@{@"values":addUniqueOperation} sessionToken:nil error:nil];
    [command resolveLocalIds:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
    XCTAssertTrue([possibleErrors indexOfObject:error.localizedDescription] != NSNotFound);

    error = nil;

    PFRemoveOperation *removeOperation = [PFRemoveOperation removeWithObjects:@[objectWithLocalId, object]];
    command = [PFRESTCommand commandWithHTTPPath:@"" httpMethod:@"" parameters:@{@"values":removeOperation} sessionToken:nil error:nil];
    [command resolveLocalIds:&error];
    XCTAssertNotNil(error);
    XCTAssertEqualObjects(error.domain, PFParseErrorDomain);
    XCTAssertTrue([possibleErrors indexOfObject:error.localizedDescription] != NSNotFound);
}

@end
