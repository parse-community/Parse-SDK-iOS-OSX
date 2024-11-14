/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFileObject.h"
#import "PFFileObject_Private.h"

#if __has_include(<Bolts/BFCancellationTokenSource.h>)
#import <Bolts/BFCancellationTokenSource.h>
#else
#import "BFCancellationTokenSource.h"
#endif

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFAsyncTaskQueue.h"
#import "PFCommandResult.h"
#import "PFCoreManager.h"
#import "PFErrorUtilities.h"
#import "PFFileController.h"
#import "PFFileManager.h"
#import "PFFileStagingController.h"
#import "PFInternalUtils.h"
#import "PFMacros.h"
#import "PFMutableFileState.h"
#import "PFRESTFileCommand.h"
#import "PFThreadsafety.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

@interface PFFileObject () {
    dispatch_queue_t _synchronizationQueue;
}

@property (nonatomic, strong, readwrite) PFFileState *state;
@property (nonatomic, copy, readonly) NSString *stagedFilePath;

//
// Private
@property (nonatomic, strong) PFAsyncTaskQueue *taskQueue;
@property (nonatomic, strong) BFCancellationTokenSource *cancellationTokenSource;

@end

@implementation PFFileObject

@synthesize stagedFilePath = _stagedFilePath;

///--------------------------------------
#pragma mark - Public
///--------------------------------------

#pragma mark Init

+ (instancetype)fileObjectWithData:(NSData *)data {
    return [self fileObjectWithName:nil data:data contentType:nil];
}

+ (instancetype)fileObjectWithName:(NSString *)name data:(NSData *)data {
    return [self fileObjectWithName:name data:data contentType:nil];
}

+ (instancetype)fileObjectWithName:(NSString *)name contentsAtPath:(NSString *)path {
    NSError *error = nil;
    PFFileObject *file = [self fileObjectWithName:name contentsAtPath:path error:&error];
    PFParameterAssert(!error, @"Could not access file at %@: %@", path, error);
    return file;
}

+ (instancetype)fileObjectWithName:(NSString *)name contentsAtPath:(NSString *)path error:(NSError **)error {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL directory = NO;

    if (![fileManager fileExistsAtPath:path isDirectory:&directory] || directory) {
        NSString *message = [NSString stringWithFormat:@"Failed to create PFFileObject at path '%@': file does not exist.", path];
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSFileNoSuchFileError
                                     userInfo:@{ NSLocalizedDescriptionKey : message }];
        }
        return nil;
    }

    PFFileObject *file = [self fileObjectWithName:name url:nil];
    if (![file _stageWithPath:path error:error]) {
        return nil;
    }
    return file;
}

+ (instancetype)fileObjectWithName:(NSString *)name
                        data:(NSData *)data
                 contentType:(NSString *)contentType {
    NSError *error = nil;
    PFFileObject *file = [self fileObjectWithName:name data:data contentType:contentType error:&error];
    PFConsistencyAssert(!error, @"Could not save file data for %@ : %@", name, error);
    return file;
}

+ (instancetype)fileObjectWithName:(NSString *)name
                        data:(NSData *)data
                 contentType:(NSString *)contentType
                       error:(NSError **)error {
    if (!data) {
        NSString *message = @"Cannot create a PFFileObject with nil data.";
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSFileNoSuchFileError
                                     userInfo:@{ NSLocalizedDescriptionKey : message }];
        }
        return nil;
    }

    PFFileObject *file = [[self alloc] initWithName:name urlString:nil mimeType:contentType];
    if (![file _stageWithData:data error:error]) {
        return nil;
    }
    return file;
}

+ (instancetype)fileObjectWithData:(NSData *)data contentType:(NSString *)contentType {
    return [self fileObjectWithName:nil data:data contentType:contentType];
}

#pragma mark Uploading

- (BFTask *)saveInBackground {
    return [self _uploadAsyncWithProgressBlock:nil];
}

- (BFTask *)saveInBackgroundWithProgressBlock:(PFProgressBlock)progressBlock {
    return [self _uploadAsyncWithProgressBlock:progressBlock];
}

- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [[self saveInBackground] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block
                    progressBlock:(PFProgressBlock)progressBlock {
    [[self _uploadAsyncWithProgressBlock:progressBlock] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

#pragma mark Downloading

- (BFTask *)getDataInBackground {
    return [self _getDataAsyncWithProgressBlock:nil];
}

- (BFTask *)getDataInBackgroundWithProgressBlock:(PFProgressBlock)progressBlock {
    return [self _getDataAsyncWithProgressBlock:progressBlock];
}

- (BFTask *)getDataStreamInBackground {
    return [self _getDataStreamAsyncWithProgressBlock:nil];
}

- (BFTask *)getDataStreamInBackgroundWithProgressBlock:(PFProgressBlock)progressBlock {
    return [self _getDataStreamAsyncWithProgressBlock:progressBlock];
}

- (BFTask *)getDataDownloadStreamInBackground {
    return [self getDataDownloadStreamInBackgroundWithProgressBlock:nil];
}

- (BFTask *)getDataDownloadStreamInBackgroundWithProgressBlock:(PFProgressBlock)progressBlock {
    return [self _downloadStreamAsyncWithProgressBlock:progressBlock];
}

- (void)getDataInBackgroundWithBlock:(PFDataResultBlock)block {
    [self getDataInBackgroundWithBlock:block progressBlock:nil];
}

- (void)getDataStreamInBackgroundWithBlock:(PFDataStreamResultBlock)block {
    [self getDataStreamInBackgroundWithBlock:block progressBlock:nil];
}

- (void)getDataInBackgroundWithBlock:(PFDataResultBlock)resultBlock
                       progressBlock:(PFProgressBlock)progressBlock {
    [[self _getDataAsyncWithProgressBlock:progressBlock] thenCallBackOnMainThreadAsync:resultBlock];
}

- (void)getDataStreamInBackgroundWithBlock:(PFDataStreamResultBlock)resultBlock
                             progressBlock:(PFProgressBlock)progressBlock {
    [[self _getDataStreamAsyncWithProgressBlock:progressBlock] thenCallBackOnMainThreadAsync:resultBlock];
}

- (BFTask<NSString *> *)getFilePathInBackground {
    return [self getFilePathInBackgroundWithProgressBlock:nil];
}

- (BFTask<NSString *> *)getFilePathInBackgroundWithProgressBlock:(PFProgressBlock)progressBlock {
    return [[self _downloadAsyncWithProgressBlock:progressBlock] continueWithSuccessBlock:^id(BFTask *task) {
        if (self.dirty) {
            return self.stagedFilePath;
        }
        return [[[self class] fileController] cachedFilePathForFileState:self.state];
    }];
}

- (void)getFilePathInBackgroundWithBlock:(nullable PFFilePathResultBlock)block {
    [[self getFilePathInBackground] thenCallBackOnMainThreadAsync:block];
}

- (void)getFilePathInBackgroundWithBlock:(nullable PFFilePathResultBlock)block
                           progressBlock:(nullable PFProgressBlock)progressBlock {
    [[self getFilePathInBackgroundWithProgressBlock:progressBlock] thenCallBackOnMainThreadAsync:block];
}

#pragma mark Interrupting

- (void)cancel {
    [self _performDataAccessBlock:^{
        [self.cancellationTokenSource cancel];
        self.cancellationTokenSource = nil;
    }];
}

#pragma mark Cache

- (BFTask *)clearCachedDataInBackground {
    @weakify(self);
    return [self.taskQueue enqueue:^id(BFTask *_) {
        @strongify(self);
        return [[[[self class] fileController] clearFileCacheAsyncForFileWithState:self.state] continueWithSuccessResult:nil];
    }];
}

+ (BFTask *)clearAllCachedDataInBackground {
    return [[[self fileController] clearAllFileCacheAsync] continueWithSuccessResult:nil];
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

#pragma mark Init

- (instancetype)initWithName:(NSString *)name urlString:(NSString *)url mimeType:(NSString *)mimeType {
    self = [super init];
    if (!self) return nil;

    _taskQueue = [[PFAsyncTaskQueue alloc] init];
    _synchronizationQueue = PFThreadsafetyCreateQueueForObject(self);

    _state = [[PFFileState alloc] initWithName:name urlString:url mimeType:mimeType];

    return self;
}

+ (instancetype)fileObjectWithName:(NSString *)name url:(NSString *)url {
    return [[self alloc] initWithName:name urlString:url mimeType:nil];
}

#pragma mark Upload

- (BFTask *)_uploadAsyncWithProgressBlock:(PFProgressBlock)progressBlock {
    @weakify(self);
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id {
        @strongify(self);

        __block BFCancellationToken *cancellationToken = nil;
        [self _performDataAccessBlock:^{
            if (!self.cancellationTokenSource || self.cancellationTokenSource.cancellationRequested) {
                self.cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
            }
            cancellationToken = self.cancellationTokenSource.token;
        }];

        return [[[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
            NSString *sessionToken = task.result;
            return [self.taskQueue enqueue:^id(BFTask *task) {
                if (!self.dirty) {
                    [self _performProgressBlockAsync:progressBlock withProgress:100];
                    return nil;
                }

                return [self _uploadFileAsyncWithSessionToken:sessionToken
                                            cancellationToken:cancellationToken
                                                progressBlock:progressBlock];
            }];
        }] continueWithSuccessResult:@YES];
    }];
}

- (BFTask *)_uploadFileAsyncWithSessionToken:(NSString *)sessionToken
                           cancellationToken:(BFCancellationToken *)cancellationToken
                               progressBlock:(PFProgressBlock)progressBlock {
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }

    PFFileController *controller = [[self class] fileController];
    @weakify(self);
    return [[[controller uploadFileAsyncWithState:[self _fileState]
                                   sourceFilePath:self.stagedFilePath
                                     sessionToken:sessionToken
                                cancellationToken:cancellationToken
                                    progressBlock:progressBlock] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        [self _performDataAccessBlock:^{
            self.state = [task.result copy];
        }];
        return nil;
    } cancellationToken:cancellationToken] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        [self _performDataAccessBlock:^{
            self.cancellationTokenSource = nil;
        }];
        return task;
    }];
}

