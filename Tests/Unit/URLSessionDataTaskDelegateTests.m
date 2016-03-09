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
#import "PFConstants.h"
#import "PFTestCase.h"
#import "PFURLSessionJSONDataTaskDelegate.h"

@interface URLSessionDataTaskDelegateTests : PFTestCase

@end

@implementation URLSessionDataTaskDelegateTests

- (void)testConstructors {
    id mockedTask = PFStrictClassMock([NSURLSessionTask class]);
    BFCancellationTokenSource *tokenSource = [BFCancellationTokenSource cancellationTokenSource];
    PFURLSessionJSONDataTaskDelegate *delegate = [[PFURLSessionJSONDataTaskDelegate alloc] initForDataTask:mockedTask
                                                                                     withCancellationToken:tokenSource.token];
    XCTAssertNotNil(delegate);
    XCTAssertEqual(mockedTask, delegate.dataTask);
    XCTAssertNotNil(delegate.resultTask);

    delegate = [PFURLSessionJSONDataTaskDelegate taskDelegateForDataTask:mockedTask
                                                   withCancellationToken:tokenSource.token];
    XCTAssertNotNil(delegate);
    XCTAssertEqual(mockedTask, delegate.dataTask);
    XCTAssertNotNil(delegate.resultTask);
}

- (void)testCancel {
    id mockedTask = PFStrictClassMock([NSURLSessionTask class]);

    BFCancellationTokenSource *source = [BFCancellationTokenSource cancellationTokenSource];
    PFURLSessionJSONDataTaskDelegate *delegate = [PFURLSessionJSONDataTaskDelegate taskDelegateForDataTask:mockedTask
                                                                                     withCancellationToken:source.token];
    XCTAssertFalse(delegate.resultTask.cancelled);

    OCMStub([mockedTask cancel]).andDo(^(NSInvocation *invocation) {
        [delegate URLSession:[NSURLSession sharedSession]
                        task:mockedTask
        didCompleteWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil]];
    });
    [source cancel];

    XCTAssertTrue(delegate.resultTask.cancelled);
}

- (void)testSuccess {
    NSURLSession *mockedSession = PFStrictClassMock([NSURLSession class]);
    id mockedTask = PFStrictClassMock([NSURLSessionTask class]);

    BFCancellationTokenSource *source = [BFCancellationTokenSource cancellationTokenSource];
    PFURLSessionJSONDataTaskDelegate *delegate = [PFURLSessionJSONDataTaskDelegate taskDelegateForDataTask:mockedTask
                                                                                     withCancellationToken:source.token];

    NSData *chunkA = [@"{ \"foo\" :" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *chunkB = [@" \"bar\" }" dataUsingEncoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                                                 statusCode:200
                                                                HTTPVersion:@"HTTP/1.1"
                                                               headerFields:nil];
    
    [delegate URLSession:mockedSession
                    task:mockedTask
         didSendBodyData:5
          totalBytesSent:5
totalBytesExpectedToSend:5];

    [delegate URLSession:mockedSession
                dataTask:mockedTask
      didReceiveResponse:urlResponse
       completionHandler:^(NSURLSessionResponseDisposition disposition) {
           XCTAssertEqual(disposition, NSURLSessionResponseAllow);
       }];

    [delegate URLSession:mockedSession dataTask:mockedTask didReceiveData:chunkA];
    [delegate URLSession:mockedSession dataTask:mockedTask didReceiveData:chunkB];

    [delegate URLSession:mockedSession task:mockedTask didCompleteWithError:nil];

    PFCommandResult *commandResult = delegate.resultTask.result;
    XCTAssertEqualObjects([commandResult result], (@{ @"foo" : @"bar" }));
}

- (void)testUnknownError {
    NSURLSession *mockedSession = PFStrictClassMock([NSURLSession class]);
    id mockedTask = PFStrictClassMock([NSURLSessionTask class]);

    BFCancellationTokenSource *source = [BFCancellationTokenSource cancellationTokenSource];
    PFURLSessionJSONDataTaskDelegate *delegate = [PFURLSessionJSONDataTaskDelegate taskDelegateForDataTask:mockedTask
                                                                                     withCancellationToken:source.token];

    NSError *expectedError = [NSError errorWithDomain:PFParseErrorDomain code:1337 userInfo:nil];

    NSData *chunk = [@"{ \"foo\" :" dataUsingEncoding:NSUTF8StringEncoding];
    NSURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                                             statusCode:500
                                                            HTTPVersion:@"HTTP/1.1"
                                                           headerFields:nil];
    [delegate URLSession:mockedSession
                    task:mockedTask
         didSendBodyData:5
          totalBytesSent:5
totalBytesExpectedToSend:5];

    [delegate URLSession:mockedSession
                dataTask:mockedTask
      didReceiveResponse:urlResponse
       completionHandler:^(NSURLSessionResponseDisposition disposition) {
           XCTAssertEqual(disposition, NSURLSessionResponseAllow);
       }];

    [delegate URLSession:mockedSession dataTask:mockedTask didReceiveData:chunk];

    [delegate URLSession:mockedSession task:mockedTask didCompleteWithError:expectedError];

    XCTAssertEqualObjects(delegate.resultTask.error.userInfo[@"originalError"], expectedError);
    XCTAssertEqualObjects(delegate.resultTask.error.userInfo[NSUnderlyingErrorKey], expectedError);
}

