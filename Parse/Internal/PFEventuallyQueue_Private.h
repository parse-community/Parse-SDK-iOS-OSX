/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFEventuallyQueue.h"

@class BFExecutor;
@class PFEventuallyPin;
@class PFObject;
@class PFOperationSet;
@class PFTaskQueue;

extern NSUInteger const PFEventuallyQueueDefaultMaxAttemptsCount;
extern NSTimeInterval const PFEventuallyQueueDefaultTimeoutRetryInterval;

@class BFTaskCompletionSource;

@interface PFEventuallyQueue ()
{
@protected
    BFExecutor *_synchronizationExecutor;
    dispatch_queue_t _synchronizationQueue;

@private
    dispatch_queue_t _processingQueue;
    dispatch_source_t _processingQueueSource;

    dispatch_semaphore_t _retryingSemaphore;

    NSMutableDictionary *_taskCompletionSources;

    /**
     Task queue that will enqueue command enqueueing task so that we enqueue the command
     one at a time.
     */
    PFTaskQueue *_commandEnqueueTaskQueue;
}

@property (nonatomic, assign, readwrite, getter=isConnected) BOOL connected;

/**
 This method is used to do some work after the command is finished running and
 either succeeded or dropped from queue with error/exception.

 @param command    Command that was run.
 @param identifier Unique identifier of the command
 @param resultTask Task that represents the result of running a command.
 @return A continuation task in case the EventuallyQueue need to do something.
 Typically this will return back given resultTask.
 */
- (BFTask *)_didFinishRunningCommand:(id<PFNetworkCommand>)command
                      withIdentifier:(NSString *)identifier
                          resultTask:(BFTask *)resultTask;

///--------------------------------------
#pragma mark - Reachability
///--------------------------------------

- (void)_startMonitoringNetworkReachability;
- (void)_stopMonitoringNetworkReachability;

///--------------------------------------
#pragma mark - Test Helper
///--------------------------------------

- (void)_setMaxAttemptsCount:(NSUInteger)attemptsCount;

- (void)_setRetryInterval:(NSTimeInterval)retryInterval;

- (void)_simulateReboot NS_REQUIRES_SUPER;

- (int)_commandsInMemory;

- (void)_notifyTestHelperObjectUpdated;

@end

@protocol PFEventuallyQueueSubclass <NSObject>

///--------------------------------------
#pragma mark - Pending Commands
///--------------------------------------


/**
 Generates a new identifier for a command so that it can be sorted later by this identifier.
 */
- (NSString *)_newIdentifierForCommand:(id<PFNetworkCommand>)command;

/**
 This method is triggered on batch processing of the queue.
 It will capture the identifiers and use them to execute commands.

 @return An array of identifiers of all commands that are pending sorted by the order they're enqueued.
 */
- (NSArray *)_pendingCommandIdentifiers;

/**
 This method should return a command for a given identifier.

 @param identifier An identifier of a command, that was in array returned by <_pendingCommandIdentifiers>
 @param error      Pointer to `NSError *` that should be set if the method failed to construct/retrieve a command.

 @return A command that needs to be run, or `nil` if there was an error.
 */
- (id<PFNetworkCommand>)_commandWithIdentifier:(NSString *)identifier error:(NSError **)error;

///--------------------------------------
#pragma mark - Running Commands
///--------------------------------------

/**
 This method serves as a way to do any kind of work to enqueue a command properly.
 If the task fails with an error/exception or is cancelled - execution won't start.

 @param command              Command that needs to be enqueued
 @param object               The object on which the command is run against.
 @param identifier           Unique identifier used to represent a command.
 @return Task that is resolved when the command is complete enqueueing.
 */
- (BFTask *)_enqueueCommandInBackground:(id<PFNetworkCommand>)command
                                 object:(PFObject *)object
                             identifier:(NSString *)identifier;

- (BFTask *)_waitForOperationSet:(PFOperationSet *)operationSet
                   eventuallyPin:(PFEventuallyPin *)eventuallyPin;

@end
