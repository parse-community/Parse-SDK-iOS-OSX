/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFEventuallyQueue.h"
#import "PFEventuallyQueue_Private.h"

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFErrorUtilities.h"
#import "PFLogging.h"
#import "PFMacros.h"
#import "PFRESTCommand.h"
#import "PFTaskQueue.h"

#if !TARGET_OS_WATCH
#import "PFReachability.h"
#endif

NSUInteger const PFEventuallyQueueDefaultMaxAttemptsCount = 5;
NSTimeInterval const PFEventuallyQueueDefaultTimeoutRetryInterval = 600.0f;

@interface PFEventuallyQueue ()
#if !TARGET_OS_WATCH
<PFReachabilityListener>
#endif

@property (atomic, assign, readwrite) BOOL monitorsReachability;
@property (atomic, assign, getter=isRunning) BOOL running;

@end

@implementation PFEventuallyQueue

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource
                  maxAttemptsCount:(NSUInteger)attemptsCount
                     retryInterval:(NSTimeInterval)retryInterval {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;
    _maxAttemptsCount = attemptsCount;
    _retryInterval = retryInterval;

    // Set up all the queues
    NSString *queueBaseLabel = [NSString stringWithFormat:@"com.parse.%@", NSStringFromClass([self class])];

    _synchronizationQueue = dispatch_queue_create([NSString stringWithFormat:@"%@.synchronization", queueBaseLabel].UTF8String,
                                                  DISPATCH_QUEUE_SERIAL);
    PFMarkDispatchQueue(_synchronizationQueue);
    _synchronizationExecutor = [BFExecutor executorWithDispatchQueue:_synchronizationQueue];

    _processingQueue = dispatch_queue_create([NSString stringWithFormat:@"%@.processing", queueBaseLabel].UTF8String,
                                             DISPATCH_QUEUE_SERIAL);
    PFMarkDispatchQueue(_processingQueue);

    _processingQueueSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, _processingQueue);
    
    _commandEnqueueTaskQueue = [[PFTaskQueue alloc] init];

    _taskCompletionSources = [NSMutableDictionary dictionary];
    _testHelper = [[PFEventuallyQueueTestHelper alloc] init];

    [self _startMonitoringNetworkReachability];

    return self;
}

- (void)dealloc {
    [self _stopMonitoringNetworkReachability];
}

///--------------------------------------
#pragma mark - Enqueueing Commands
///--------------------------------------

- (BFTask *)enqueueCommandInBackground:(id<PFNetworkCommand>)command {
    return [self enqueueCommandInBackground:command withObject:nil];
}

- (BFTask *)enqueueCommandInBackground:(id<PFNetworkCommand>)command withObject:(PFObject *)object {
    PFParameterAssert(command, @"Cannot enqueue nil command.");

    BFTaskCompletionSource *taskCompletionSource = [BFTaskCompletionSource taskCompletionSource];

    @weakify(self);
    [_commandEnqueueTaskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
            @strongify(self);

            NSString *identifier = [self _newIdentifierForCommand:command];
            return [[[self _enqueueCommandInBackground:command
                                                object:object
                                            identifier:identifier] continueWithBlock:^id(BFTask *task) {
                if (task.faulted || task.cancelled) {
                    [self.testHelper notify:PFEventuallyQueueEventCommandNotEnqueued];
                    if (task.error) {
                        taskCompletionSource.error = task.error;
                    } else if (task.cancelled) {
                        [taskCompletionSource cancel];
                    }
                } else {
                    [self.testHelper notify:PFEventuallyQueueEventCommandEnqueued];
                }

                return task;
            }] continueWithExecutor:_synchronizationExecutor withSuccessBlock:^id(BFTask *task) {
                [self _didEnqueueCommand:command withIdentifier:identifier taskCompletionSource:taskCompletionSource];
                return nil;
            }];
        }];
    }];

    return taskCompletionSource.task;
}

- (BFTask *)_enqueueCommandInBackground:(id<PFNetworkCommand>)command
                                 object:(PFObject *)object
                             identifier:(NSString *)identifier {
    // This enforces implementing this method in subclasses
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)_didEnqueueCommand:(id<PFNetworkCommand>)command
            withIdentifier:(NSString *)identifier
      taskCompletionSource:(BFTaskCompletionSource *)taskCompletionSource {
    PFAssertIsOnDispatchQueue(_synchronizationQueue);

    _taskCompletionSources[identifier] = taskCompletionSource;
    dispatch_source_merge_data(_processingQueueSource, 1);

    if (_retryingSemaphore) {
        dispatch_semaphore_signal(_retryingSemaphore);
    }
}

///--------------------------------------
#pragma mark - Pending Commands
///--------------------------------------

- (NSArray *)_pendingCommandIdentifiers {
    return nil;
}

- (id<PFNetworkCommand>)_commandWithIdentifier:(NSString *)identifier error:(NSError **)error {
    return nil;
}

- (NSString *)_newIdentifierForCommand:(id<PFNetworkCommand>)command {
    return nil;
}

- (NSUInteger)commandCount {
    return [self _pendingCommandIdentifiers].count;
}

