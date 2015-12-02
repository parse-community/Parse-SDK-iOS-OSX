/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPinningEventuallyQueue.h"

#import <Bolts/BFExecutor.h>
#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFErrorUtilities.h"
#import "PFEventuallyPin.h"
#import "PFEventuallyQueue_Private.h"
#import "PFMacros.h"
#import "PFObjectPrivate.h"
#import "PFOperationSet.h"
#import "PFRESTCommand.h"
#import "PFTaskQueue.h"

@interface PFPinningEventuallyQueue () <PFEventuallyQueueSubclass> {
    /**
     Queue for reading/writing eventually operations from LDS. Makes all reads/writes atomic
     operations.
     */
    PFTaskQueue *_taskQueue;

    /**
     List of `PFEventuallyPin.uuid` that are currently queued in `_processingQueue`. This contains
     uuid of PFEventuallyPin that's enqueued.
     */
    NSMutableArray *_eventuallyPinUUIDQueue;

    /**
     Map of eventually operation UUID to matching PFEventuallyPin. This contains PFEventuallyPin
     that's enqueued.
     */
    NSMutableDictionary *_uuidToEventuallyPin;

    /**
     Map OperationSetUUID to PFOperationSet
     */
    NSMutableDictionary *_operationSetUUIDToOperationSet;

    /**
     Map OperationSetUUID to PFEventuallyPin
     */
    NSMutableDictionary *_operationSetUUIDToEventuallyPin;
}

@end

@implementation PFPinningEventuallyQueue

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)newDefaultPinningEventuallyQueueWithCommandRunner:(id<PFCommandRunning>)commandRunner {
    PFPinningEventuallyQueue *queue = [[self alloc] initWithCommandRunner:commandRunner
                                                         maxAttemptsCount:PFEventuallyQueueDefaultMaxAttemptsCount
                                                            retryInterval:PFEventuallyQueueDefaultTimeoutRetryInterval];
    [queue start];
    return queue;
}

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithCommandRunner:(id<PFCommandRunning>)commandRunner
                     maxAttemptsCount:(NSUInteger)attemptsCount
                        retryInterval:(NSTimeInterval)retryInterval {
    self = [super initWithCommandRunner:commandRunner maxAttemptsCount:attemptsCount retryInterval:retryInterval];
    if (!self) return nil;

    _taskQueue = [[PFTaskQueue alloc] init];

    dispatch_sync(_synchronizationQueue, ^{
        _eventuallyPinUUIDQueue = [NSMutableArray array];
        _uuidToEventuallyPin = [NSMutableDictionary dictionary];
        _operationSetUUIDToOperationSet = [NSMutableDictionary dictionary];
        _operationSetUUIDToEventuallyPin = [NSMutableDictionary dictionary];
    });

    // Populate Eventually Pin to make sure we pre-loaded any existing data.
    [self _populateEventuallyPinAsync];

    return self;
}

///--------------------------------------
#pragma mark - Controlling Queue
///--------------------------------------

- (void)removeAllCommands {
    [super removeAllCommands];

    BFTask *removeTask = [_taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [toAwait continueWithBlock:^id(BFTask *task) {
            return [[PFEventuallyPin findAllEventuallyPin] continueWithSuccessBlock:^id(BFTask *task) {
                NSArray *eventuallyPins = task.result;
                NSMutableArray *unpinTasks = [NSMutableArray array];

                for (PFEventuallyPin *eventuallyPin in eventuallyPins) {
                    [unpinTasks addObject:[eventuallyPin unpinInBackgroundWithName:PFEventuallyPinPinName]];
                }

                return [BFTask taskForCompletionOfAllTasks:unpinTasks];
            }];
        }];
    }];

    [removeTask waitForResult:nil];
    // Clear in-memory data
    dispatch_sync(_synchronizationQueue, ^{
        [_eventuallyPinUUIDQueue removeAllObjects];
        [_uuidToEventuallyPin removeAllObjects];
        [_operationSetUUIDToEventuallyPin removeAllObjects];
        [_operationSetUUIDToOperationSet removeAllObjects];
    });
}

