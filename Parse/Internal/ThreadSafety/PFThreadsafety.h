/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

extern dispatch_queue_t PFThreadsafetyCreateQueueForObject(id object);
extern void PFThreadsafetySafeDispatchSync(dispatch_queue_t queue, dispatch_block_t block);


// PFThreadsafetySafeDispatchSync, but with a return type.
#define PFThreadSafetyPerform(queue, block) ({                      \
    __block typeof((block())) result;                              \
    PFThreadsafetySafeDispatchSync(queue, ^{ result = block(); }); \
    result;                                                        \
})
