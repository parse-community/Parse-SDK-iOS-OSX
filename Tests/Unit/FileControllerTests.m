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
@import Bolts.BFTaskCompletionSource;

#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFFileController.h"
#import "PFFileManager.h"
#import "PFMutableFileState.h"
#import "PFTestCase.h"

@protocol FileControllerDataSource <PFCommandRunnerProvider, PFFileManagerProvider>

@end

@interface FileControllerTests : PFTestCase

@end

@implementation FileControllerTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (NSData *)sampleData {
    const char bytes[] = {
        0x0, 0x1, 0x2, 0x3,
        0x4, 0x5, 0x6, 0x7,
        0x8, 0x9, 0xA, 0xB,
        0xC, 0xD, 0xE, 0xF};

    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

- (NSString *)temporaryDirectory {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromClass([self class])];
}

- (id)mockedDataSource {
    id mockedDataSource = PFStrictProtocolMock(@protocol(FileControllerDataSource));
    id mockedCommandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    OCMStub([mockedDataSource commandRunner]).andReturn(mockedCommandRunner);

    id mockedFileManager = PFStrictClassMock([PFFileManager class]);

    OCMStub([mockedDataSource fileManager]).andReturn(mockedFileManager);
    OCMStub([mockedFileManager parseLocalSandboxDataDirectoryPath]).andReturn([self temporaryDirectory]);

    return mockedDataSource;
}

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    [[PFFileManager createDirectoryIfNeededAsyncAtPath:[self temporaryDirectory]] waitUntilFinished];
}

- (void)tearDown {
    [super tearDown];

    [[PFFileManager removeItemAtPathAsync:[self temporaryDirectory]] waitUntilFinished];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    id mockedDataSource = [self mockedDataSource];

    PFFileController *fileController = [[PFFileController alloc] initWithDataSource:mockedDataSource];
    XCTAssertEqual((id)fileController.dataSource, mockedDataSource);

    fileController = [PFFileController controllerWithDataSource:mockedDataSource];
    XCTAssertEqual((id)fileController.dataSource, mockedDataSource);
}

- (void)testDownload {
    id mockedDataSource = [self mockedDataSource];

    NSString *temporaryPath = [self temporaryDirectory];
    NSString *downloadsPath = [temporaryPath stringByAppendingPathComponent:@"downloads"];
    NSURL *tempPath = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:@"sampleData.dat"]];
    NSData *sampleData = [self sampleData];
    [sampleData writeToURL:tempPath atomically:YES];

    id mockedFileManager = [mockedDataSource fileManager];
    OCMStub([mockedFileManager parseCacheItemPathForPathComponent:@"PFFileCache"]).andReturn(downloadsPath);

    id mockedCommandRunner = [mockedDataSource commandRunner];
    OCMStub([mockedCommandRunner runFileDownloadCommandAsyncWithFileURL:tempPath
                                                         targetFilePath:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSString *path = obj;
        if (!path) {
            return NO;
        }
        [[NSData data] writeToFile:path atomically:YES];
        return YES;
    }]
                                                      cancellationToken:nil
                                                          progressBlock:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFProgressBlock block = obj;
        if (block) {
            block(100);
        }
        return block != nil;
    }]]).andReturn([BFTask taskWithResult:nil]);

    PFFileController *fileController = [PFFileController controllerWithDataSource:mockedDataSource];

    PFFileState *fileState = [[PFMutableFileState alloc] initWithName:@"sampleData"
                                                            urlString:[tempPath absoluteString]
                                                             mimeType:@"application/octet-stream"];

    __block int progress = -1;
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[fileController downloadFileAsyncWithState:fileState
                              cancellationToken:nil
                                  progressBlock:^(int percentDone) {
                                      XCTAssertTrue(progress <= percentDone);

                                      progress = percentDone;
                                  }] continueWithBlock:^id(BFTask *task) {
                                      XCTAssertNil(task.error);

                                      [expectation fulfill];

                                      return nil;
                                  }];
    [self waitForTestExpectations];
}

