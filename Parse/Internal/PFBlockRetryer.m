/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFBlockRetryer.h"

#import <Bolts/BFTask.h>

#import "BFTask+Private.h"

@implementation PFBlockRetryer

+ (BFTask *)retryBlock:(PFBlockRetryerBlock)block forAttempts:(NSUInteger)attempts {
    NSTimeInterval delay = initialRetryDelay_;
    delay += initialRetryDelay_ * ((double)arc4random_uniform(0x0FFFF) / 0x0FFFF);
    return [self retryBlock:block forAttempts:attempts delay:delay];
}

+ (BFTask *)retryBlock:(PFBlockRetryerBlock)block forAttempts:(NSUInteger)attempts delay:(NSTimeInterval)delay {
    return [block() continueWithBlock:^id(BFTask *task) {
        if (!task.error && !task.exception) {
            return task;
        }

        if (attempts <= 1) {
            return task;
        }

        return [[BFTask taskWithDelay:(int)(delay * 1000)] continueWithBlock:^id(BFTask *task) {
            return [self retryBlock:block forAttempts:(attempts - 1)];
        }];
    }];
}

///--------------------------------------
#pragma mark - Delay
///--------------------------------------

static NSTimeInterval initialRetryDelay_ = 1.0;

+ (void)setInitialRetryDelay:(NSTimeInterval)newDelay {
    initialRetryDelay_ = newDelay;
}

+ (NSTimeInterval)initialRetryDelay {
    return initialRetryDelay_;
}

@end