- (void)_simulateReboot {
    [super _simulateReboot];

    [_eventuallyPinUUIDQueue removeAllObjects];
    [_uuidToEventuallyPin removeAllObjects];
    [_operationSetUUIDToEventuallyPin removeAllObjects];
    [_operationSetUUIDToOperationSet removeAllObjects];

    [self _populateEventuallyPinAsync];
}

///--------------------------------------
#pragma mark - PFEventuallyQueueSubclass
///--------------------------------------

- (NSString *)_newIdentifierForCommand:(id<PFNetworkCommand>)command {
    return [[NSUUID UUID] UUIDString];
}

- (NSArray *)_pendingCommandIdentifiers {
    [[self _populateEventuallyPinAsync] waitForResult:nil];

    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        PFEventuallyPin *pin = _uuidToEventuallyPin[evaluatedObject];
        // Filter out all pins that don't have `operationSet` data ready yet
        // to make sure we send the command with all the changes.
        if (pin.operationSetUUID) {
            return (_operationSetUUIDToEventuallyPin[pin.operationSetUUID] != nil);
        }
        return YES;
    }];
    return [_eventuallyPinUUIDQueue filteredArrayUsingPredicate:predicate];
}

- (id<PFNetworkCommand>)_commandWithIdentifier:(NSString *)identifier error:(NSError **)error {
    // Should be populated by `_pendingCommandIdentifiers`
    PFEventuallyPin *eventuallyPin = _uuidToEventuallyPin[identifier];

    // TODO (hallucinogen): this is a temporary hack. We need to change this to match the Android one.
    // We need to construct the command just right when we want to execute it. Or else it will ask for localId
    // when there's unsaved child.
    switch (eventuallyPin.type) {
        case PFEventuallyPinTypeSave: {
            PFOperationSet *operationSet = _operationSetUUIDToOperationSet[eventuallyPin.operationSetUUID];
            return [eventuallyPin.object _constructSaveCommandForChanges:operationSet
                                                            sessionToken:eventuallyPin.sessionToken
                                                           objectEncoder:[PFPointerObjectEncoder objectEncoder]];
        }
        case PFEventuallyPinTypeDelete:
            return [eventuallyPin.object _currentDeleteCommandWithSessionToken:eventuallyPin.sessionToken];
        case PFEventuallyPinTypeCommand:
        default:
            break;
    }

    id<PFNetworkCommand> command = eventuallyPin.command;
    if (!command && error) {
        *error = [PFErrorUtilities errorWithCode:kPFErrorInternalServer
                                        message:@"Failed to construct eventually command from cache."
                                      shouldLog:NO];
    }
    return command;
}

- (BFTask *)_enqueueCommandInBackground:(id<PFNetworkCommand>)command
                                 object:(PFObject *)object
                             identifier:(NSString *)identifier {
    return [_taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [toAwait continueAsyncWithBlock:^id(BFTask *task){
            return [PFEventuallyPin pinEventually:object forCommand:command withUUID:identifier];
        }];
    }];
}

