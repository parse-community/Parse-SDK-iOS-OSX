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

@class BFCancellationToken;
@class BFTask;
@class PFFileState;
@class PFFileStagingController;

@interface PFFileController : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider, PFFileManagerProvider> dataSource;

@property (nonatomic, strong, readonly) PFFileStagingController *fileStagingController;

@property (nonatomic, copy, readonly) NSString *cacheFilesDirectoryPath;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource;


///--------------------------------------
/// @name Download
///--------------------------------------

/*!
 Downloads a file asynchronously with a given state.

 @param fileState         File state to download the file for.
 @param cancellationToken Cancellation token.
 @param progressBlock     Progress block to call (optional).

 @returns `BFTask` with a result set to `nil`.
 */
- (BFTask *)downloadFileAsyncWithState:(PFFileState *)fileState
                     cancellationToken:(BFCancellationToken *)cancellationToken
                         progressBlock:(PFProgressBlock)progressBlock;

/*!
 Downloads a file asynchronously with a given state and yields a stream to the live download of that file.

 @param fileState File state to download the file for.
 @param cancellationToken Cancellation token.
 @param progressBlock Progress block to call (optional).

 @return `BFTask` with a result set to live `NSInputStream` of the file.
 */
- (BFTask *)downloadFileStreamAsyncWithState:(PFFileState *)fileState
                           cancellationToken:(BFCancellationToken *)cancellationToken
                               progressBlock:(PFProgressBlock)progressBlock;

///--------------------------------------
/// @name Upload
///--------------------------------------

/*!
 Uploads a file asynchronously from file path for a given file state.

 @param fileState         File state to upload the file for.
 @param sourceFilePath    Source file path.
 @param sessionToken      Session token to use.
 @param cancellationToken Cancellation token.
 @param progressBlock     Progress block to call (optional).

 @returns `BFTask` with a result set to `PFFileState` of uploaded file.
 */
- (BFTask *)uploadFileAsyncWithState:(PFFileState *)fileState
                      sourceFilePath:(NSString *)sourceFilePath
                        sessionToken:(NSString *)sessionToken
                   cancellationToken:(BFCancellationToken *)cancellationToken
                       progressBlock:(PFProgressBlock)progressBlock;

///--------------------------------------
/// @name Cache
///--------------------------------------

- (BFTask *)clearFileCacheAsync;

- (NSString *)cachedFilePathForFileState:(PFFileState *)fileState;

@end
