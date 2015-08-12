/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class BFCancellationToken;
@class BFTask;

NS_ASSUME_NONNULL_BEGIN

@interface PFURLSessionDataTaskDelegate : NSObject <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong, readonly) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong, readonly) BFTask *resultTask;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initForDataTask:(NSURLSessionDataTask *)dataTask
          withCancellationToken:(nullable BFCancellationToken *)cancellationToken NS_DESIGNATED_INITIALIZER;

+ (instancetype)taskDelegateForDataTask:(NSURLSessionDataTask *)dataTask
                  withCancellationToken:(nullable BFCancellationToken *)cancellationToken;

@end

NS_ASSUME_NONNULL_END
