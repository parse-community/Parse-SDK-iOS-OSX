/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFThreadsafety.h"

static void *const PFThreadsafetyQueueIDKey = (void *)&PFThreadsafetyQueueIDKey;

dispatch_queue_t PFThreadsafetyCreateQueueForObject(id object) {
    NSString *label = [NSStringFromClass([object class]) stringByAppendingString:@".synchronizationQueue"];
    dispatch_queue_t queue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_SERIAL);

    void *uuid = calloc(1, sizeof(uuid));
    dispatch_queue_set_specific(queue, PFThreadsafetyQueueIDKey, uuid, free);

    return queue;
}

void PFThreadsafetySafeDispatchSync(dispatch_queue_t queue, dispatch_block_t block) {
    void *uuidMine = dispatch_get_specific(PFThreadsafetyQueueIDKey);
    void *uuidOther = dispatch_queue_get_specific(queue, PFThreadsafetyQueueIDKey);

    if (uuidMine == uuidOther) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}
