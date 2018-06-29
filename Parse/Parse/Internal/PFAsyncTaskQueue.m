/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAsyncTaskQueue.h"

#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"

@interface PFAsyncTaskQueue()

@property (nonatomic, strong) dispatch_queue_t syncQueue;
@property (nonatomic, strong) BFTask *tail;

@end

@implementation PFAsyncTaskQueue

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _tail = [BFTask taskWithResult:nil];
    _syncQueue = dispatch_queue_create("com.parse.asynctaskqueue.sync", DISPATCH_QUEUE_SERIAL);

    return self;
}

+ (instancetype)taskQueue {
    return [[self alloc] init];
}

///--------------------------------------
#pragma mark - Enqueue
///--------------------------------------

- (BFTask *)enqueue:(BFContinuationBlock)block {
    BFTaskCompletionSource *source = [BFTaskCompletionSource taskCompletionSource];
    dispatch_async(_syncQueue, ^{
        self->_tail = [self->_tail continueAsyncWithBlock:block];
        [self->_tail continueAsyncWithBlock:^id(BFTask *task) {
            if (task.faulted) {
                [source trySetError:task.error];
            } else if (task.cancelled) {
                [source trySetCancelled];
            } else {
                [source trySetResult:task.result];
            }
            return task;
        }];
    });
    return source.task;
}

@end