///--------------------------------------
#pragma mark - Controlling Queue
///--------------------------------------

- (void)start {
    dispatch_source_set_event_handler(_processingQueueSource, ^{
        [self _runCommands];
    });
    [self resume];
}

- (void)resume {
    if (self.running) {
        return;
    }
    self.running = YES;
    dispatch_resume(_processingQueueSource);
    dispatch_source_merge_data(_processingQueueSource, 1);
}

- (void)pause {
    if (!self.running) {
        return;
    }
    self.running = NO;
    dispatch_suspend(_processingQueueSource);
}

- (void)removeAllCommands {
    dispatch_sync(_synchronizationQueue, ^{
        [_taskCompletionSources removeAllObjects];
    });
}

///--------------------------------------
#pragma mark - Running Commands
///--------------------------------------

- (void)_runCommands {
    PFAssertIsOnDispatchQueue(_processingQueue);

    [self _runCommandsWithRetriesCount:self.maxAttemptsCount];
}

- (void)_runCommandsWithRetriesCount:(NSUInteger)retriesCount {
    PFAssertIsOnDispatchQueue(_processingQueue);

    if (!self.running || !self.connected) {
        return;
    }

    // Expect sorted result from _pendingCommandIdentifiers
    NSArray *commandIdentifiers = [self _pendingCommandIdentifiers];
    BOOL shouldRetry = NO;
    for (NSString *identifier in commandIdentifiers) {
        NSError *error = nil;
        id<PFNetworkCommand> command = [self _commandWithIdentifier:identifier error:&error];
        if (!command || error) {
            if (!error) {
                error = [PFErrorUtilities errorWithCode:kPFErrorInternalServer
                                                message:@"Failed to dequeue an eventually command."
                                              shouldLog:NO];
            }
            BFTask *task = [BFTask taskWithError:error];
            [self _didFinishRunningCommand:command withIdentifier:identifier resultTask:task];
            continue;
        }

        __block BFTaskCompletionSource *taskCompletionSource = nil;
        dispatch_sync(_synchronizationQueue, ^{
            taskCompletionSource = _taskCompletionSources[identifier];
        });

        BFTask *resultTask = nil;
        PFCommandResult *result = nil;
        @try {
            resultTask = [self _runCommand:command withIdentifier:identifier];
            result = [resultTask waitForResult:&error];
        }
        @catch (NSException *exception) {
            error = [NSError errorWithDomain:PFParseErrorDomain
                                        code:kPFErrorInvalidPointer
                                    userInfo:@{ @"message" : @"Failed to run an eventually command.",
                                                @"exception" : exception }];
            resultTask = [BFTask taskWithError:error];
        }

        if (error) {
            BOOL permanent = (![error.userInfo[@"temporary"] boolValue] &&
                              ([error.domain isEqualToString:PFParseErrorDomain] ||
                               error.code != kPFErrorConnectionFailed));

            if (!permanent) {
                PFLogWarning(PFLoggingTagCommon,
                             @"Attempt at runEventually command timed out. Waiting %f seconds. %d retries remaining.",
                             self.retryInterval,
                             (int)retriesCount);

                __block dispatch_semaphore_t semaphore = NULL;
                dispatch_sync(_synchronizationQueue, ^{
                    _retryingSemaphore = dispatch_semaphore_create(0);
                    semaphore = _retryingSemaphore;
                });

                dispatch_time_t timeoutTime = dispatch_time(DISPATCH_TIME_NOW,
                                                            (int64_t)(self.retryInterval * NSEC_PER_SEC));

                long waitResult = dispatch_semaphore_wait(semaphore, timeoutTime);
                dispatch_sync(_synchronizationQueue, ^{
                    _retryingSemaphore = NULL;
                });

                if (waitResult == 0) {
                    // We haven't waited long enough, but if we lost the connection, or should stop, just quit.
                    return;
                }

                // We need to go out of the loop.
                if (retriesCount > 0) {
                    shouldRetry = YES;
                    break;
                }
            }

            PFLogError(PFLoggingTagCommon, @"Failed to run command eventually with error: %@", error);
        }

        // Post processing shouldn't make the queue retry the command.
        resultTask = [self _didFinishRunningCommand:command withIdentifier:identifier resultTask:resultTask];
        [resultTask waitForResult:nil];

        // Notify anyone waiting that the operation is completed.
        if (resultTask.error) {
            taskCompletionSource.error = resultTask.error;
        } else if (resultTask.cancelled) {
            [taskCompletionSource cancel];
        } else {
            taskCompletionSource.result = resultTask.result;
        }
    }

    // Retry here so that we're in cleaner state.
    if (shouldRetry) {
        return [self _runCommandsWithRetriesCount:(retriesCount - 1)];
    }
}

- (BFTask *)_runCommand:(id<PFNetworkCommand>)command withIdentifier:(NSString *)identifier {
    if ([command isKindOfClass:[PFRESTCommand class]]) {
        return [self.dataSource.commandRunner runCommandAsync:(PFRESTCommand *)command withOptions:0];
    }

    NSError *error = [PFErrorUtilities errorWithCode:kPFErrorInternalServer
                                             message:[NSString stringWithFormat:@"Can't find a compatible runner for command %@.", command]
                                           shouldLog:NO];
    return [BFTask taskWithError:error];
}

