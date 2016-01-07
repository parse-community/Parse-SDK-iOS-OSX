/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

#import "PFDataProvider.h"
#import "PFMacros.h"

@class BFCancellationToken;
@class BFTask<__covariant BFGenericType>;
@class PFFileState;
@class PFFileStagingController;
@class PFFileDataStream;

@interface PFFileController : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider, PFFileManagerProvider> dataSource;

@property (nonatomic, strong, readonly) PFFileStagingController *fileStagingController;

@property (nonatomic, copy, readonly) NSString *cacheFilesDirectoryPath;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource;

///--------------------------------------
#pragma mark - Download
///--------------------------------------

/**
 Downloads a file asynchronously with a given state.

 @param fileState         File state to download the file for.
 @param cancellationToken Cancellation token.
 @param progressBlock     Progress block to call (optional).

 @return `BFTask` with a result set to `nil`.
 */
- (BFTask<PFVoid> *)downloadFileAsyncWithState:(PFFileState *)fileState
                             cancellationToken:(BFCancellationToken *)cancellationToken
                                 progressBlock:(PFProgressBlock)progressBlock;

/**
 Downloads a file asynchronously with a given state and yields a stream to the live download of that file.

 @param fileState File state to download the file for.
 @param cancellationToken Cancellation token.
 @param progressBlock Progress block to call (optional).

 @return `BFTask` with a result set to live `NSInputStream` of the file.
 */
- (BFTask<PFFileDataStream *> *)downloadFileStreamAsyncWithState:(PFFileState *)fileState
                                               cancellationToken:(BFCancellationToken *)cancellationToken
                                                   progressBlock:(PFProgressBlock)progressBlock;

///--------------------------------------
#pragma mark - Upload
///--------------------------------------

/**
 Uploads a file asynchronously from file path for a given file state.

 @param fileState         File state to upload the file for.
 @param sourceFilePath    Source file path.
 @param sessionToken      Session token to use.
 @param cancellationToken Cancellation token.
 @param progressBlock     Progress block to call (optional).

 @return `BFTask` with a result set to `PFFileState` of uploaded file.
 */
- (BFTask<PFFileState *> *)uploadFileAsyncWithState:(PFFileState *)fileState
                                     sourceFilePath:(NSString *)sourceFilePath
                                       sessionToken:(NSString *)sessionToken
                                  cancellationToken:(BFCancellationToken *)cancellationToken
                                      progressBlock:(PFProgressBlock)progressBlock;

///--------------------------------------
#pragma mark - Cache
///--------------------------------------

- (BFTask<PFVoid> *)clearFileCacheAsync;

- (NSString *)cachedFilePathForFileState:(PFFileState *)fileState;

@end
