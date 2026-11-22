/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCloud.h"

#if __has_include(<Bolts/BFCancellationTokenSource.h>)
#import <Bolts/BFCancellationTokenSource.h>
#import <Bolts/BFTaskCompletionSource.h>
#else
#import "BFCancellationTokenSource.h"
#import "BFTaskCompletionSource.h"
#endif

#import "BFTask+Private.h"
#import "PFCloudCodeController.h"
#import "PFCommandResult.h"
#import "PFCoreManager.h"
#import "PFMacros.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

@implementation PFCloud {
    NSMutableSet<BFCancellationTokenSource *> *_callCancellationTokenSources;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _callCancellationTokenSources = [NSMutableSet set];

    return self;
}

///--------------------------------------
#pragma mark - Public
///--------------------------------------

+ (BFTask *)callFunctionInBackground:(NSString *)functionName withParameters:(NSDictionary *)parameters {
    return [[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        PFCloudCodeController *controller = [Parse _currentManager].coreManager.cloudCodeController;
        return [controller callCloudCodeFunctionAsync:functionName
                                       withParameters:parameters
                                         sessionToken:sessionToken];
    }];
}

+ (void)callFunctionInBackground:(NSString *)function
                  withParameters:(NSDictionary *)parameters
                           block:(PFIdResultBlock)block {
    [[self callFunctionInBackground:function withParameters:parameters] thenCallBackOnMainThreadAsync:block];
}

- (BFTask *)callFunctionInBackground:(NSString *)function withParameters:(NSDictionary *)parameters {
    return [self _callFunctionInBackground:function withParameters:parameters block:nil];
}

- (void)callFunctionInBackground:(NSString *)function
                  withParameters:(NSDictionary *)parameters
                           block:(PFIdResultBlock)block {
    [self _callFunctionInBackground:function withParameters:parameters block:block];
}

- (void)cancel {
    @synchronized(self) {
        NSArray<BFCancellationTokenSource *> *callCancellationTokenSources = _callCancellationTokenSources.allObjects;
        [_callCancellationTokenSources removeAllObjects];
        // Cancelled while holding the lock, so that a concurrent cancel only returns once all calls are cancelled
        [callCancellationTokenSources makeObjectsPerformSelector:@selector(cancel)];
    }
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

/**
 Calls the function with a cancellation token of its own, which `cancel` cancels until the call has completed,
 and with a block, until the block has been called.

 @return The task of the call, which is cancelled without waiting for the request if the call is cancelled
 before it completes.
 */
- (BFTask *)_callFunctionInBackground:(NSString *)function
                       withParameters:(NSDictionary *)parameters
                                block:(PFIdResultBlock)block {
    BFCancellationTokenSource *cancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    BFCancellationToken *cancellationToken = cancellationTokenSource.token;
    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    __weak BFTaskCompletionSource *weakTaskCompletionSource = taskCompletionSource;
    [cancellationToken registerCancellationObserverWithBlock:^{
        // Not on the cancelling thread, where continuations of the task could block it or deadlock
        BFTaskCompletionSource *strongTaskCompletionSource = weakTaskCompletionSource;
        [[BFExecutor defaultPriorityBackgroundExecutor] execute:^{
            [strongTaskCompletionSource trySetCancelled];
        }];
    }];
    @synchronized(self) {
        [_callCancellationTokenSources addObject:cancellationTokenSource];
    }

    [[[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        PFCloudCodeController *controller = [Parse _currentManager].coreManager.cloudCodeController;
        return [controller callCloudCodeFunctionAsync:function
                                       withParameters:parameters
                                         sessionToken:sessionToken
                                    cancellationToken:cancellationToken];
    } cancellationToken:cancellationToken] continueWithBlock:^id(BFTask *task) {
        if (task.cancelled) {
            [taskCompletionSource trySetCancelled];
        } else if (task.faulted) {
            [taskCompletionSource trySetError:task.error];
        } else {
            [taskCompletionSource trySetResult:task.result];
        }
        return nil;
    }];

    // The call stays cancellable until the block is called, so that cancelling also stops a queued block
    @weakify(self);
    [[taskCompletionSource.task thenCallBackOnMainThreadAsync:block
                                            cancellationToken:cancellationToken] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        if (!self) {
            return nil;
        }
        @synchronized(self) {
            [self->_callCancellationTokenSources removeObject:cancellationTokenSource];
        }
        return nil;
    }];
    return taskCompletionSource.task;
}

@end

///--------------------------------------
#pragma mark - Synchronous
///--------------------------------------

@implementation PFCloud (Synchronous)

+ (id)callFunction:(NSString *)function withParameters:(NSDictionary *)parameters {
    return [self callFunction:function withParameters:parameters error:nil];
}

+ (id)callFunction:(NSString *)function withParameters:(NSDictionary *)parameters error:(NSError **)error {
    return [[self callFunctionInBackground:function withParameters:parameters] waitForResult:error];
}

@end

///--------------------------------------
#pragma mark - Deprecated
///--------------------------------------

@implementation PFCloud (Deprecated)

+ (void)callFunctionInBackground:(NSString *)function
                  withParameters:(nullable NSDictionary *)parameters
                          target:(nullable id)target
                        selector:(nullable SEL)selector {
    [self callFunctionInBackground:function withParameters:parameters block:^(id results, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:results object:error];
    }];
}

@end
