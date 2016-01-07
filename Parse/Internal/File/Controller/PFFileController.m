/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFileController.h"

#import <Bolts/BFCancellationToken.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFFileDataStream.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFFileManager.h"
#import "PFFileStagingController.h"
#import "PFFileState.h"
#import "PFHash.h"
#import "PFMacros.h"
#import "PFRESTFileCommand.h"
#import "PFErrorUtilities.h"

static NSString *const PFFileControllerCacheDirectoryName_ = @"PFFileCache";

@interface PFFileController () {
    NSMutableDictionary *_downloadTasks; // { "urlString" : BFTask }
    NSMutableDictionary *_downloadProgressBlocks; // { "urlString" : [ block1, block2 ] }
    dispatch_queue_t _downloadDataAccessQueue;
    dispatch_queue_t _fileStagingControllerAccessQueue;
}

@end

@implementation PFFileController

@synthesize fileStagingController = _fileStagingController;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    _downloadTasks = [NSMutableDictionary dictionary];
    _downloadProgressBlocks = [NSMutableDictionary dictionary];
    _downloadDataAccessQueue = dispatch_queue_create("com.parse.fileController.download", DISPATCH_QUEUE_SERIAL);
    _fileStagingControllerAccessQueue = dispatch_queue_create("com.parse.filestaging.controller.access", DISPATCH_QUEUE_SERIAL);

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Properties
///--------------------------------------

- (PFFileStagingController *)fileStagingController {
    __block PFFileStagingController *result = nil;
    dispatch_sync(_fileStagingControllerAccessQueue, ^{
        if (!_fileStagingController) {
            _fileStagingController = [PFFileStagingController controllerWithDataSource:self.dataSource];
        }
        result = _fileStagingController;
    });
    return result;
}

///--------------------------------------
#pragma mark - Download
///--------------------------------------

- (BFTask<PFVoid> *)downloadFileAsyncWithState:(PFFileState *)fileState
                             cancellationToken:(BFCancellationToken *)cancellationToken
                                 progressBlock:(PFProgressBlock)progressBlock {
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }
    if (!fileState.secureURLString) {
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorUnsavedFile
                                                 message:@"Can't download a file that doesn't exist on the server or locally."];
        return [BFTask taskWithError:error];
    }

    @weakify(self);
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        [self _addFileDownloadProgressBlock:progressBlock forFileWithState:fileState];

        BFTask *resultTask = [self _fileDownloadResultTaskForFileWithState:fileState];
        if (!resultTask) {
            NSURL *url = [NSURL URLWithString:fileState.secureURLString];
            NSString *temporaryPath = [self _temporaryFileDownloadPathForFileState:fileState];

            PFProgressBlock unifyingProgressBlock = [self _fileDownloadUnifyingProgressBlockForFileState:fileState];
            resultTask = [self.dataSource.commandRunner runFileDownloadCommandAsyncWithFileURL:url
                                                                                targetFilePath:temporaryPath
                                                                             cancellationToken:cancellationToken
                                                                                 progressBlock:unifyingProgressBlock];
            resultTask = [[resultTask continueWithSuccessBlock:^id(BFTask *task) {
                return [[self _cacheFileAsyncWithState:fileState atPath:temporaryPath] continueWithBlock:^id(BFTask *task) {
                    // Ignore the error if file exists.
                    if (task.error && task.error.code == NSFileWriteFileExistsError) {
                        return nil;
                    }
                    return task;
                }];
            }] continueWithBlock:^id(BFTask *task) {
                dispatch_barrier_async(_downloadDataAccessQueue, ^{
                    [_downloadTasks removeObjectForKey:fileState.secureURLString];
                    [_downloadProgressBlocks removeObjectForKey:fileState.secureURLString];
                });
                return task;
            }];
            dispatch_barrier_async(_downloadDataAccessQueue, ^{
                _downloadTasks[fileState.secureURLString] = resultTask;
            });
        }
        return resultTask;
    }];
}

- (BFTask<PFFileDataStream *> *)downloadFileStreamAsyncWithState:(PFFileState *)fileState
                                               cancellationToken:(BFCancellationToken *)cancellationToken
                                                   progressBlock:(PFProgressBlock)progressBlock {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        BFTaskCompletionSource<PFFileDataStream *> *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
        NSString *filePath = [self _temporaryFileDownloadPathForFileState:fileState];
        PFFileDataStream *stream = [[PFFileDataStream alloc] initWithFileAtPath:filePath];
        [[self downloadFileAsyncWithState:fileState
                        cancellationToken:cancellationToken
                            progressBlock:^(int percentDone) {
                                [taskCompletionSource trySetResult:stream];

                                if (progressBlock) {
                                    progressBlock(percentDone);
                                }
                            }] continueWithBlock:^id(BFTask *task) {
                                [stream stopBlocking];
                                return task;
                            }];
        return taskCompletionSource.task;
    }];
}

