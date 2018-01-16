/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFileStagingController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFAsyncTaskQueue.h"
#import "PFDataProvider.h"
#import "PFFileManager.h"
#import "PFLogging.h"

static NSString *const PFFileStagingControllerDirectoryName_ = @"PFFileStaging";

@implementation PFFileStagingController {
    PFAsyncTaskQueue *_taskQueue;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFFileManagerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;
    _taskQueue = [PFAsyncTaskQueue taskQueue];

    [self _clearStagedFilesAsync];

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFFileManagerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Properties
///--------------------------------------

- (NSString *)stagedFilesDirectoryPath {
    return [self.dataSource.fileManager parseCacheItemPathForPathComponent:PFFileStagingControllerDirectoryName_];
}

///--------------------------------------
#pragma mark - Staging
///--------------------------------------

- (BFTask *)stageFileAsyncAtPath:(NSString *)filePath name:(NSString *)name uniqueId:(uint64_t)uniqueId {
    return [_taskQueue enqueue:^id(BFTask *task) {
        return [[PFFileManager createDirectoryIfNeededAsyncAtPath:self.stagedFilesDirectoryPath] continueWithBlock:^id(BFTask *task) {
            NSString *destinationPath = [self stagedFilePathForFileWithName:name uniqueId:uniqueId];
            return [[PFFileManager copyItemAsyncAtPath:filePath toPath:destinationPath] continueWithSuccessResult:destinationPath];
        }];
    }];
}

- (BFTask *)stageFileAsyncWithData:(NSData *)fileData name:(NSString *)name uniqueId:(uint64_t)uniqueId {
    return [_taskQueue enqueue:^id(BFTask *task) {
        return [[PFFileManager createDirectoryIfNeededAsyncAtPath:self.stagedFilesDirectoryPath] continueWithBlock:^id(BFTask *task) {
            NSString *destinationPath = [self stagedFilePathForFileWithName:name uniqueId:uniqueId];
            return [[PFFileManager writeDataAsync:fileData toFile:destinationPath] continueWithSuccessResult:destinationPath];
        }];
    }];
}

- (NSString *)stagedFilePathForFileWithName:(NSString *)name uniqueId:(uint64_t)uniqueId {
    NSString *fileName = [NSString stringWithFormat:@"%llX_%@", uniqueId, name];
    return [self.stagedFilesDirectoryPath stringByAppendingPathComponent:fileName];
}

///--------------------------------------
#pragma mark - Clearing
///--------------------------------------

- (BFTask *)_clearStagedFilesAsync {
    return [_taskQueue enqueue:^id(BFTask *task) {
        NSString *stagedFilesDirectoryPath = self.stagedFilesDirectoryPath;
        return [PFFileManager removeItemAtPathAsync:stagedFilesDirectoryPath withFileLock:NO];
    }];
}

@end
