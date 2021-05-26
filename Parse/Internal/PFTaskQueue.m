/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTaskQueue.h"

#import <Bolts/BFTask.h>

@interface PFTaskQueue ()

@property (nonatomic, strong, readwrite) BFTask *tail;
@property (nonatomic, strong, readwrite) NSObject *mutex;

@end

@implementation PFTaskQueue

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    self.mutex = [[NSObject alloc] init];

    return self;
}

- (BFTask *)enqueue:(BFTask *(^)(BFTask *toAwait))taskStart {
    @synchronized (self.mutex) {
        BFTask *oldTail = self.tail ?: [BFTask taskWithResult:nil];

        // The task created by taskStart is responsible for waiting on the
        // task passed to it before doing its work. This gives it an opportunity
        // to do startup work or save state before waiting for its turn in the queue.
        BFTask *task = taskStart(oldTail);

        // The tail task should be dependent on the old tail as well as the newly-created
        // task. This prevents cancellation of the new task from causing the queue to run
        // out of order.
        self.tail = [BFTask taskForCompletionOfAllTasks:@[oldTail, task]];

        return task;
    }
}

@end
