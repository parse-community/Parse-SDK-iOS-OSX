/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <OCMock/OCMock.h>

@import Bolts.BFTask;

#import "PFCoreManager.h"
#import "PFFileController.h"
#import "PFFileStagingController.h"
#import "PFFileState.h"
#import "PFFile_Private.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

static NSData *dataFromInputStream(NSInputStream *inputStream) {
    NSMutableData *results = [[NSMutableData alloc] init];

    [inputStream open];

    while (inputStream.streamError == nil && inputStream.hasBytesAvailable) {
        uint8_t buffer[1024];
        size_t bytesRead = [inputStream read:buffer maxLength:1024];

        if (bytesRead == -1) {
            break;
        }

        [results appendBytes:buffer length:bytesRead];
    }

    [inputStream close];

    return results;
}

@interface FileUnitTestsInvocationVerifier : NSObject

@end

@implementation FileUnitTestsInvocationVerifier

- (void)verifyObject:(id)object error:(NSError *)error {

}

@end

@interface FileUnitTests : PFUnitTestCase

@end

@implementation FileUnitTests

///--------------------------------------
#pragma mark - Helpers
///--------------------------------------

- (NSString *)sampleFilePath {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"sampleData.dat"];
    [[self sampleData] writeToFile:path atomically:YES];

    return path;
}

- (NSString *)sampleStagingPath {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:@"staged-files"];
}

- (NSData *)sampleData {
    const uint8_t bytes[] = {
        [0 ... 255] = 0x7F
    };

    return [NSData dataWithBytes:bytes length:sizeof(bytes)];
}

- (void)clearStagingAndTemporaryFiles {
    [[NSFileManager defaultManager] removeItemAtPath:[self sampleFilePath] error:NULL];
    [[NSFileManager defaultManager] removeItemAtPath:[self sampleStagingPath] error:NULL];
    [[NSFileManager defaultManager] createDirectoryAtPath:[self sampleStagingPath]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:NULL];
}

- (PFFileController *)mockedFileController {
    id mockedFileController = PFStrictClassMock([PFFileController class]);
    id mockedFileStagingController = PFStrictClassMock([PFFileStagingController class]);

    NSString *stagedDirectory = [self sampleStagingPath];
    NSString *sampleFile = [stagedDirectory stringByAppendingPathComponent:@"stagedFile.dat"];
    [self clearStagingAndTemporaryFiles];

    OCMStub([mockedFileController fileStagingController]).andReturn(mockedFileStagingController);
    OCMStub([[mockedFileStagingController ignoringNonObjectArgs] stageFileAsyncWithData:OCMOCK_ANY
                                                                                   name:OCMOCK_ANY
                                                                               uniqueId:0]).andReturn([BFTask taskWithResult:sampleFile]);
    OCMStub([[mockedFileStagingController ignoringNonObjectArgs] stageFileAsyncAtPath:OCMOCK_ANY
                                                                                 name:OCMOCK_ANY
                                                                             uniqueId:0]).andReturn([BFTask taskWithResult:sampleFile]);

    return mockedFileController;
}

- (PFProgressBlock)progressValidationBlock {
    __block int currentProgress = 0;
    return [^(int progress) {
        XCTAssertLessThanOrEqual(currentProgress, progress);
        currentProgress = progress;
    } copy];
}