- (void)testDownloadSharesOperations {
    id mockedDataSource = [self mockedDataSource];

    NSString *temporaryPath = [self temporaryDirectory];
    NSString *downloadsPath = [temporaryPath stringByAppendingPathComponent:@"downloads"];
    NSURL *tempPath = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:@"sampleData.dat"]];
    NSData *sampleData = [self sampleData];
    [sampleData writeToURL:tempPath atomically:YES];

    id mockedFileManager = [mockedDataSource fileManager];
    OCMStub([mockedFileManager parseCacheItemPathForPathComponent:@"PFFileCache"]).andReturn(downloadsPath);

    __block BOOL enqueuedFirstDownload = NO;
    __block BOOL enqueuedSecondDownload = NO;

    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    __block PFProgressBlock progressBlock = nil;

    id mockedCommandRunner = [mockedDataSource commandRunner];
    OCMStub([mockedCommandRunner runFileDownloadCommandAsyncWithFileURL:tempPath
                                                         targetFilePath:[OCMArg checkWithBlock:^BOOL(id obj) {
        NSString *path = obj;
        if (!path) {
            return NO;
        }
        [[NSData data] writeToFile:path atomically:YES];
        return YES;
    }]
                                                      cancellationToken:nil
                                                          progressBlock:[OCMArg checkWithBlock:^BOOL(id obj) {
        progressBlock = obj;
        return progressBlock != nil;
    }]]).andReturn(taskCompletionSource.task).andDo(^(NSInvocation *invocation) {
        XCTAssertFalse(enqueuedFirstDownload);
        enqueuedFirstDownload = YES;
    });

    PFFileController *fileController = [PFFileController controllerWithDataSource:mockedDataSource];

    PFFileState *fileState = [[PFMutableFileState alloc] initWithName:@"sampleData"
                                                            urlString:[tempPath absoluteString]
                                                             mimeType:@"application/octet-stream"];

    XCTestExpectation *firstExpectation = [self expectationWithDescription:@"downloadFileAsyncWithStateNumber1"];
    [[fileController downloadFileAsyncWithState:fileState cancellationToken:nil progressBlock:^(int percentDone) {
        XCTAssertGreaterThan(percentDone, 0);
        XCTAssertLessThanOrEqual(percentDone, 100);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        [firstExpectation fulfill];

        return nil;
    }];

    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:10.0];
    // Wait till the download operation starts
    while (!enqueuedFirstDownload && [timeoutDate timeIntervalSinceNow] > 0.0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    XCTestExpectation *secondExpectation = [self expectationWithDescription:@"downloadFileAsyncWithStateNumber2"];
    [[fileController downloadFileAsyncWithState:fileState cancellationToken:nil progressBlock:^(int percentDone) {
        XCTAssertGreaterThan(percentDone, 0);
        XCTAssertLessThanOrEqual(percentDone, 100);
        enqueuedSecondDownload = YES;
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        [secondExpectation fulfill];

        return nil;
    }];

    // Wait till the second operation is enqueued
    timeoutDate = [NSDate dateWithTimeIntervalSinceNow:10.0];
    while (!enqueuedSecondDownload && [timeoutDate timeIntervalSinceNow] > 0.0) {
        progressBlock(50);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    [taskCompletionSource trySetResult:nil];

    [self waitForTestExpectations];
}

- (void)testDownloadCancel {
    id mockedDataSource = [self mockedDataSource];

    NSString *temporaryPath = [self temporaryDirectory];
    NSString *downloadsPath = [temporaryPath stringByAppendingPathComponent:@"downloads"];
    NSURL *tempPath = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:@"sampleData.dat"]];
    NSData *sampleData = [self sampleData];
    [sampleData writeToURL:tempPath atomically:YES];

    id mockedFileManager = [mockedDataSource fileManager];
    OCMStub([mockedFileManager parseCacheItemPathForPathComponent:@"PFFileCache"]).andReturn(downloadsPath);

    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];

    id mockedCommandRunner = [mockedDataSource commandRunner];
    OCMStub([mockedCommandRunner runFileDownloadCommandAsyncWithFileURL:tempPath
                                                         targetFilePath:[OCMArg isNotNil]
                                                      cancellationToken:cancellationTokenSource.token
                                                          progressBlock:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFProgressBlock block = obj;
        if (block) {
            block(100);
        }
        return block != nil;
    }]]).andReturn([BFTask cancelledTask]);

    PFFileController *fileController = [PFFileController controllerWithDataSource:mockedDataSource];
    PFFileState *fileState = [[PFMutableFileState alloc] initWithName:@"sampleData"
                                                            urlString:[tempPath absoluteString]
                                                             mimeType:@"application/octet-stream"];

    __block int progress = -1;
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];


    [[fileController downloadFileAsyncWithState:fileState
                              cancellationToken:cancellationTokenSource.token
                                  progressBlock:^(int percentDone) {
                                      XCTAssertTrue(progress <= percentDone);
                                      progress = percentDone;
                                  }] continueWithBlock:^id(BFTask *task) {
                                      XCTAssertTrue(task.cancelled);
                                      [expectation fulfill];
                                      return nil;
                                  }];
    [cancellationTokenSource cancel];
    [self waitForTestExpectations];
}

