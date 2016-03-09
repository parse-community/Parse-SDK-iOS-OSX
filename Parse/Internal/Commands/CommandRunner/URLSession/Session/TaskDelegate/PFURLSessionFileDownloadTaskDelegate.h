/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSessionDataTaskDelegate.h"

#import <Parse/PFConstants.h>

NS_ASSUME_NONNULL_BEGIN

@interface PFURLSessionFileDownloadTaskDelegate : PFURLSessionDataTaskDelegate

@property (nonatomic, copy, readonly) NSString *targetFilePath;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initForDataTask:(NSURLSessionDataTask *)dataTask
          withCancellationToken:(nullable BFCancellationToken *)cancellationToken
                 targetFilePath:(NSString *)targetFilePath
                  progressBlock:(nullable PFProgressBlock)progressBlock;
+ (instancetype)taskDelegateForDataTask:(NSURLSessionDataTask *)dataTask
                  withCancellationToken:(nullable BFCancellationToken *)cancellationToken
                         targetFilePath:(NSString *)targetFilePath
                          progressBlock:(nullable PFProgressBlock)progressBlock;

@end

NS_ASSUME_NONNULL_END