- (XCTestExpectation *)expectationForSelector:(SEL)cmd {
    return [self expectationWithDescription:NSStringFromSelector(cmd)];
}

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp {
    [super setUp];

    [Parse _currentManager].coreManager.fileController = [self mockedFileController];
}

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testContructors {
    [self clearStagingAndTemporaryFiles];
    PFFile *file = [PFFile fileWithData:[NSData data]];
    XCTAssertEqualObjects(file.name, @"file");
    XCTAssertNil(file.url);
    XCTAssertTrue(file.dirty);
    XCTAssertTrue(file.dataAvailable);

    [self clearStagingAndTemporaryFiles];
    file = [PFFile fileWithData:[NSData data] contentType:@"content-type"];
    XCTAssertEqualObjects(file.name, @"file");
    XCTAssertNil(file.url);
    XCTAssertTrue(file.dirty);
    XCTAssertTrue(file.dataAvailable);

    [self clearStagingAndTemporaryFiles];
    file = [PFFile fileWithName:@"name" data:[NSData data]];
    XCTAssertEqualObjects(file.name, @"name");
    XCTAssertNil(file.url);
    XCTAssertTrue(file.dirty);
    XCTAssertTrue(file.dataAvailable);

    [self clearStagingAndTemporaryFiles];
    file = [PFFile fileWithName:nil contentsAtPath:[self sampleFilePath]];
    XCTAssertEqualObjects(file.name, @"file");
    XCTAssertNil(file.url);
    XCTAssertTrue(file.dirty);
    XCTAssertTrue(file.dataAvailable);

    [self clearStagingAndTemporaryFiles];
    NSError *error = nil;
    file = [PFFile fileWithName:nil contentsAtPath:[self sampleFilePath] error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(file.name, @"file");
    XCTAssertNil(file.url);
    XCTAssertTrue(file.dirty);
    XCTAssertTrue(file.dataAvailable);

    [self clearStagingAndTemporaryFiles];
    file = [PFFile fileWithName:nil data:[NSData data] contentType:@"content-type"];
    XCTAssertEqualObjects(file.name, @"file");
    XCTAssertNil(file.url);
    XCTAssertTrue(file.dirty);
    XCTAssertTrue(file.dataAvailable);

    [self clearStagingAndTemporaryFiles];
    file = [PFFile fileWithName:nil data:[NSData data] contentType:@"content-type" error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(file.name, @"file");
    XCTAssertNil(file.url);
    XCTAssertTrue(file.dirty);
    XCTAssertTrue(file.dataAvailable);
}

- (void)testConstructorWithNilData {
    NSMutableData *data = nil;

    NSError *error = nil;
    PFFile *file = [PFFile fileWithName:@"testFile"
                                   data:data
                            contentType:nil
                                  error:&error];

    XCTAssertNil(file);
    XCTAssertEqualObjects(NSCocoaErrorDomain, error.domain);
    XCTAssertEqual(NSFileNoSuchFileError, error.code);
}

- (void)testUploading {
    id mockedFileController = [Parse _currentManager].coreManager.fileController;
    PFFileState *expectedState = [[PFFileState alloc] initWithName:@"file"
                                                         urlString:nil
                                                          mimeType:@"application/octet-stream"];

    OCMStub([mockedFileController uploadFileAsyncWithState:expectedState
                                            sourceFilePath:[OCMArg isNotNil]
                                              sessionToken:nil
                                         cancellationToken:[OCMArg isNotNil]
                                             progressBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained PFFileState *state = nil;
        __unsafe_unretained PFProgressBlock progressBlock = nil;

        [invocation getArgument:&state atIndex:2];
        [invocation getArgument:&progressBlock atIndex:6];

        if (progressBlock) {
            progressBlock(100);
        }

        __autoreleasing BFTask *resultTask = [BFTask taskWithResult:state];
        [invocation setReturnValue:&resultTask];
    });

    NSError *error = nil;
    XCTestExpectation *expectation = nil;

    PFFile *file = [PFFile fileWithData:[self sampleData] contentType:@"application/octet-stream"];

    XCTAssertTrue([file save]);
    XCTAssertTrue([file save:&error]);
    XCTAssertNil(error);

    expectation = [self expectationForSelector:@selector(saveInBackground)];
    [[file saveInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.completed);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    expectation = [self expectationForSelector:@selector(saveInBackgroundWithProgressBlock:)];
    [[file saveInBackgroundWithProgressBlock:[self progressValidationBlock]] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.completed);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    expectation = [self expectationForSelector:@selector(saveInBackgroundWithBlock:)];
    [file saveInBackgroundWithBlock:^(BOOL success, NSError *error){
        XCTAssertTrue(success);
        [expectation fulfill];
    }];
    [self waitForTestExpectations];

    expectation = [self expectationForSelector:@selector(saveInBackgroundWithBlock:progressBlock:)];
    [file saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
        XCTAssertTrue(success);
        [expectation fulfill];
    } progressBlock:[self progressValidationBlock]];
    [self waitForTestExpectations];

    expectation = [self expectationForSelector:@selector(saveInBackgroundWithTarget:selector:)];
    id verifier = PFStrictClassMock([FileUnitTestsInvocationVerifier class]);
    OCMStub([verifier verifyObject:@YES error:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [file saveInBackgroundWithTarget:verifier selector:@selector(verifyObject:error:)];
#pragma clang diagnostic pop

    [self waitForTestExpectations];
}

- (void)testDownloading{
    id mockedFileController = [Parse _currentManager].coreManager.fileController;
    PFFileState *expectedState = [[PFFileState alloc] initWithName:@"file"
                                                         urlString:@"http://some.place"
                                                          mimeType:nil];

    NSString *cachedPath = [self sampleFilePath];

    OCMStub([mockedFileController cachedFilePathForFileState:expectedState]).andReturn(cachedPath);
    OCMStub([mockedFileController downloadFileAsyncWithState:expectedState
                                           cancellationToken:OCMOCK_ANY
                                               progressBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained PFProgressBlock progressBlock = nil;
        [invocation getArgument:&progressBlock atIndex:4];
        if (progressBlock) {
            progressBlock(100);
        }

        [[self sampleData] writeToFile:cachedPath atomically:YES];
        __autoreleasing BFTask *results = [BFTask taskWithResult:nil];
        [invocation setReturnValue:&results];
    });

    OCMStub([mockedFileController downloadFileStreamAsyncWithState:expectedState
                                                 cancellationToken:OCMOCK_ANY
                                                     progressBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained PFProgressBlock progressBlock = nil;
        [invocation getArgument:&progressBlock atIndex:4];
        if (progressBlock) {
            progressBlock(100);
        }

        [[self sampleData] writeToFile:cachedPath atomically:YES];
        __autoreleasing BFTask *results = [BFTask taskWithResult:[NSInputStream inputStreamWithFileAtPath:cachedPath]];
        [invocation setReturnValue:&results];
    });

#define wait_next [self waitForTestExpectations]; \
                  [[NSFileManager defaultManager] removeItemAtPath:cachedPath error:NULL]

    NSError *error = nil;
    XCTestExpectation *expectation = nil;

    NSData *expectedData = [self sampleData];
    PFFile *file = [PFFile fileWithName:@"file" url:@"http://some.place"];

    XCTAssertEqualObjects([file getData], expectedData);

    [[NSFileManager defaultManager] removeItemAtPath:cachedPath error:NULL];
    XCTAssertEqualObjects([file getData:&error], expectedData);
    XCTAssertNil(error);

    [[NSFileManager defaultManager] removeItemAtPath:cachedPath error:NULL];
    XCTAssertEqualObjects(dataFromInputStream([file getDataStream]), expectedData);

    [[NSFileManager defaultManager] removeItemAtPath:cachedPath error:NULL];
    XCTAssertEqualObjects(dataFromInputStream([file getDataStream:&error]), expectedData);
    XCTAssertNil(error);

    [[NSFileManager defaultManager] removeItemAtPath:cachedPath error:NULL];
    expectation = [self expectationForSelector:@selector(getDataInBackground)];
    [[file getDataInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, expectedData);
        [expectation fulfill];
        return nil;
    }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataInBackgroundWithProgressBlock:)];
    [[file getDataInBackgroundWithProgressBlock:[self progressValidationBlock]] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(task.result, expectedData);
        [expectation fulfill];
        return nil;
    }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataInBackgroundWithBlock:)];
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        XCTAssertEqualObjects(data, expectedData);
        [expectation fulfill];
    }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataInBackgroundWithBlock:progressBlock:)];
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        XCTAssertEqualObjects(data, expectedData);
        [expectation fulfill];
    } progressBlock:[self progressValidationBlock]];

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataStreamInBackground)];
    [[file getDataStreamInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(dataFromInputStream(task.result), expectedData);
        [expectation fulfill];
        return nil;
    }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataStreamInBackgroundWithBlock:)];
    [file getDataStreamInBackgroundWithBlock:^(NSInputStream *inputStream, NSError *error) {
        XCTAssertEqualObjects(dataFromInputStream(inputStream), expectedData);
        [expectation fulfill];
    }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataStreamInBackgroundWithProgressBlock:)];
    [[file getDataStreamInBackgroundWithProgressBlock:[self progressValidationBlock]]
        continueWithBlock:^id(BFTask *task) {
            XCTAssertEqualObjects(dataFromInputStream(task.result), expectedData);
            [expectation fulfill];
            return nil;
        }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataStreamInBackgroundWithBlock:progressBlock:)];
    [file getDataStreamInBackgroundWithBlock:^(NSInputStream *inputStream, NSError *error) {
        XCTAssertEqualObjects(dataFromInputStream(inputStream), expectedData);
        [expectation fulfill];
    } progressBlock:[self progressValidationBlock]];

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataInBackgroundWithTarget:selector:)];
    id verifier = PFStrictClassMock([FileUnitTestsInvocationVerifier class]);
    OCMStub([verifier verifyObject:expectedData error:nil]).andDo(^(NSInvocation *invocation) {
        [expectation fulfill];
    });

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [file getDataInBackgroundWithTarget:verifier selector:@selector(verifyObject:error:)];
#pragma clang diagnostic pop

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataDownloadStreamInBackground)];
    [[file getDataDownloadStreamInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertEqualObjects(dataFromInputStream(task.result), expectedData);
        [expectation fulfill];
        return nil;
    }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getDataDownloadStreamInBackgroundWithProgressBlock:)];
    [[file getDataDownloadStreamInBackgroundWithProgressBlock:[self progressValidationBlock]]
        continueWithBlock:^id(BFTask *task) {
            XCTAssertEqualObjects(dataFromInputStream(task.result), expectedData);
            [expectation fulfill];
            return nil;
        }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getFilePathInBackground)];
    [[file getFilePathInBackground] continueWithBlock:^id(BFTask *task) {
        NSData *data = [NSData dataWithContentsOfFile:task.result];
        XCTAssertEqualObjects(data, expectedData);
        [expectation fulfill];
        return nil;
    }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getFilePathInBackgroundWithProgressBlock:)];
    [[file getFilePathInBackgroundWithProgressBlock:[self progressValidationBlock]] continueWithBlock:^id(BFTask *task) {
        NSData *data = [NSData dataWithContentsOfFile:task.result];
        XCTAssertEqualObjects(data, expectedData);
        [expectation fulfill];
        return nil;
    }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getFilePathInBackgroundWithBlock:)];
    [file getFilePathInBackgroundWithBlock:^(NSString *filePath, NSError *error) {
        XCTAssertNil(error);
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        XCTAssertEqualObjects(data, expectedData);
        [expectation fulfill];
    }];

    wait_next;
    expectation = [self expectationForSelector:@selector(getFilePathInBackgroundWithBlock:progressBlock:)];
    [file getFilePathInBackgroundWithBlock:^(NSString *filePath, NSError *error) {
        XCTAssertNil(error);
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        XCTAssertEqualObjects(data, expectedData);
        [expectation fulfill];
    } progressBlock:[self progressValidationBlock]];

    wait_next;
}

