/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSessionUploadTaskDelegate.h"

@implementation PFURLSessionUploadTaskDelegate {
    __nullable PFProgressBlock _progressBlock;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initForDataTask:(NSURLSessionDataTask *)dataTask
          withCancellationToken:(nullable BFCancellationToken *)cancellationToken
            uploadProgressBlock:(nullable PFProgressBlock)progressBlock {
    self = [self initForDataTask:dataTask withCancellationToken:cancellationToken];
    if (!self) return nil;

    _progressBlock = [progressBlock copy];

    return self;
}

+ (instancetype)taskDelegateForDataTask:(NSURLSessionDataTask *)dataTask
                  withCancellationToken:(nullable BFCancellationToken *)cancellationToken
                    uploadProgressBlock:(nullable PFProgressBlock)progressBlock {
    return [[self alloc] initForDataTask:dataTask
                   withCancellationToken:cancellationToken
                     uploadProgressBlock:progressBlock];
}

///--------------------------------------
#pragma mark - NSURLSessionTaskDelegate
///--------------------------------------

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    int progress = (int)round(totalBytesSent / (double)totalBytesExpectedToSend * 100);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressBlock) {
            _progressBlock(progress);
        }
    });
}

@end