- (void)testDownloadStream {
    id mockedDataSource = [self mockedDataSource];

    NSString *temporaryPath = [self temporaryDirectory];
    NSString *downloadsPath = [temporaryPath stringByAppendingPathComponent:@"downloads"];
    NSURL *tempPath = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:@"sampleData.dat"]];
    NSData *sampleData = [self sampleData];
    [sampleData writeToURL:tempPath atomically:YES];

    id mockedFileManager = [mockedDataSource fileManager];
    OCMStub([mockedFileManager parseCacheItemPathForPathComponent:@"PFFileCache"]).andReturn(downloadsPath);

    id mockedCommandRunner = [mockedDataSource commandRunner];
    OCMStub([mockedCommandRunner runFileDownloadCommandAsyncWithFileURL:tempPath
                                                         targetFilePath:[OCMArg isNotNil]
                                                      cancellationToken:nil
                                                          progressBlock:[OCMArg checkWithBlock:^BOOL(id obj) {
        PFProgressBlock block = obj;
        if (block) {
            block(100);
        }
        return block != nil;
    }]]).andReturn([BFTask taskWithResult:nil]);

    PFFileController *fileController = [PFFileController controllerWithDataSource:mockedDataSource];
    PFFileState *fileState = [[PFMutableFileState alloc] initWithName:@"sampleData"
                                                            urlString:[tempPath absoluteString]
                                                             mimeType:@"application/octet-stream"];

    __block int progress = -1;
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[fileController downloadFileStreamAsyncWithState:fileState
                                    cancellationToken:nil
                                        progressBlock:^(int percentDone) {
                                            XCTAssertTrue(progress <= percentDone);

                                            progress = percentDone;
                                        }] continueWithBlock:^id(BFTask *task) {
                                            XCTAssertNil(task.error);
                                            PFAssertIsKindOfClass(task.result, [NSInputStream class]);
                                            [expectation fulfill];
                                            return nil;
                                        }];
    [self waitForTestExpectations];
}

