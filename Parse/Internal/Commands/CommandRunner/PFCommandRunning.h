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
@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFCommandResult;
@class PFRESTCommand;
@protocol PFNetworkCommand;

typedef NS_OPTIONS(NSUInteger, PFCommandRunningOptions) {
    PFCommandRunningOptionRetryIfFailed = 1 << 0,
};

extern NSTimeInterval const PFCommandRunningDefaultRetryDelay;

NS_ASSUME_NONNULL_BEGIN

@protocol PFCommandRunning <NSObject>

@property (nonatomic, weak, readonly) id<PFInstallationIdentifierStoreProvider> dataSource;

@property (nonatomic, copy, readonly) NSString *applicationId;
@property (nonatomic, copy, readonly) NSString *clientKey;

@property (nonatomic, assign) NSTimeInterval initialRetryDelay;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                     applicationId:(NSString *)applicationId
                         clientKey:(NSString *)clientKey;
+ (instancetype)commandRunnerWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                              applicationId:(NSString *)applicationId
                                  clientKey:(NSString *)clientKey;

///--------------------------------------
/// @name Data Commands
///--------------------------------------

/**
 Run command.

 @param command   Command to run.
 @param options   Options to use to run command.

 @return `BFTask` with result set to `PFCommandResult`.
 */
- (BFTask *)runCommandAsync:(PFRESTCommand *)command
                withOptions:(PFCommandRunningOptions)options;

/**
 Run command.

 @param command           Command to run.
 @param options           Options to use to run command.
 @param cancellationToken Operation to use as a cancellation token.

 @return `BFTask` with result set to `PFCommandResult`.
 */
- (BFTask *)runCommandAsync:(PFRESTCommand *)command
                withOptions:(PFCommandRunningOptions)options
          cancellationToken:(nullable BFCancellationToken *)cancellationToken;

///--------------------------------------
/// @name File Commands
///--------------------------------------

- (BFTask *)runFileUploadCommandAsync:(PFRESTCommand *)command
                      withContentType:(NSString *)contentType
                contentSourceFilePath:(NSString *)sourceFilePath
                              options:(PFCommandRunningOptions)options
                    cancellationToken:(nullable BFCancellationToken *)cancellationToken
                        progressBlock:(nullable PFProgressBlock)progressBlock;

- (BFTask *)runFileDownloadCommandAsyncWithFileURL:(NSURL *)url
                                    targetFilePath:(NSString *)filePath
                                 cancellationToken:(nullable BFCancellationToken *)cancellationToken
                                     progressBlock:(nullable PFProgressBlock)progressBlock;

@end

NS_ASSUME_NONNULL_END
