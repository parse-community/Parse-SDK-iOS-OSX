/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSessionFileDownloadTaskDelegate.h"

#import "PFErrorUtilities.h"
#import "PFHash.h"
#import "PFURLSessionDataTaskDelegate_Private.h"

@interface PFURLSessionFileDownloadTaskDelegate () {
    NSOutputStream *_fileDataOutputStream;
    PFProgressBlock _progressBlock;
}

@end

@implementation PFURLSessionFileDownloadTaskDelegate

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initForDataTask:(NSURLSessionDataTask *)dataTask
          withCancellationToken:(BFCancellationToken *)cancellationToken
                 targetFilePath:(NSString *)targetFilePath
                  progressBlock:(PFProgressBlock)progressBlock {
    self = [super initForDataTask:dataTask withCancellationToken:cancellationToken];
    if (!self) return nil;

    _targetFilePath = targetFilePath;
    _fileDataOutputStream = [NSOutputStream outputStreamToFileAtPath:_targetFilePath append:NO];
    _progressBlock = progressBlock;

    return self;
}

+ (instancetype)taskDelegateForDataTask:(NSURLSessionDataTask *)dataTask
                  withCancellationToken:(BFCancellationToken *)cancellationToken
                         targetFilePath:(NSString *)targetFilePath
                          progressBlock:(PFProgressBlock)progressBlock {
    return [[self alloc] initForDataTask:dataTask
                   withCancellationToken:cancellationToken
                          targetFilePath:targetFilePath
                           progressBlock:progressBlock];
}

///--------------------------------------
#pragma mark - Progress
///--------------------------------------

- (void)_reportProgress {
    if (!_progressBlock) {
        return;
    }

    int progress = (int)(self.downloadedBytes / (CGFloat)self.response.expectedContentLength * 100);
    _progressBlock(progress);
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (NSOutputStream *)dataOutputStream {
    return _fileDataOutputStream;
}

///--------------------------------------
#pragma mark - Task
///--------------------------------------

- (void)_taskDidFinish {
    if (self.error) {
        // TODO: (nlutsenko) Unify this with code from PFURLSessionJSONDataTaskDelegate
        NSMutableDictionary *errorDictionary = [NSMutableDictionary dictionary];
        errorDictionary[@"code"] = @(kPFErrorConnectionFailed);
        errorDictionary[@"error"] = [self.error localizedDescription];
        errorDictionary[@"originalError"] = self.error;
        errorDictionary[NSUnderlyingErrorKey] = self.error;
        errorDictionary[@"temporary"] = @(self.response.statusCode >= 500 || self.response.statusCode < 400);
        self.error = [PFErrorUtilities errorFromResult:errorDictionary];
    }
    [super _taskDidFinish];
}

///--------------------------------------
#pragma mark - NSURLSessionDataDelegate
///--------------------------------------

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [super URLSession:session dataTask:dataTask didReceiveData:data];
    [self _reportProgress];
}

@end