- (void)testDownloadStreamSharesOperations {
    id mockedDataSource = [self mockedDataSource];

    NSString *temporaryPath = [self temporaryDirectory];
    NSURL *tempPath = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:@"sampleData.dat"]];
    NSData *sampleData = [self sampleData];
    [sampleData writeToURL:tempPath atomically:YES];

    __block BOOL enqueuedFirstDownload = NO;
    __block BOOL enqueuedSecondDownload = NO;

    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    __block PFProgressBlock progressBlock = nil;

    id mockedCommandRunner = [mockedDataSource commandRunner];
    OCMStub([mockedCommandRunner runFileDownloadCommandAsyncWithFileURL:tempPath
                                                         targetFilePath:[OCMArg isNotNil]
                                                      cancellationToken:nil
                                                          progressBlock:[OCMArg checkWithBlock:^BOOL(id obj) {
        progressBlock = obj;
        return progressBlock != nil;
    }]]).andReturn(taskCompletionSource.task).andDo(^(NSInvocation *invocation) {
        XCTAssertFalse(enqueuedFirstDownload);
        enqueuedFirstDownload = YES;
    });

    PFFileController *fileController = [PFFileController controllerWithDataSource:mockedDataSource];

    PFFileState *fileState = [[PFMutableFileState alloc] initWithName:@"sampleData"
                                                            urlString:[tempPath absoluteString]
                                                             mimeType:@"application/octet-stream"];

    XCTestExpectation *firstExpectation = [self expectationWithDescription:@"downloadFileAsyncWithStateNumber1"];
    [[fileController downloadFileStreamAsyncWithState:fileState cancellationToken:nil progressBlock:^(int percentDone) {
        XCTAssertGreaterThan(percentDone, 0);
        XCTAssertLessThanOrEqual(percentDone, 100);
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        PFAssertIsKindOfClass(task.result, [NSInputStream class]);
        [firstExpectation fulfill];
        return nil;
    }];

    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:10.0];
    // Wait till the download operation starts
    while (!enqueuedFirstDownload && [timeoutDate timeIntervalSinceNow] > 0.0) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    XCTestExpectation *secondExpectation = [self expectationWithDescription:@"downloadFileAsyncWithStateNumber2"];
    [[fileController downloadFileStreamAsyncWithState:fileState cancellationToken:nil progressBlock:^(int percentDone) {
        XCTAssertGreaterThan(percentDone, 0);
        XCTAssertLessThanOrEqual(percentDone, 100);
        enqueuedSecondDownload = YES;
    }] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        PFAssertIsKindOfClass(task.result, [NSInputStream class]);
        [secondExpectation fulfill];
        return nil;
    }];

    // Wait till the second operation is enqueued
    timeoutDate = [NSDate dateWithTimeIntervalSinceNow:10.0];
    while (!enqueuedSecondDownload && [timeoutDate timeIntervalSinceNow] > 0.0) {
        progressBlock(50);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }

    [taskCompletionSource trySetResult:nil];

    [self waitForTestExpectations];
}

- (void)testUpload {
    id mockedDataSource = [self mockedDataSource];

    NSString *temporaryPath = [self temporaryDirectory];
    NSString *downloadsPath = [temporaryPath stringByAppendingPathComponent:@"downloads"];
    NSURL *tempPath = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:@"sampleData.dat"]];
    NSData *sampleData = [self sampleData];
    [sampleData writeToURL:tempPath atomically:YES];

    id mockedFileManager = [mockedDataSource fileManager];
    OCMStub([mockedFileManager parseCacheItemPathForPathComponent:@"PFFileCache"]).andReturn(downloadsPath);



    NSDictionary *result = (@{ @"name": @"sampleData", @"url": [tempPath absoluteString] });
    PFCommandResult *commandResult = [PFCommandResult commandResultWithResult:result
                                                                 resultString:nil
                                                                 httpResponse:nil];

    id mockedCommandRunner = [mockedDataSource commandRunner];
    [OCMStub(([[mockedCommandRunner ignoringNonObjectArgs] runFileUploadCommandAsync:[OCMArg isNotNil]
                                                                      withContentType:@"application/octet-stream"
                                                                contentSourceFilePath:[tempPath path]
                                                                              options:0
                                                                    cancellationToken:nil
                                                                        progressBlock:[OCMArg isNotNil]])) andReturn:[BFTask taskWithResult:commandResult]];

    PFFileController *fileController = [PFFileController controllerWithDataSource:mockedDataSource];
    PFFileState *fileState = [[PFMutableFileState alloc] initWithName:@"sampleData"
                                                            urlString:nil
                                                             mimeType:@"application/octet-stream"];

    __block int progress = -1;
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[fileController uploadFileAsyncWithState:fileState
                               sourceFilePath:[tempPath path]
                                 sessionToken:@"session-token"
                            cancellationToken:nil
                                progressBlock:^(int percentDone) {
                                    XCTAssertTrue(progress <= percentDone);
                                    progress = percentDone;
                                }] continueWithBlock:^id(BFTask<PFFileState *> *task) {
                                    XCTAssertNotNil(task.result);
                                    XCTAssertEqualObjects(task.result.urlString, tempPath.absoluteString);
                                    [expectation fulfill];
                                    return nil;
                                }];
    [self waitForTestExpectations];
}

