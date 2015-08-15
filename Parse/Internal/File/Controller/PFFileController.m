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
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFFileManager.h"
#import "PFFileState.h"
#import "PFHash.h"
#import "PFMacros.h"
#import "PFRESTFileCommand.h"

static NSString *const PFFileControllerCacheDirectoryName_ = @"PFFileCache";
static NSString *const PFFileControllerStagingDirectoryName_ = @"PFFileStaging";

@interface PFFileController () {
    NSMutableDictionary *_downloadTasks; // { "urlString" : BFTask }
    NSMutableDictionary *_downloadProgressBlocks; // { "urlString" : [ block1, block2 ] }
    dispatch_queue_t _downloadDataAccessQueue;
}

@end

@implementation PFFileController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    _downloadTasks = [NSMutableDictionary dictionary];
    _downloadProgressBlocks = [NSMutableDictionary dictionary];
    _downloadDataAccessQueue = dispatch_queue_create("com.parse.fileController.download", DISPATCH_QUEUE_SERIAL);

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Download
///--------------------------------------

- (BFTask *)downloadFileAsyncWithState:(PFFileState *)fileState
                     cancellationToken:(BFCancellationToken *)cancellationToken
                         progressBlock:(PFProgressBlock)progressBlock {
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }

    @weakify(self);
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        [self _addFileDownloadProgressBlock:progressBlock forFileWithState:fileState];

        BFTask *resultTask = [self _fileDownloadResultTaskForFileWithState:fileState];
        if (!resultTask) {
            NSURL *url = [NSURL URLWithString:fileState.urlString];
            NSString *temporaryPath = [self _temporaryFileDownloadPathForFileState:fileState];

            PFProgressBlock unifyingProgressBlock = [self _fileDownloadUnifyingProgressBlockForFileState:fileState];
            resultTask = [self.dataSource.commandRunner runFileDownloadCommandAsyncWithFileURL:url
                                                                                targetFilePath:temporaryPath
                                                                             cancellationToken:cancellationToken
                                                                                 progressBlock:unifyingProgressBlock];
            resultTask = [[resultTask continueWithSuccessBlock:^id(BFTask *task) {
                // TODO: (nlutsenko) Create `+ moveAsync` in PFFileManager
                NSError *fileError = nil;
                [[NSFileManager defaultManager] moveItemAtPath:temporaryPath
                                                        toPath:[self cachedFilePathForFileState:fileState]
                                                         error:&fileError];
                if (fileError && fileError.code != NSFileWriteFileExistsError) {
                    return fileError;
                }
                return nil;
            }] continueWithBlock:^id(BFTask *task) {
                dispatch_barrier_async(_downloadDataAccessQueue, ^{
                    [_downloadTasks removeObjectForKey:fileState.urlString];
                    [_downloadProgressBlocks removeObjectForKey:fileState.urlString];
                });
                return task;
            }];
            dispatch_barrier_async(_downloadDataAccessQueue, ^{
                _downloadTasks[fileState.urlString] = resultTask;
            });
        }
        return resultTask;
    }];
}

- (BFTask *)downloadFileStreamAsyncWithState:(PFFileState *)fileState
                           cancellationToken:(BFCancellationToken *)cancellationToken
                               progressBlock:(PFProgressBlock)progressBlock {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
        NSString *filePath = [self _temporaryFileDownloadPathForFileState:fileState];
        NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:filePath];
        [self downloadFileAsyncWithState:fileState
                       cancellationToken:cancellationToken
                           progressBlock:^(int percentDone) {
                               [taskCompletionSource trySetResult:stream];

                               if (progressBlock) {
                                   progressBlock(percentDone);
                               }
                           }];
        return taskCompletionSource.task;
    }];
}

- (BFTask *)_fileDownloadResultTaskForFileWithState:(PFFileState *)state {
    __block BFTask *resultTask = nil;
    dispatch_sync(_downloadDataAccessQueue, ^{
        resultTask = _downloadTasks[state.urlString];
    });
    return resultTask;
}

- (PFProgressBlock)_fileDownloadUnifyingProgressBlockForFileState:(PFFileState *)fileState {
    return ^(int progress) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __block NSArray *blocks = nil;
            dispatch_sync(_downloadDataAccessQueue, ^{
                blocks = [_downloadProgressBlocks[fileState.urlString] copy];
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
        NSMutableArray *progressBlocks = _downloadProgressBlocks[state.urlString];
        if (!progressBlocks) {
            progressBlocks = [NSMutableArray arrayWithObject:block];
            _downloadProgressBlocks[state.urlString] = progressBlocks;
        } else {
            [progressBlocks addObject:block];
        }
    });
}

- (NSString *)_temporaryFileDownloadPathForFileState:(PFFileState *)fileState {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:PFMD5HashFromString(fileState.urlString)];
}

///--------------------------------------
#pragma mark - Upload
///--------------------------------------

- (BFTask *)uploadFileAsyncWithState:(PFFileState *)fileState
                      sourceFilePath:(NSString *)sourceFilePath
                        sessionToken:(NSString *)sessionToken
                   cancellationToken:(BFCancellationToken *)cancellationToken
                       progressBlock:(PFProgressBlock)progressBlock {
    PFRESTFileCommand *command = [PFRESTFileCommand uploadCommandForFileWithName:fileState.name
                                                                    sessionToken:sessionToken];

    @weakify(self);
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }
    return [[[self.dataSource.commandRunner runFileUploadCommandAsync:command
                                                      withContentType:fileState.mimeType
                                                contentSourceFilePath:sourceFilePath
                                                              options:PFCommandRunningOptionRetryIfFailed
                                                    cancellationToken:cancellationToken
                                                        progressBlock:progressBlock] continueWithSuccessBlock:^id(BFTask *task) {
        PFCommandResult *result = task.result;
        PFFileState *fileState = [[PFFileState alloc] initWithName:result.result[@"name"]
                                                         urlString:result.result[@"url"]
                                                          mimeType:nil];
        return fileState;
    }] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);

        NSString *finalPath = [self cachedFilePathForFileState:task.result];
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:sourceFilePath
                                                toPath:finalPath
                                                 error:&error];
        if (error) {
            return [BFTask taskWithError:error];
        }
        return task;
    }];
}

///--------------------------------------
#pragma mark - Cache
///--------------------------------------

- (NSString *)cachedFilePathForFileState:(PFFileState *)fileState {
    if (!fileState.urlString) {
        return nil;
    }

    NSString *filename = [fileState.urlString lastPathComponent];
    NSString *path = [self.cacheFilesDirectoryPath stringByAppendingPathComponent:filename];
    return path;
}

- (NSString *)cacheFilesDirectoryPath {
    NSString *path = [self.dataSource.fileManager parseCacheItemPathForPathComponent:PFFileControllerCacheDirectoryName_];
    [[PFFileManager createDirectoryIfNeededAsyncAtPath:path] waitForResult:nil withMainThreadWarning:NO];
    return path;
}

- (BFTask *)clearFileCacheAsync {
    NSString *path = [self cacheFilesDirectoryPath];
    return [PFFileManager removeDirectoryContentsAsyncAtPath:path];
}

///--------------------------------------
#pragma mark - Staging
///--------------------------------------

- (NSString *)stagedFilesDirectoryPath {
    NSString *folderPath = [self.dataSource.fileManager parseLocalSandboxDataDirectoryPath];
    NSString *path = [folderPath stringByAppendingPathComponent:PFFileControllerStagingDirectoryName_];
    [[PFFileManager createDirectoryIfNeededAsyncAtPath:path] waitForResult:nil withMainThreadWarning:NO];
    return path;
}

@end
