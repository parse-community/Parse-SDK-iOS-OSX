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

    OCMStub([mockedCommand resolveLocalIds]);

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

    OCMStub([mockedCommand resolveLocalIds]);
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

    OCMStub([mockedCommand resolveLocalIds]);

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

    OCMExpect([mockedCommand resolveLocalIds]);

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

@end