- (void)testCancel {
    id mockedFileController = [Parse _currentManager].coreManager.fileController;
    PFFileState *expectedState = [[PFFileState alloc] initWithName:@"file"
                                                         urlString:@"http://some.place"
                                                          mimeType:nil];

    NSString *cachedPath = [self sampleFilePath];

    OCMStub([mockedFileController cachedFilePathForFileState:expectedState]).andReturn(cachedPath);
    OCMStub([mockedFileController downloadFileAsyncWithState:expectedState
                                           cancellationToken:OCMOCK_ANY
                                               progressBlock:OCMOCK_ANY])._andDo(^(NSInvocation *invocation) {
        __unsafe_unretained PFProgressBlock progressBlock = nil;
        [invocation getArgument:&progressBlock atIndex:4];
        if (progressBlock) {
            progressBlock(100);
        }

        [[self sampleData] writeToFile:cachedPath atomically:YES];
        __autoreleasing BFTask *results = [BFTask cancelledTask];
        [invocation setReturnValue:&results];
    });

    XCTestExpectation *expectation = nil;
    PFFile *file = [PFFile fileWithName:@"file" url:@"http://some.place"];

    [[NSFileManager defaultManager] removeItemAtPath:cachedPath error:NULL];
    expectation = [self currentSelectorTestExpectation];
    [[file getDataInBackground] continueWithBlock:^id(BFTask *task) {
        XCTAssertTrue(task.cancelled);
        [expectation fulfill];

        return nil;
    }];

    [file cancel];
    [self waitForTestExpectations];
}

- (void)testClearCachedData {
    id mockedFileController = [Parse _currentManager].coreManager.fileController;

    PFFile *file = [PFFile fileWithName:@"a" data:[NSData data]];
    OCMExpect([mockedFileController clearFileCacheAsyncForFileWithState:file.state]).andReturn([BFTask taskWithResult:nil]);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[file clearCachedDataInBackground] continueWithBlock:^id _Nullable(BFTask * _Nonnull task) {
        XCTAssertNil(task.result);
        XCTAssertFalse(task.faulted);
        XCTAssertFalse(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedFileController);
}

- (void)testClearAllCachedData {
    id mockedFileController = [Parse _currentManager].coreManager.fileController;
    OCMExpect([mockedFileController clearAllFileCacheAsync]).andReturn([BFTask taskWithResult:nil]);

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [[PFFile clearAllCachedDataInBackground] continueWithBlock:^id _Nullable(BFTask * _Nonnull task) {
        XCTAssertNil(task.result);
        XCTAssertFalse(task.faulted);
        XCTAssertFalse(task.cancelled);
        [expectation fulfill];
        return nil;
    }];
    [self waitForTestExpectations];

    OCMVerifyAll(mockedFileController);
}

@end