- (BFTask *)_didFinishRunningCommand:(id<PFNetworkCommand>)command
                      withIdentifier:(NSString *)identifier
                          resultTask:(BFTask *)resultTask {
    // Delete the commands regardless, even if it failed. Otherwise we'll just keep trying it forever.
    // We don't need to wait for taskQueue since it will not be queued again since this
    // PFEventuallyPin is still in `_eventuallyPinUUIDQueue`
    PFEventuallyPin *eventuallyPin = _uuidToEventuallyPin[identifier];
    BFTask *unpinTask = [eventuallyPin unpinInBackgroundWithName:PFEventuallyPinPinName];
    unpinTask = [unpinTask continueWithBlock:^id(BFTask *task) {
        // Remove data from memory.
        dispatch_sync(_synchronizationQueue, ^{
            [_uuidToEventuallyPin removeObjectForKey:identifier];
            [_eventuallyPinUUIDQueue removeObject:identifier];
        });

        if (resultTask.cancelled || resultTask.exception || resultTask.error) {
            return resultTask;
        }

        if (eventuallyPin.operationSetUUID) {
            // Remove only if the operation succeeded
            dispatch_sync(_synchronizationQueue, ^{
                [_operationSetUUIDToOperationSet removeObjectForKey:eventuallyPin.operationSetUUID];
                [_operationSetUUIDToEventuallyPin removeObjectForKey:eventuallyPin.operationSetUUID];
            });
        }

        PFCommandResult *commandResult = resultTask.result;
        switch (eventuallyPin.type) {
            case PFEventuallyPinTypeSave: {

                task = [task continueWithBlock:^id(BFTask *task) {
                    return [eventuallyPin.object handleSaveResultAsync:commandResult.result];
                }];
                break;
            }
            case PFEventuallyPinTypeDelete: {
                task = [task continueWithBlock:^id(BFTask *task) {
                    PFObject *object = eventuallyPin.object;
                    id<PFObjectControlling> controller = [[object class] objectController];
                    return [controller processDeleteResultAsync:commandResult.result forObject:object];
                }];
                break;
            }
            case PFEventuallyPinTypeCommand:
            default:
                break;
        }

        return task;
    }];

    // Notify event listener that we finished running.
    return [[super _didFinishRunningCommand:command
                             withIdentifier:identifier
                                 resultTask:resultTask] continueWithBlock:^id(BFTask *task) {
        return unpinTask;
    }];
}

/**
 Synchronizes PFObject taskQueue (Many) and PFPinningEventuallyQueue taskQueue (None). Each queue will be held
 until both are ready, matched on operationSetUUID. Once both are ready, the eventually task will run.
 */
- (BFTask *)_waitForOperationSet:(PFOperationSet *)operationSet eventuallyPin:(PFEventuallyPin *)eventuallyPin {
    if (eventuallyPin != nil && eventuallyPin.type != PFEventuallyPinTypeSave) {
        // If not save, then we don't have to do anything special.
        return [BFTask taskWithResult:nil];
    }

    // TODO (hallucinogen): actually wait for PFObject taskQueue and PFPinningEventually taskQueue

    __block NSString *uuid = nil;
    dispatch_sync(_synchronizationQueue, ^{
        if (operationSet != nil) {
            uuid = operationSet.uuid;
            _operationSetUUIDToOperationSet[uuid] = operationSet;
        }
        if (eventuallyPin != nil) {
            uuid = eventuallyPin.operationSetUUID;
            _operationSetUUIDToEventuallyPin[uuid] = eventuallyPin;
        }
    });
    if (uuid == nil) {
        NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                         reason:@"Either operationSet or eventuallyPin must be set"
                                                       userInfo:nil];
        return [BFTask taskWithException:exception];
    }
    return [BFTask taskWithResult:nil];
}

///--------------------------------------
#pragma mark - Eventually Pin
///--------------------------------------

- (BFTask *)_populateEventuallyPinAsync {
    return [_taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [[toAwait continueWithBlock:^id(BFTask *task) {
            return [PFEventuallyPin findAllEventuallyPinWithExcludeUUIDs:_eventuallyPinUUIDQueue];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            NSArray *eventuallyPins = task.result;

            for (PFEventuallyPin *eventuallyPin in eventuallyPins) {
                // If it's enqueued already, we don't need to run it again.
                if ([_eventuallyPinUUIDQueue containsObject:eventuallyPin.operationSetUUID]) {
                    continue;
                }

                // Make sure the data is in memory.
                dispatch_sync(_synchronizationQueue, ^{
                    [_eventuallyPinUUIDQueue addObject:eventuallyPin.uuid];
                    _uuidToEventuallyPin[eventuallyPin.uuid] = eventuallyPin;
                });

                // For now we don't care whether this will fail or not.
                [[self _waitForOperationSet:nil eventuallyPin:eventuallyPin] waitForResult:nil];
            }

            return task;
        }];
    }];
}

@end
