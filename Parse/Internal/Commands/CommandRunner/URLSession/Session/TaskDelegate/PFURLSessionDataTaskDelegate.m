/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSessionDataTaskDelegate.h"
#import "PFURLSessionDataTaskDelegate_Private.h"

#import <Bolts/BFTaskCompletionSource.h>
#import <Bolts/BFCancellationToken.h>

#import "PFAssert.h"
#import "PFMacros.h"

@interface PFURLSessionDataTaskDelegate () {
    BFTaskCompletionSource *_taskCompletionSource;
}

@end

@implementation PFURLSessionDataTaskDelegate

@synthesize dataOutputStream = _dataOutputStream;
@synthesize downloadedBytes = _downloadedBytes;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initForDataTask:(NSURLSessionDataTask *)dataTask
          withCancellationToken:(BFCancellationToken *)cancellationToken {
    self = [super init];
    if (!self) return nil;

    _taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];

    _dataTask = dataTask;
    @weakify(self);
    [cancellationToken registerCancellationObserverWithBlock:^{
        @strongify(self);
        [self _cancel];
    }];

    return self;
}

+ (instancetype)taskDelegateForDataTask:(NSURLSessionDataTask *)dataTask
                  withCancellationToken:(nullable BFCancellationToken *)cancellationToken {
    return [[self alloc] initForDataTask:dataTask withCancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (BFTask *)resultTask {
    return _taskCompletionSource.task;
}

- (NSOutputStream *)dataOutputStream {
    if (!_dataOutputStream) {
        _dataOutputStream = [NSOutputStream outputStreamToMemory];
    }
    return _dataOutputStream;
}

///--------------------------------------
#pragma mark - Task
///--------------------------------------

- (void)_taskDidFinish {
    [self _closeDataOutputStream];
    if (self.error) {
        [_taskCompletionSource trySetError:self.error];
    } else {
        [_taskCompletionSource trySetResult:self.result];
    }
}

- (void)_taskDidCancel {
    [self _closeDataOutputStream];
    [_taskCompletionSource trySetCancelled];
}

- (void)_cancel {
    [self.dataTask cancel];
}

///--------------------------------------
#pragma mark - Stream
///--------------------------------------

- (void)_openDataOutputStream {
    [self.dataOutputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.dataOutputStream open];
}

- (void)_writeDataOutputStreamData:(NSData *)data {
    NSInteger length = data.length;
    while (YES) {
        NSInteger bytesWritten = 0;
        if ([self.dataOutputStream hasSpaceAvailable]) {
            const uint8_t *dataBuffer = (uint8_t *)[data bytes];

            NSInteger numberOfBytesWritten = 0;
            while (bytesWritten < length) {
                numberOfBytesWritten = [self.dataOutputStream write:&dataBuffer[bytesWritten]
                                                          maxLength:(length - bytesWritten)];
                if (numberOfBytesWritten == -1) {
                    break;
                }

                bytesWritten += numberOfBytesWritten;
            }
            break;
        }

        if (self.dataOutputStream.streamError) {
            [self.dataTask cancel];
            self.error = self.dataOutputStream.streamError;
            // Don't finish the delegate here, as we will finish when NSURLSessionTask calls back about cancellation.
            return;
        }
    }
    _downloadedBytes += length;
}

- (void)_closeDataOutputStream {
    [self.dataOutputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.dataOutputStream close];
}

///--------------------------------------
#pragma mark - NSURLSessionTaskDelegate
///--------------------------------------

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
    totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    // No-op, we don't care about progress here.
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        [self _taskDidCancel];
    } else {
        self.error = self.error ?: error;
        [self _taskDidFinish];
    }
}

///--------------------------------------
#pragma mark - NSURLSessionDataDelegate
///--------------------------------------

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    _response = (NSHTTPURLResponse *)response;
    [self _openDataOutputStream];

    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self _writeDataOutputStreamData:data];
}

@end