#pragma mark Download

- (BFTask *)_getDataAsyncWithProgressBlock:(PFProgressBlock)progressBlock {
    return [[self _downloadAsyncWithProgressBlock:progressBlock] continueWithSuccessBlock:^id(BFTask *task) {
        return [self _cachedData];
    }];
}

- (BFTask *)_getDataStreamAsyncWithProgressBlock:(PFProgressBlock)progressBlock {
    return [[self _downloadAsyncWithProgressBlock:progressBlock] continueWithSuccessBlock:^id(BFTask *task) {
        return [self _cachedDataStream];
    }];
}

- (BFTask *)_downloadAsyncWithProgressBlock:(PFProgressBlock)progressBlock {
    __block BFCancellationToken *cancellationToken = nil;
    [self _performDataAccessBlock:^{
        if (!self.cancellationTokenSource || self.cancellationTokenSource.cancellationRequested) {
            self.cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
        }
        cancellationToken = self.cancellationTokenSource.token;
    }];

    @weakify(self);
    return [self.taskQueue enqueue:^id(BFTask *task) {
        @strongify(self);
        if (self.dataAvailable) {
            [self _performProgressBlockAsync:progressBlock withProgress:100];
            return nil;
        }

        PFFileController *controller = [[self class] fileController];
        return [[controller downloadFileAsyncWithState:[self _fileState]
                                     cancellationToken:cancellationToken
                                         progressBlock:progressBlock] continueWithBlock:^id(BFTask *task) {
            [self _performDataAccessBlock:^{
                self.cancellationTokenSource = nil;
            }];
            return task;
        }];
    }];
}

- (BFTask *)_downloadStreamAsyncWithProgressBlock:(PFProgressBlock)progressBlock {
    __block BFCancellationToken *cancellationToken = nil;
    [self _performDataAccessBlock:^{
        if (!self.cancellationTokenSource || self.cancellationTokenSource.cancellationRequested) {
            self.cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
        }
        cancellationToken = self.cancellationTokenSource.token;
    }];

    @weakify(self);
    return [self.taskQueue enqueue:^id(BFTask *task) {
        @strongify(self);
        if (self.dataAvailable) {
            [self _performProgressBlockAsync:progressBlock withProgress:100];
            return [self _cachedDataStream];
        }

        PFFileController *controller = [[self class] fileController];
        return [[controller downloadFileStreamAsyncWithState:[self _fileState]
                                           cancellationToken:cancellationToken
                                               progressBlock:progressBlock] continueWithBlock:^id(BFTask *task) {
            [self _performDataAccessBlock:^{
                self.cancellationTokenSource = nil;
            }];
            return task;
        }];
    }];
}

