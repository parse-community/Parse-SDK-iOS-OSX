/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCloud.h"

#import <objc/runtime.h>

#if __has_include(<Bolts/BFTaskCompletionSource.h>)
#import <Bolts/BFTaskCompletionSource.h>
#else
#import "BFTaskCompletionSource.h"
#endif

#import "BFTask+Private.h"
#import "PFCloudCodeController.h"
#import "PFCommandResult.h"
#import "PFCoreManager.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

/**
 Cancels the calls that use the same cancellation token, with a single observer on the token.

 Bolts keeps the observers of a token until the token is deallocated,
 and disposing a token with more than 128 observers throws an exception.
 */
@interface PFCloudCallCanceller : NSObject

+ (instancetype)cancellerForToken:(BFCancellationToken *)cancellationToken;

- (void)addCallCancellationTokenSource:(BFCancellationTokenSource *)callCancellationTokenSource;
- (void)removeCallCancellationTokenSource:(BFCancellationTokenSource *)callCancellationTokenSource;

@end

@implementation PFCloud

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

+ (BFTask *)callFunctionInBackground:(NSString *)function
                      withParameters:(NSDictionary *)parameters
                   cancellationToken:(BFCancellationToken *)cancellationToken {
    if (!cancellationToken) {
        return [self callFunctionInBackground:function withParameters:parameters];
    }
    return [self _callFunctionInBackground:function withParameters:parameters cancellationToken:cancellationToken block:nil];
}

+ (void)callFunctionInBackground:(NSString *)function
                  withParameters:(NSDictionary *)parameters
               cancellationToken:(BFCancellationToken *)cancellationToken
                           block:(PFIdResultBlock)block {
    if (!cancellationToken) {
        [self callFunctionInBackground:function withParameters:parameters block:block];
        return;
    }
    [self _callFunctionInBackground:function withParameters:parameters cancellationToken:cancellationToken block:block];
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

/**
 Calls the function with a token of its own, which is cancelled when the given token is cancelled.
 The given token is not read anymore once the call has started.

 @return The task of the call, which is cancelled without waiting for the request if the given token is cancelled
 before the call completes.
 */
+ (BFTask *)_callFunctionInBackground:(NSString *)function
                       withParameters:(NSDictionary *)parameters
                    cancellationToken:(BFCancellationToken *)cancellationToken
                                block:(PFIdResultBlock)block {
    if (cancellationToken.cancellationRequested) {
        return [BFTask cancelledTask];
    }

    BFCancellationTokenSource *callCancellationTokenSource = [BFCancellationTokenSource cancellationTokenSource];
    BFCancellationToken *callCancellationToken = callCancellationTokenSource.token;
    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];
    __weak BFTaskCompletionSource *weakTaskCompletionSource = taskCompletionSource;
    [callCancellationToken registerCancellationObserverWithBlock:^{
        // Not on the cancelling thread, where continuations of the task could block it or deadlock
        BFTaskCompletionSource *strongTaskCompletionSource = weakTaskCompletionSource;
        [[BFExecutor defaultPriorityBackgroundExecutor] execute:^{
            [strongTaskCompletionSource trySetCancelled];
        }];
    }];

    PFCloudCallCanceller *canceller = [PFCloudCallCanceller cancellerForToken:cancellationToken];
    [canceller addCallCancellationTokenSource:callCancellationTokenSource];
    // Checked again, as the canceller doesn't cancel calls that are added after the token was cancelled
    if (cancellationToken.cancellationRequested) {
        [canceller removeCallCancellationTokenSource:callCancellationTokenSource];
        return [BFTask cancelledTask];
    }

    [[[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        PFCloudCodeController *controller = [Parse _currentManager].coreManager.cloudCodeController;
        return [controller callCloudCodeFunctionAsync:function
                                       withParameters:parameters
                                         sessionToken:sessionToken
                                    cancellationToken:callCancellationToken];
    } cancellationToken:callCancellationToken] continueWithBlock:^id(BFTask *task) {
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
    [[taskCompletionSource.task thenCallBackOnMainThreadAsync:block
                                            cancellationToken:callCancellationToken] continueWithBlock:^id(BFTask *task) {
        [canceller removeCallCancellationTokenSource:callCancellationTokenSource];
        return nil;
    }];
    return taskCompletionSource.task;
}

@end

///--------------------------------------
#pragma mark - Call Canceller
///--------------------------------------

@implementation PFCloudCallCanceller {
    NSMutableSet<BFCancellationTokenSource *> *_callCancellationTokenSources;
}

+ (instancetype)cancellerForToken:(BFCancellationToken *)cancellationToken {
    @synchronized(self) {
        PFCloudCallCanceller *canceller = objc_getAssociatedObject(cancellationToken, _cmd);
        if (!canceller) {
            canceller = [[self alloc] init];
            objc_setAssociatedObject(cancellationToken, _cmd, canceller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [cancellationToken registerCancellationObserverWithBlock:^{
                [canceller _cancelCalls];
            }];
        }
        return canceller;
    }
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _callCancellationTokenSources = [NSMutableSet set];

    return self;
}

- (void)addCallCancellationTokenSource:(BFCancellationTokenSource *)callCancellationTokenSource {
    @synchronized(self) {
        [_callCancellationTokenSources addObject:callCancellationTokenSource];
    }
}

- (void)removeCallCancellationTokenSource:(BFCancellationTokenSource *)callCancellationTokenSource {
    @synchronized(self) {
        [_callCancellationTokenSources removeObject:callCancellationTokenSource];
    }
}

- (void)_cancelCalls {
    NSArray<BFCancellationTokenSource *> *callCancellationTokenSources = nil;
    @synchronized(self) {
        callCancellationTokenSources = _callCancellationTokenSources.allObjects;
        [_callCancellationTokenSources removeAllObjects];
    }
    [callCancellationTokenSources makeObjectsPerformSelector:@selector(cancel)];
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
