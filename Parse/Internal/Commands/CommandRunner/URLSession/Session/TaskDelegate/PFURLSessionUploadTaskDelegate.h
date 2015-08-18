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

#import "PFURLSessionJSONDataTaskDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFURLSessionUploadTaskDelegate : PFURLSessionJSONDataTaskDelegate

- (instancetype)initForDataTask:(NSURLSessionDataTask *)dataTask
          withCancellationToken:(nullable BFCancellationToken *)cancellationToken
            uploadProgressBlock:(nullable PFProgressBlock)progressBlock;
+ (instancetype)taskDelegateForDataTask:(NSURLSessionDataTask *)dataTask
                  withCancellationToken:(nullable BFCancellationToken *)cancellationToken
                    uploadProgressBlock:(nullable PFProgressBlock)progressBlock;

@end

NS_ASSUME_NONNULL_END
