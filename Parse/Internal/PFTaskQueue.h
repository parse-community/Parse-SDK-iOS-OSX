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

@class BFTask PF_GENERIC(__covariant BFGenericType);

@interface PFTaskQueue : NSObject

// The lock for this task queue.
@property (nonatomic, strong, readonly) NSObject *mutex;

/*!
 Enqueues a task created by the given block. Then block is given a task to
 await once state is snapshotted (e.g. after capturing session tokens at the
 time of the save call. Awaiting this task will wait for the created task's
 turn in the queue.
 */
- (BFTask *)enqueue:(BFTask *(^)(BFTask *toAwait))taskStart;

@end