#pragma mark Caching

- (NSString *)_cachedFilePath {
    return [[[self class] fileController] cachedFilePathForFileState:self.state];
}

- (NSData *)_cachedData {
    NSString *filePath = (self.dirty ? self.stagedFilePath : [self _cachedFilePath]);
    if (!filePath) {
        return nil;
    }
    return [NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:NULL];
}

- (NSInputStream *)_cachedDataStream {
    NSString *filePath = (self.dirty ? self.stagedFilePath : [[[self class] fileController] cachedFilePathForFileState:self.state]);
    if (!filePath) {
        return nil;
    }
    return [NSInputStream inputStreamWithFileAtPath:filePath];
}

///--------------------------------------
#pragma mark - Staging
///--------------------------------------

- (BOOL)_stageWithData:(NSData *)data error:(NSError * __autoreleasing *)error {
    __block BOOL result = NO;
    [self _performDataAccessBlock:^{
        self->_stagedFilePath = [[[[self class] fileController].fileStagingController stageFileAsyncWithData:data
                                                                                                        name:self.state.name
                                                                                                    uniqueId:(uintptr_t)self]
                           waitForResult:error withMainThreadWarning:NO];

        result = (self->_stagedFilePath != nil);
    }];
    return result;
}

- (BOOL)_stageWithPath:(NSString *)path error:(NSError * __autoreleasing *)error {
    __block BOOL result = NO;
    [self _performDataAccessBlock:^{
        self->_stagedFilePath = [[[[self class] fileController].fileStagingController stageFileAsyncAtPath:path
                                                                                                      name:self.state.name
                                                                                                  uniqueId:(uintptr_t)self]
                           waitForResult:error withMainThreadWarning:NO];

        result = (self->_stagedFilePath != nil);
    }];
    return result;
}

#pragma mark Data Access

- (NSString *)name {
    __block NSString *name = nil;
    [self _performDataAccessBlock:^{
        name = self.state.name;
    }];
    return name;
}

- (NSString *)url {
    __block NSString *url = nil;
    [self _performDataAccessBlock:^{
        url = self.state.secureURLString;
    }];
    return url;
}

- (BOOL)isDirty {
    return !self.url;
}

- (BOOL)isDataAvailable {
    __block BOOL available = NO;
    [self _performDataAccessBlock:^{
        available = ((self.dirty && self.stagedFilePath) ||
                     (self.url && [[NSFileManager defaultManager] fileExistsAtPath:[self _cachedFilePath]]));
    }];
    return available;
}

- (void)_performDataAccessBlock:(dispatch_block_t)block {
    PFThreadsafetySafeDispatchSync(_synchronizationQueue, block);
}

- (PFFileState *)_fileState {
    __block PFFileState *state = nil;
    [self _performDataAccessBlock:^{
        state = self.state;
    }];
    return state;
}

#pragma mark Progress

- (void)_performProgressBlockAsync:(PFProgressBlock)block withProgress:(int)progress {
    if (!block) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        block(progress);
    });
}

///--------------------------------------
#pragma mark - FileController
///--------------------------------------

+ (PFFileController *)fileController {
    return [Parse _currentManager].coreManager.fileController;
}

@end

///--------------------------------------
#pragma mark - Synchronous
///--------------------------------------

@implementation PFFileObject (Synchronous)

#pragma mark Storing Data with Parse

- (BOOL)save {
    return [self save:nil];
}

- (BOOL)save:(NSError **)error {
    return [[[self saveInBackground] waitForResult:error] boolValue];
}

#pragma mark Getting Data from Parse

- (NSData *)getData {
    return [self getData:nil];
}

- (NSData *)getData:(NSError **)error {
    return [[self getDataInBackground] waitForResult:error];
}

- (NSInputStream *)getDataStream {
    return [self getDataStream:nil];
}

- (NSInputStream *)getDataStream:(NSError **)error {
    return [[self getDataStreamInBackground] waitForResult:error];
}

@end

///--------------------------------------
#pragma mark - Deprecated
///--------------------------------------

@implementation PFFileObject (Deprecated)

- (void)saveInBackgroundWithTarget:(nullable id)target selector:(nullable SEL)selector {
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

- (void)getDataInBackgroundWithTarget:(nullable id)target selector:(nullable SEL)selector {
    [self getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:data object:error];
    }];
}

@end