- (void)testUploadCancel {
    id mockedDataSource = PFStrictProtocolMock(@protocol(FileControllerDataSource));
    id mockedCommandRunner = PFStrictProtocolMock(@protocol(PFCommandRunning));
    id mockedFileManager = PFStrictClassMock([PFFileManager class]);

    NSString *temporaryPath = [self temporaryDirectory];
    NSString *downloadsPath = [temporaryPath stringByAppendingPathComponent:@"downloads"];
    NSURL *tempPath = [NSURL fileURLWithPath:[temporaryPath stringByAppendingPathComponent:@"sampleData.dat"]];
    NSData *sampleData = [self sampleData];
    [sampleData writeToURL:tempPath atomically:YES];

    OCMStub([mockedDataSource fileManager]).andReturn(mockedFileManager);
    OCMStub([mockedFileManager parseCacheItemPathForPathComponent:@"PFFileCache"]).andReturn(downloadsPath);
    OCMStub([mockedDataSource commandRunner]).andReturn(mockedCommandRunner);

    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    [OCMStub(([[mockedCommandRunner ignoringNonObjectArgs] runFileUploadCommandAsync:[OCMArg isNotNil]
                                                                     withContentType:@"application/octet-stream"
                                                               contentSourceFilePath:[tempPath path]
                                                                             options:0
                                                                   cancellationToken:cancellationTokenSource.token
                                                                       progressBlock:[OCMArg isNotNil]])) andReturn:[BFTask cancelledTask]];

    PFFileController *fileController = [PFFileController controllerWithDataSource:mockedDataSource];
    PFFileState *fileState = [[PFMutableFileState alloc] initWithName:@"sampleData"
                                                            urlString:nil
                                                             mimeType:@"application/octet-stream"];

    __block int progress = -1;
    XCTestExpectation *expectation = [self currentSelectorTestExpectation];

    [[fileController uploadFileAsyncWithState:fileState
                               sourceFilePath:[tempPath path]
                                 sessionToken:@"session-token"
                            cancellationToken:cancellationTokenSource.token
                                progressBlock:^(int percentDone) {
                                    XCTAssertTrue(progress <= percentDone);
                                    progress = percentDone;
                                }] continueWithBlock:^id(BFTask *task) {
                                    XCTAssertTrue(task.cancelled);
                                    [expectation fulfill];
                                    return nil;
                                }];

    [cancellationTokenSource cancel];
    [self waitForTestExpectations];
}

- (void)testClearFileCache {
    id mockedDataSource = PFStrictProtocolMock(@protocol(PFFileManagerProvider));
    id mockedFileManager = PFStrictClassMock([PFFileManager class]);

    NSString *temporaryPath = [self temporaryDirectory];
    NSString *downloadsPath = [temporaryPath stringByAppendingPathComponent:@"downloads"];

    OCMStub([mockedDataSource fileManager]).andReturn(mockedFileManager);
    OCMStub([mockedFileManager parseLocalSandboxDataDirectoryPath]).andReturn(temporaryPath);
    OCMStub([mockedFileManager parseCacheItemPathForPathComponent:@"PFFileCache"]).andReturn(downloadsPath);

    PFFileController *fileController = [PFFileController controllerWithDataSource:mockedDataSource];
    PFFileState *fileState = [[PFMutableFileState alloc] initWithName:@"sampleData"
                                                            urlString:temporaryPath
                                                             mimeType:@"application/octet-stream"];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[fileController clearFileCacheAsyncForFileWithState:fileState] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        [expectation fulfill];
        return nil;
    }];

    [self waitForTestExpectations];
}

- (void)testClearAllFilesCache {
    id mockedDataSource = PFStrictProtocolMock(@protocol(PFFileManagerProvider));
    id mockedFileManager = PFStrictClassMock([PFFileManager class]);

    NSString *temporaryPath = [self temporaryDirectory];
    NSString *downloadsPath = [temporaryPath stringByAppendingPathComponent:@"downloads"];

    OCMStub([mockedDataSource fileManager]).andReturn(mockedFileManager);
    OCMStub([mockedFileManager parseLocalSandboxDataDirectoryPath]).andReturn(temporaryPath);
    OCMStub([mockedFileManager parseCacheItemPathForPathComponent:@"PFFileCache"]).andReturn(downloadsPath);

    PFFileController *fileController = [PFFileController controllerWithDataSource:mockedDataSource];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[fileController clearAllFileCacheAsync] continueWithBlock:^id(BFTask *task) {
        XCTAssertNil(task.error);
        [expectation fulfill];
        return nil;
    }];

    [self waitForTestExpectations];
}

@end