- (BFTask *)_didFinishRunningCommand:(id<PFNetworkCommand>)command
                      withIdentifier:(NSString *)identifier
                          resultTask:(BFTask *)resultTask {
    PFConsistencyAssert(resultTask.completed, @"Task should be completed.");

    dispatch_sync(_synchronizationQueue, ^{
        [_taskCompletionSources removeObjectForKey:identifier];
    });

    if (resultTask.faulted || resultTask.cancelled) {
        [self.testHelper notify:PFEventuallyQueueEventCommandFailed];
    } else {
        [self.testHelper notify:PFEventuallyQueueEventCommandSucceded];
    }

    return resultTask;
}

- (BFTask *)_waitForOperationSet:(PFOperationSet *)operationSet
                   eventuallyPin:(PFEventuallyPin *)eventuallyPin {
    return [BFTask taskWithResult:nil];
}

///--------------------------------------
#pragma mark - Reachability
///--------------------------------------

- (void)_startMonitoringNetworkReachability {
#if TARGET_OS_WATCH
    self.connected = YES;
#else
    if (self.monitorsReachability) {
        return;
    }
    self.monitorsReachability = YES;

    [[PFReachability sharedParseReachability] addListener:self];

    // Set the initial connected status
    self.connected = ([PFReachability sharedParseReachability].currentState != PFReachabilityStateNotReachable);
#endif
}

- (void)_stopMonitoringNetworkReachability {
#if !TARGET_OS_WATCH
    if (!self.monitorsReachability) {
        return;
    }

    [[PFReachability sharedParseReachability] removeListener:self];

    self.monitorsReachability = NO;
    self.connected = YES;
#endif
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

/** Manually sets the network connection status. */
- (void)setConnected:(BOOL)connected {
    BFTaskCompletionSource *barrier = [BFTaskCompletionSource taskCompletionSource];
    dispatch_async(_processingQueue, ^{
        dispatch_sync(_synchronizationQueue, ^{
            if (self.connected != connected) {
                _connected = connected;
                if (connected) {
                    dispatch_source_merge_data(_processingQueueSource, 1);
                }
            }
        });
        barrier.result = nil;
    });
    if (connected) {
        dispatch_async(_synchronizationQueue, ^{
            if (_retryingSemaphore) {
                dispatch_semaphore_signal(_retryingSemaphore);
            }
        });
    }
    [barrier.task waitForResult:nil];
}

///--------------------------------------
#pragma mark - Test Helper Method
///--------------------------------------

/** Makes this command cache forget all the state it keeps during a single run of the app. */
- (void)_simulateReboot {
    // Make sure there is no command pending enqueuing
    [[[[_commandEnqueueTaskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return toAwait;
    }] continueWithExecutor:_synchronizationExecutor withBlock:^id(BFTask *task) {
        // Remove all state task completion sources
        [_taskCompletionSources removeAllObjects];
        return nil;
    }] continueWithExecutor:[BFExecutor executorWithDispatchQueue:_processingQueue] withBlock:^id(BFTask *task) {
        // Let all operations in the queue run at least once
        return nil;
    }] waitUntilFinished];
}

/** Test helper to return how many commands are being retained in memory by the cache. */
- (int)_commandsInMemory {
    return (int)_taskCompletionSources.count;
}

/** Called by PFObject whenever an object has been updated after a saveEventually. */
- (void)_notifyTestHelperObjectUpdated {
    [self.testHelper notify:PFEventuallyQueueEventObjectUpdated];
}

- (void)_setMaxAttemptsCount:(NSUInteger)attemptsCount {
    _maxAttemptsCount = attemptsCount;
}

- (void)_setRetryInterval:(NSTimeInterval)retryInterval {
    _retryInterval = retryInterval;
}

#if !TARGET_OS_WATCH

///--------------------------------------
#pragma mark - Reachability
///--------------------------------------

- (void)reachability:(PFReachability *)reachability didChangeReachabilityState:(PFReachabilityState)state {
    if (self.monitorsReachability) {
        self.connected = (state != PFReachabilityStateNotReachable);
    }
}

#endif

@end

// PFEventuallyQueueTestHelper gets notifications of various events happening in the command cache,
// so that tests can be synchronized. See CommandTests.m for examples of how to use this.

@implementation PFEventuallyQueueTestHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        [self clear];
    }
    return self;
}

- (void)clear {
    for (int i = 0; i < PFEventuallyQueueEventCount; ++i) {
        events[i] = dispatch_semaphore_create(0);
    }
}

- (void)notify:(PFEventuallyQueueTestHelperEvent)event {
    dispatch_semaphore_signal(events[event]);
}

- (BOOL)waitFor:(PFEventuallyQueueTestHelperEvent)event {
    // Wait 1 second for a permit from the semaphore.
    return (dispatch_semaphore_wait(events[event], dispatch_time(DISPATCH_TIME_NOW, 10LL * NSEC_PER_SEC)) == 0);
}

@end