- (BFTask *)_fileDownloadResultTaskForFileWithState:(PFFileState *)state {
    __block BFTask *resultTask = nil;
    dispatch_sync(_downloadDataAccessQueue, ^{
        resultTask = _downloadTasks[state.secureURLString];
    });
    return resultTask;
}

- (PFProgressBlock)_fileDownloadUnifyingProgressBlockForFileState:(PFFileState *)fileState {
    return ^(int progress) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __block NSArray *blocks = nil;
            dispatch_sync(_downloadDataAccessQueue, ^{
                blocks = [_downloadProgressBlocks[fileState.secureURLString] copy];
            });
            if (blocks.count != 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (PFProgressBlock block in blocks) {
                        block(progress);
                    }
                });
            }
        });
    };
}

- (void)_addFileDownloadProgressBlock:(PFProgressBlock)block forFileWithState:(PFFileState *)state {
    if (!block) {
        return;
    }

    dispatch_barrier_async(_downloadDataAccessQueue, ^{
        NSMutableArray *progressBlocks = _downloadProgressBlocks[state.secureURLString];
        if (!progressBlocks) {
            progressBlocks = [NSMutableArray arrayWithObject:block];
            _downloadProgressBlocks[state.secureURLString] = progressBlocks;
        } else {
            [progressBlocks addObject:block];
        }
    });
}

- (NSString *)_temporaryFileDownloadPathForFileState:(PFFileState *)fileState {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:PFMD5HashFromString(fileState.secureURLString)];
}

///--------------------------------------
#pragma mark - Upload
///--------------------------------------

- (BFTask<PFFileState *> *)uploadFileAsyncWithState:(PFFileState *)fileState
                                     sourceFilePath:(NSString *)sourceFilePath
                                       sessionToken:(NSString *)sessionToken
                                  cancellationToken:(BFCancellationToken *)cancellationToken
                                      progressBlock:(PFProgressBlock)progressBlock {
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }
    if (!sourceFilePath) {
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorUnsavedFile
                                                 message:@"Can't upload a file that doesn't exist locally."];
        return [BFTask taskWithError:error];
    }

    PFRESTFileCommand *command = [PFRESTFileCommand uploadCommandForFileWithName:fileState.name sessionToken:sessionToken];
    @weakify(self);
    return [[self.dataSource.commandRunner runFileUploadCommandAsync:command
                                                     withContentType:fileState.mimeType
                                               contentSourceFilePath:sourceFilePath
                                                             options:PFCommandRunningOptionRetryIfFailed
                                                   cancellationToken:cancellationToken
                                                       progressBlock:progressBlock] continueWithSuccessBlock:^id(BFTask<PFCommandResult *> *task) {
        @strongify(self);
        PFCommandResult *result = task.result;
        PFFileState *fileState = [[PFFileState alloc] initWithName:result.result[@"name"]
                                                         urlString:result.result[@"url"]
                                                          mimeType:nil];
        return [[self _cacheFileAsyncWithState:fileState atPath:sourceFilePath] continueWithSuccessResult:fileState];
    }];
}

///--------------------------------------
#pragma mark - Cache
///--------------------------------------

- (BFTask<PFVoid> *)_cacheFileAsyncWithState:(PFFileState *)state atPath:(NSString *)path {
    return [[PFFileManager createDirectoryIfNeededAsyncAtPath:self.cacheFilesDirectoryPath] continueWithSuccessBlock:^id(BFTask *_) {
        return [PFFileManager moveItemAsyncAtPath:path toPath:[self cachedFilePathForFileState:state]];
    }];
}

- (NSString *)cachedFilePathForFileState:(PFFileState *)fileState {
    if (!fileState.secureURLString) {
        return nil;
    }

    NSString *filename = fileState.secureURLString.lastPathComponent;
    NSString *path = [self.cacheFilesDirectoryPath stringByAppendingPathComponent:filename];
    return path;
}

- (NSString *)cacheFilesDirectoryPath {
    return [self.dataSource.fileManager parseCacheItemPathForPathComponent:PFFileControllerCacheDirectoryName_];
}

- (BFTask<PFVoid> *)clearFileCacheAsync {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        NSString *path = self.cacheFilesDirectoryPath;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return [PFFileManager removeDirectoryContentsAsyncAtPath:path];
        }
        return nil;
    }];
}

@end
