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

@class BFCancellationToken;
@class BFTask;
@class PFRESTCommand;

NS_ASSUME_NONNULL_BEGIN

@interface PFURLSession : NSObject

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
+ (instancetype)sessionWithConfiguration:(NSURLSessionConfiguration *)configuration;

///--------------------------------------
/// @name Teardown
///--------------------------------------

- (void)invalidateAndCancel;

///--------------------------------------
/// @name Network Requests
///--------------------------------------

- (BFTask *)performDataURLRequestAsync:(NSURLRequest *)request
                            forCommand:(PFRESTCommand *)command
                     cancellationToken:(nullable BFCancellationToken *)cancellationToken;

- (BFTask *)performFileUploadURLRequestAsync:(NSURLRequest *)request
                                  forCommand:(PFRESTCommand *)command
                   withContentSourceFilePath:(NSString *)sourceFilePath
                           cancellationToken:(nullable BFCancellationToken *)cancellationToken
                               progressBlock:(nullable PFProgressBlock)progressBlock;

- (BFTask *)performFileDownloadURLRequestAsync:(NSURLRequest *)request
                                  toFileAtPath:(NSString *)filePath
                         withCancellationToken:(nullable BFCancellationToken *)cancellationToken
                                 progressBlock:(nullable PFProgressBlock)progressBlock;


@end

NS_ASSUME_NONNULL_END