- (void)testJSONError {
    NSURLSession *mockedSession = PFStrictClassMock([NSURLSession class]);
    id mockedTask = PFStrictClassMock([NSURLSessionTask class]);

    BFCancellationTokenSource *source = [BFCancellationTokenSource cancellationTokenSource];
    PFURLSessionJSONDataTaskDelegate *delegate = [PFURLSessionJSONDataTaskDelegate taskDelegateForDataTask:mockedTask
                                                                                     withCancellationToken:source.token];

    NSError *expectedError = [NSError errorWithDomain:NSCocoaErrorDomain code:3840 userInfo:nil];

    NSData *chunk = [@"{ \"foo\" :" dataUsingEncoding:NSUTF8StringEncoding];
    NSURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                                             statusCode:200
                                                            HTTPVersion:@"HTTP/1.1"
                                                           headerFields:nil];
    [delegate URLSession:mockedSession
                    task:mockedTask
         didSendBodyData:5
          totalBytesSent:5
totalBytesExpectedToSend:5];

    [delegate URLSession:mockedSession
                dataTask:mockedTask
      didReceiveResponse:urlResponse
       completionHandler:^(NSURLSessionResponseDisposition disposition) {
           XCTAssertEqual(disposition, NSURLSessionResponseAllow);
       }];

    [delegate URLSession:mockedSession dataTask:mockedTask didReceiveData:chunk];
    [delegate URLSession:mockedSession task:mockedTask didCompleteWithError:nil];

    XCTAssertEqualObjects(delegate.resultTask.error.domain, expectedError.domain);
    XCTAssertEqual(delegate.resultTask.error.code, expectedError.code);
}

- (void)testHTTPError {
    NSURLSession *mockedSession = PFStrictClassMock([NSURLSession class]);
    id mockedTask = PFStrictClassMock([NSURLSessionTask class]);

    BFCancellationTokenSource *source = [BFCancellationTokenSource cancellationTokenSource];
    PFURLSessionJSONDataTaskDelegate *delegate = [PFURLSessionJSONDataTaskDelegate taskDelegateForDataTask:mockedTask
                                                                                     withCancellationToken:source.token];

    NSError *expectedError = [NSError errorWithDomain:PFParseErrorDomain
                                                 code:1337
                                             userInfo:@{
                                                        NSLocalizedDescriptionKey : @"An error",
                                                        @"temporary" : @1,
                                                        @"error" : @"An error",
                                                        @"code" : @1337
                                                        }];

    NSData *chunk = [@"{ \"error\" : \"An error\", \"code\": 1337 }" dataUsingEncoding:NSUTF8StringEncoding];
    NSURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"http://foo.bar"]
                                                             statusCode:500
                                                            HTTPVersion:@"HTTP/1.1"
                                                           headerFields:nil];
    [delegate URLSession:mockedSession
                    task:mockedTask
         didSendBodyData:5
          totalBytesSent:5
totalBytesExpectedToSend:5];

    [delegate URLSession:mockedSession
                dataTask:mockedTask
      didReceiveResponse:urlResponse
       completionHandler:^(NSURLSessionResponseDisposition disposition) {
           XCTAssertEqual(disposition, NSURLSessionResponseAllow);
       }];

    [delegate URLSession:mockedSession dataTask:mockedTask didReceiveData:chunk];
    [delegate URLSession:mockedSession task:mockedTask didCompleteWithError:nil];

    XCTAssertEqualObjects(delegate.resultTask.error, expectedError);
}

@end
