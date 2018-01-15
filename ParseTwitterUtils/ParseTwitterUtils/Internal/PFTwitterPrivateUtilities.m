/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTwitterPrivateUtilities.h"

#import <Bolts/BFExecutor.h>

@implementation PFTwitterPrivateUtilities

+ (void)safePerformSelector:(SEL)selector
                   onTarget:(id)target
                 withObject:(id)object
                     object:(id)anotherObject {
    if (target == nil || selector == nil || ![target respondsToSelector:selector]) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [target performSelector:selector withObject:object withObject:anotherObject];
#pragma clang diagnostic pop
}

@end

@implementation BFTask (ParseTwitterUtils)

- (id)pftw_waitForResult:(NSError **)error {
    [self waitUntilFinished];

    if (self.cancelled) {
        return nil;
    } else if (self.error && error) {
        *error = self.error;
    }
    return self.result;
}

- (instancetype)pftw_continueAsyncWithBlock:(BFContinuationBlock)block {
    BFExecutor *executor = [BFExecutor executorWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    return [self continueWithExecutor:executor withBlock:block];
}

- (instancetype)pftw_continueWithMainThreadUserBlock:(PFUserResultBlock)block {
    return [self pftw_continueWithMainThreadBlock:^id(BFTask *task) {
        if (block) {
            block(task.result, task.error);
        }
        return nil;
    }];
}

- (instancetype)pftw_continueWithMainThreadBooleanBlock:(PFBooleanResultBlock)block {
    return [self pftw_continueWithMainThreadBlock:^id(BFTask *task) {
        if (block) {
            block([task.result boolValue], task.error);
        }
        return nil;
    }];
}

- (instancetype)pftw_continueWithMainThreadBlock:(BFContinuationBlock)block {
    return [self continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:block];
}

@end
