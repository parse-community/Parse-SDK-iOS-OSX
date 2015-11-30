/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "BFTask+Private.h"

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "PFLogging.h"

@implementation BFExecutor (Background)

+ (instancetype)defaultPriorityBackgroundExecutor {
    static BFExecutor *executor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        executor = [BFExecutor executorWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    });
    return executor;
}

@end

@implementation BFTask (Private)

- (instancetype)continueAsyncWithBlock:(BFContinuationBlock)block {
    return [self continueWithExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:block];
}

- (instancetype)continueAsyncWithSuccessBlock:(BFContinuationBlock)block {
    return [self continueWithExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withSuccessBlock:block];
}

- (BFTask *)continueImmediatelyWithBlock:(BFContinuationBlock)block {
    return [self continueWithExecutor:[BFExecutor immediateExecutor] withBlock:block];
}

- (BFTask *)continueImmediatelyWithSuccessBlock:(BFContinuationBlock)block {
    return [self continueWithExecutor:[BFExecutor immediateExecutor] withSuccessBlock:block];
}

- (instancetype)continueWithResult:(id)result {
    return [self continueWithBlock:^id(BFTask *task) {
        return result;
    }];
}

- (instancetype)continueWithSuccessResult:(id)result {
    return [self continueWithSuccessBlock:^id(BFTask *task) {
        return result;
    }];
}

- (instancetype)continueWithMainThreadResultBlock:(PFIdResultBlock)resultBlock
                               executeIfCancelled:(BOOL)executeIfCancelled {
    if (!resultBlock) {
        return self;
    }
    return [self continueWithExecutor:[BFExecutor mainThreadExecutor]
                            withBlock:^id(BFTask *task) {
                                BFTaskCompletionSource *tcs = [BFTaskCompletionSource taskCompletionSource];

                                @try {
                                    if (self.exception) {
                                        //TODO: (nlutsenko) Add more context, by passing a `_cmd` from the caller method
                                        PFLogException(self.exception);
                                        @throw self.exception;
                                    }

                                    if (!self.cancelled || executeIfCancelled) {
                                        resultBlock(self.result, self.error);
                                    }
                                } @finally {
                                    tcs.result = nil;
                                }

                                return tcs.task;
                            }];
}

- (instancetype)continueWithMainThreadBooleanResultBlock:(PFBooleanResultBlock)resultBlock
                                      executeIfCancelled:(BOOL)executeIfCancelled {
    return [self continueWithMainThreadResultBlock:^(id object, NSError *error) {
        resultBlock([object boolValue], error);
    } executeIfCancelled:executeIfCancelled];
}

- (BFTask *)thenCallBackOnMainThreadAsync:(void(^)(id result, NSError *error))block {
    return [self continueWithMainThreadResultBlock:block executeIfCancelled:NO];
}

- (BFTask *)thenCallBackOnMainThreadWithBoolValueAsync:(void(^)(BOOL result, NSError *error))block {
    if (!block) {
        return self;
    }
    return [self thenCallBackOnMainThreadAsync:^(id blockResult, NSError *blockError) {
        block([blockResult boolValue], blockError);
    }];
}

- (id)waitForResult:(NSError **)error {
    return [self waitForResult:error withMainThreadWarning:YES];
}

- (id)waitForResult:(NSError **)error withMainThreadWarning:(BOOL)warningEnabled {
    if (warningEnabled) {
        [self waitUntilFinished];
    } else {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self continueWithBlock:^id(BFTask *task) {
            dispatch_semaphore_signal(semaphore);
            return nil;
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    }
    if (self.cancelled) {
        return nil;
    } else if (self.exception) {
        @throw self.exception;
    }
    if (self.error && error) {
        *error = self.error;
    }
    return self.result;
}

@end

void forceLoadCategory_BFTask_Private() {
    NSString *string = nil;
    [string description];
}
