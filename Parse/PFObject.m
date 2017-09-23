/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObject.h"
#import "PFObject+Subclass.h"
#import "PFObject+Synchronous.h"
#import "PFObject+Deprecated.h"
#import "PFObjectSubclassingController.h"

#import <objc/message.h>
#import <objc/objc-sync.h>
#import <objc/runtime.h>

#import <Bolts/BFTaskCompletionSource.h>

#import "BFTask+Private.h"
#import "PFACLPrivate.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFConstants.h"
#import "PFCoreManager.h"
#import "PFCurrentUserController.h"
#import "PFDateFormatter.h"
#import "PFDecoder.h"
#import "PFEncoder.h"
#import "PFErrorUtilities.h"
#import "PFEventuallyQueue_Private.h"
#import "PFFileManager.h"
#import "PFFile_Private.h"
#import "PFJSONSerialization.h"
#import "PFLogging.h"
#import "PFMacros.h"
#import "PFMultiProcessFileLockController.h"
#import "PFMutableObjectState.h"
#import "PFObjectBatchController.h"
#import "PFObjectConstants.h"
#import "PFObjectController.h"
#import "PFObjectEstimatedData.h"
#import "PFObjectFileCodingLogic.h"
#import "PFObjectFilePersistenceController.h"
#import "PFObjectLocalIdStore.h"
#import "PFObjectUtilities.h"
#import "PFOfflineStore.h"
#import "PFOperationSet.h"
#import "PFPin.h"
#import "PFPinningObjectStore.h"
#import "PFQueryPrivate.h"
#import "PFRESTObjectBatchCommand.h"
#import "PFRESTObjectCommand.h"
#import "PFRelation.h"
#import "PFRelationPrivate.h"
#import "PFSubclassing.h"
#import "PFTaskQueue.h"
#import "ParseInternal.h"
#import "Parse_Private.h"

/**
 Checks if an object can be used as a value for PFObject.
 */
static void PFObjectAssertValueIsKindOfValidClass(id object) {
    static NSArray *classes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classes = @[ [NSDictionary class], [NSArray class],
                     [NSString class], [NSNumber class], [NSNull class], [NSDate class], [NSData class],
                     [PFObject class], [PFFile class], [PFACL class], [PFGeoPoint class] ];
    });

    for (Class class in classes) {
        if ([object isKindOfClass:class]) {
            return;
        }
    }

    PFParameterAssertionFailure(@"PFObject values may not have class: %@", [object class]);
}

@interface PFObject () <PFObjectPrivateSubclass> {
    // A lock for accessing any of the internal state of this object.
    // Guards basically all of the variables below.
    NSObject *lock;

    PFObjectState *_pfinternal_state;

    PFObjectEstimatedData *_estimatedData;
    NSMutableSet *_availableKeys; // TODO: (nlutsenko) Maybe decouple this further.

    // TODO (grantland): Derive this off the EventuallyPins as opposed to +/- count.
    NSUInteger _deletingEventuallyCount;

    NSString *localId;

    // This queue is used to guarantee the order of *Eventually commands
    // and offload all the work to the background thread
    PFTaskQueue *_eventuallyTaskQueue;
}

@property (nonatomic, strong, readwrite) NSString *localId;

@property (nonatomic, strong, readwrite) PFTaskQueue *taskQueue;

+ (void)assertSubclassIsRegistered:(Class)subclass;

@end

@implementation PFObject (Private)

+ (void)unregisterSubclass:(Class<PFSubclassing>)subclass {
    [[self subclassingController] unregisterSubclass:subclass];
}

/**
 Returns the object that should be used to synchronize all internal data access.
 */
- (NSObject *)lock {
    return lock;
}

/**
 Blocks until all outstanding operations have completed.
 */
- (void)waitUntilFinished {
    [[self.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return toAwait;
    }] waitForResult:nil];
}

/**
 For operations that need to be put into multiple objects queues, like saveAll
 and fetchAll, this method does the nasty work.
 @param taskStart - A block that is called when all of the objects are ready.
 It can return a promise that all of the queues will then wait on.
 @param objects - The objects that this operation affects.
 @return - Returns a promise that is fulfilled once the promise returned by the
 block is fulfilled.
 */
+ (BFTask *)_enqueue:(BFTask *(^)(BFTask *toAwait))taskStart forObjects:(NSArray *)objects {
    // The task that will be complete when all of the child queues indicate they're ready to start.
    BFTaskCompletionSource *readyToStart = [BFTaskCompletionSource taskCompletionSource];

    // First, we need to lock the mutex for the queue for every object. We have to hold this
    // from at least when taskStart() is called to when obj.taskQueue enqueue is called, so
    // that saves actually get executed in the order they were setup by taskStart().
    // The locks have to be sorted so that we always acquire them in the same order.
    // Otherwise, there's some risk of deadlock.
    NSMutableArray *mutexes = [NSMutableArray array];
    for (PFObject *obj in objects) {
        [mutexes addObject:obj.taskQueue.mutex];
    }
    [mutexes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        void *lock1 = (__bridge void *)obj1;
        void *lock2 = (__bridge void *)obj2;
        return lock1 - lock2;
    }];
    for (NSObject *lock in mutexes) {
        objc_sync_enter(lock);
    }

    @try {
        // The task produced by taskStart. By running this immediately, we allow everything prior
        // to toAwait to run before waiting for all of the queues on all of the objects.
        BFTask *fullTask = taskStart(readyToStart.task);

        // Add fullTask to each of the objects' queues.
        NSMutableArray *childTasks = [NSMutableArray array];
        for (PFObject *obj in objects) {
            [obj.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
                [childTasks addObject:toAwait];
                return fullTask;
            }];
        }

        // When all of the objects' queues are ready, signal fullTask that it's ready to go on.
        [[BFTask taskForCompletionOfAllTasks:childTasks] continueWithBlock:^id(BFTask *task) {
            readyToStart.result = nil;
            return nil;
        }];

        return fullTask;

    } @finally {
        for (NSObject *lock in mutexes) {
            objc_sync_exit(lock);
        }
    }
}

///--------------------------------------
#pragma mark - Children helpers
///--------------------------------------

/**
 Finds all of the objects that are reachable from child, including child itself,
 and adds them to the given mutable array.  It traverses arrays and json objects.
 @param node  An kind object to search for children.
 @param dirtyChildren  The array to collect the result into.
 @param seen  The set of all objects that have already been seen.
 @param seenNew  The set of new objects that have already been seen since the
 last existing object.
 */
+ (void)collectDirtyChildren:(id)node
                    children:(NSMutableSet *)dirtyChildren
                       files:(NSMutableSet *)dirtyFiles
                        seen:(NSSet *)seen
                     seenNew:(NSSet *)seenNew
                 currentUser:(PFUser *)currentUser {
    if ([node isKindOfClass:[NSArray class]]) {
        for (id elem in node) {
            @autoreleasepool {
                [self collectDirtyChildren:elem
                                  children:dirtyChildren
                                     files:dirtyFiles
                                      seen:seen
                                   seenNew:seenNew
                               currentUser:currentUser];
            }
        }
    } else if ([node isKindOfClass:[NSDictionary class]]) {
        [node enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [self collectDirtyChildren:obj
                              children:dirtyChildren
                                 files:dirtyFiles
                                  seen:seen
                               seenNew:seenNew
                           currentUser:currentUser];
        }];
    } else if ([node isKindOfClass:[PFACL class]]) {
        PFACL *acl = (PFACL *)node;
        if ([acl hasUnresolvedUser]) {
            [self collectDirtyChildren:currentUser
                              children:dirtyChildren
                                 files:dirtyFiles
                                  seen:seen
                               seenNew:seenNew
                           currentUser:currentUser];
        }

    } else if ([node isKindOfClass:[PFObject class]]) {
        PFObject *object = (PFObject *)node;
        NSDictionary *toSearch = nil;

        @synchronized ([object lock]) {
            // Check for cycles of new objects.  Any such cycle means it will be
            // impossible to save this collection of objects, so throw an exception.
            if (object.objectId) {
                seenNew = [NSSet set];
            } else {
                if ([seenNew containsObject:object]) {
                    PFConsistencyAssertionFailure(@"Found a circular dependency when saving.");
                }
                seenNew = [seenNew setByAddingObject:object];
            }

            // Check for cycles of any object.  If this occurs, then there's no
            // problem, but we shouldn't recurse any deeper, because it would be
            // an infinite recursion.
            if ([seen containsObject:object]) {
                return;
            }
            seen = [seen setByAddingObject:object];

            // Recurse into this object's children looking for dirty children.
            // We only need to look at the child object's current estimated data,
            // because that's the only data that might need to be saved now.
            toSearch = [object._estimatedData.dictionaryRepresentation copy];
        }

        [self collectDirtyChildren:toSearch
                          children:dirtyChildren
                             files:dirtyFiles
                              seen:seen
                           seenNew:seenNew
                       currentUser:currentUser];

        if ([object isDirty:NO]) {
            [dirtyChildren addObject:object];
        }
    } else if ([node isKindOfClass:[PFFile class]]) {
        PFFile *file = (PFFile *)node;
        if (!file.url) {
            [dirtyFiles addObject:node];
        }
    }
}

// Helper version of collectDirtyChildren:children:seen:seenNew so that callers
// don't have to add the internally used parameters.
+ (void)collectDirtyChildren:(id)child
                    children:(NSMutableSet *)dirtyChildren
                       files:(NSMutableSet *)dirtyFiles
                 currentUser:(PFUser *)currentUser {
    [self collectDirtyChildren:child
                      children:dirtyChildren
                         files:dirtyFiles
                          seen:[NSSet set]
                       seenNew:[NSSet set]
                   currentUser:currentUser];
}

// Returns YES if the given object can be serialized for saving as a value
// that is pointed to by a PFObject.
// @param value  The object we want to serialize as a value.
// @param saved  The set of all objects we can assume will be saved before this one.
// @param error  The reason why it can't be serialized.
+ (BOOL)canBeSerializedAsValue:(id)value
                   afterSaving:(NSMutableArray *)saved
                         error:(NSError * __autoreleasing *)error {
    if ([value isKindOfClass:[PFObject class]]) {
        PFObject *object = (PFObject *)value;
        if (!object.objectId && ![saved containsObject:object]) {
            if (error) {
                *error = [PFErrorUtilities errorWithCode:kPFErrorInvalidPointer
                                                 message:@"Pointer to an unsaved object."];
            }
            return NO;
        }

    } else if ([value isKindOfClass:[NSDictionary class]]) {
        __block BOOL retValue = YES;
        [value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if (![[self class] canBeSerializedAsValue:obj
                                          afterSaving:saved
                                                error:error]) {
                retValue = NO;
                *stop = YES;
            }
        }];
        return retValue;
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)value;
        for (NSString *item in array) {
            if (![[self class] canBeSerializedAsValue:item
                                          afterSaving:saved
                                                error:error]) {
                return NO;
            }
        }
    }

    return YES;
}

// Returns YES if this object can be serialized for saving.
// @param saved A set of objects that we can assume will have been saved.
// @param error The reason why it can't be serialized.
- (BOOL)canBeSerializedAfterSaving:(NSMutableArray *)saved withCurrentUser:(PFUser *)user error:(NSError **)error {
    @synchronized (lock) {
        // This method is only used for batching sets of objects for saveAll
        // and when saving children automatically. Since it's only used to
        // determine whether or not save should be called on them, it only
        // needs to examine their current values, so we use estimatedData.
        if (![[self class] canBeSerializedAsValue:_estimatedData.dictionaryRepresentation
                                      afterSaving:saved
                                            error:error]) {
            return NO;
        }

        if ([self isDataAvailableForKey:@"ACL"] &&
            [[self ACLWithoutCopying] hasUnresolvedUser] &&
            ![saved containsObject:user]) {
            if (error) {
                *error = [PFErrorUtilities errorWithCode:kPFErrorInvalidACL
                                                 message:@"User associated with ACL must be signed up."];
            }
            return NO;
        }

        return YES;
    }
}

// This saves all of the objects and files reachable from the given object.
// It does its work in multiple waves, saving as many as possible in each wave.
// If there's ever an error, it just gives up, sets error, and returns NO;
+ (BFTask *)_deepSaveAsyncChildrenOfObject:(id)object withCurrentUser:(PFUser *)currentUser sessionToken:(NSString *)sessionToken {
    NSMutableSet *uniqueObjects = [NSMutableSet set];
    NSMutableSet *uniqueFiles = [NSMutableSet set];
    [self collectDirtyChildren:object children:uniqueObjects files:uniqueFiles currentUser:currentUser];
    // Remove object from the queue of objects to save as this method should only save children.
    if ([object isKindOfClass:[PFObject class]]) {
        [uniqueObjects removeObject:object];
    }

    BFTask *task = [BFTask taskWithResult:@YES];
    for (PFFile *file in uniqueFiles) {
        task = [task continueAsyncWithSuccessBlock:^id(BFTask *task) {
            return [[file saveInBackground] continueAsyncWithBlock:^id(BFTask *task) {
                // This is a stupid hack because our current behavior is to fail file
                // saves with an error when a file save inside it is cancelled.
                if (task.isCancelled) {
                    NSError *newError = [PFErrorUtilities errorWithCode:kPFErrorUnsavedFile
                                                                message:@"A file save was cancelled."];
                    return [BFTask taskWithError:newError];
                }
                return task;
            }];
        }];
    }

    // TODO: (nlutsenko) Get rid of this once we allow localIds in batches.
    NSArray *remaining = uniqueObjects.allObjects;
    NSMutableArray *finished = [NSMutableArray array];
    while (remaining.count > 0) {
        // Partition the objects into two sets: those that can be save immediately,
        // and those that rely on other objects to be created first.
        NSMutableArray *current = [NSMutableArray array];
        NSMutableArray *nextBatch = [NSMutableArray array];
        for (PFObject *object in remaining) {
            if ([object canBeSerializedAfterSaving:finished withCurrentUser:currentUser error:nil]) {
                [current addObject:object];
            } else {
                [nextBatch addObject:object];
            }
        }
        remaining = nextBatch;

        if (current.count == 0) {
            // We do cycle-detection when building the list of objects passed to this
            // function, so this should never get called.  But we should check for it
            // anyway, so that we get an exception instead of an infinite loop.
            PFConsistencyAssertionFailure(@"Unable to save a PFObject with a relation to a cycle.");
        }

        // If a lazy user is one of the objects in the array, resolve its laziness now and
        // remove it from the list of things to save.
        //
        // This has to happen separately from everything else because there [PFUser save]
        // is special-cased to work for lazy users, but new users can't be created by
        // PFMultiCommand's regular save.
        if (currentUser._lazy && [current containsObject:currentUser]) {
            task = [task continueAsyncWithSuccessBlock:^id(BFTask *task) {
                return [currentUser saveInBackground];
            }];

            [finished addObject:currentUser];
            [current removeObject:currentUser];
            if (current.count == 0) {
                continue;
            }
        }

        task = [task continueAsyncWithSuccessBlock:^id(BFTask *task) {
            // Batch requests have currently a limit of 50 packaged requests per single request
            // This splitting will split the overall array into segments of upto 50 requests
            // and execute them concurrently with a wrapper task for all of them.
            NSArray *objectBatches = [PFInternalUtils arrayBySplittingArray:current
                                            withMaximumComponentsPerSegment:PFRESTObjectBatchCommandSubcommandsLimit];
            NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:objectBatches.count];

            for (NSArray *objectBatch in objectBatches) {
                BFTask *batchTask = [self _enqueue:^BFTask *(BFTask *toAwait) {
                    return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
                        NSMutableArray *commands = [NSMutableArray arrayWithCapacity:objectBatch.count];
                        for (PFObject *object in objectBatch) {
                            PFRESTCommand *command = nil;
                            @synchronized ([object lock]) {
                                [object _objectWillSave];
                                [object _checkSaveParametersWithCurrentUser:currentUser];
                                command = [object _constructSaveCommandForChanges:[object unsavedChanges]
                                                                     sessionToken:sessionToken
                                                                    objectEncoder:[PFPointerObjectEncoder objectEncoder]];
                                [object startSave];
                            }
                            [commands addObject:command];
                        }

                        id<PFCommandRunning> commandRunner = [Parse _currentManager].commandRunner;
                        PFRESTCommand *batchCommand = [PFRESTObjectBatchCommand batchCommandWithCommands:commands
                                                                                            sessionToken:sessionToken
                                                                                               serverURL:commandRunner.serverURL];
                        return [[commandRunner runCommandAsync:batchCommand withOptions:0] continueAsyncWithBlock:^id(BFTask *commandRunnerTask) {
                            NSArray *results = [commandRunnerTask.result result];

                            NSMutableArray *handleSaveTasks = [NSMutableArray arrayWithCapacity:objectBatch.count];

                            __block NSError *error = task.error;
                            [objectBatch enumerateObjectsUsingBlock:^(PFObject *object, NSUInteger idx, BOOL *stop) {
                                // If the task resulted in an error - don't even bother looking into
                                // the result of the command, just roll the error further

                                BFTask *task = nil;
                                if (commandRunnerTask.error) {
                                    task = [object handleSaveResultAsync:nil];
                                } else {
                                    NSDictionary *commandResult = results[idx];

                                    NSDictionary *errorResult = commandResult[@"error"];
                                    if (errorResult) {
                                        error = [PFErrorUtilities errorFromResult:errorResult];
                                        task = [[object handleSaveResultAsync:nil] continueWithBlock:^id(BFTask *task) {
                                            return [BFTask taskWithError:error];
                                        }];
                                    } else {
                                        NSDictionary *successfulResult = commandResult[@"success"];
                                        task = [object handleSaveResultAsync:successfulResult];
                                    }
                                }
                                [handleSaveTasks addObject:task];
                            }];

                            return [[BFTask taskForCompletionOfAllTasks:handleSaveTasks] continueAsyncWithBlock:^id(BFTask *task) {
                                if (commandRunnerTask.faulted || commandRunnerTask.cancelled) {
                                    return commandRunnerTask;
                                }

                                // Reiterate saveAll tasks, return first error.
                                for (BFTask *handleSaveTask in handleSaveTasks) {
                                    if (handleSaveTask.faulted) {
                                        return handleSaveTask;
                                    }
                                }

                                return @YES;
                            }];
                        }];
                    }];
                } forObjects:objectBatch];
                [tasks addObject:batchTask];
            }

            return [[BFTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id(BFTask *task) {
                if (task.cancelled || task.faulted) {
                    return task;
                }
                return @YES;
            }];
        }];

        [finished addObjectsFromArray:current];
    }

    return task;
}

// Just like deepSaveAsync, but uses saveEventually instead of saveAsync.
// Because you shouldn't wait for saveEventually calls to complete, this
// does not return any operation.
+ (BFTask *)_enqueueSaveEventuallyChildrenOfObject:(PFObject *)object currentUser:(PFUser *)currentUser {
    return [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        NSMutableSet *uniqueObjects = [NSMutableSet set];
        NSMutableSet *uniqueFiles = [NSMutableSet set];
        [self collectDirtyChildren:object children:uniqueObjects files:uniqueFiles currentUser:currentUser];
        for (PFFile *file in uniqueFiles) {
            if (!file.url) {
                NSError *error = [PFErrorUtilities errorWithCode:kPFErrorUnsavedFile
                                                         message:@"Unable to saveEventually a PFObject with a relation to a new, unsaved PFFile."];
                return [BFTask taskWithError:error];
            }
        }

        // Remove object from the queue of objects to save as this method should only save children.
        [uniqueObjects removeObject:object];

        NSArray *remaining = uniqueObjects.allObjects;
        NSMutableArray *finished = [NSMutableArray array];
        NSMutableArray *enqueueTasks = [NSMutableArray array];
        while (remaining.count > 0) {
            // Partition the objects into two sets: those that can be save immediately,
            // and those that rely on other objects to be created first.
            NSMutableArray *current = [NSMutableArray array];
            NSMutableArray *nextBatch = [NSMutableArray array];
            for (PFObject *object in remaining) {
                if ([object canBeSerializedAfterSaving:finished withCurrentUser:currentUser error:nil]) {
                    [current addObject:object];
                } else {
                    [nextBatch addObject:object];
                }
            }
            remaining = nextBatch;

            if (current.count == 0) {
                // We do cycle-detection when building the list of objects passed to this
                // function, so this should never get called.  But we should check for it
                // anyway, so that we get an exception instead of an infinite loop.
                PFConsistencyAssertionFailure(@"Unable to save a PFObject with a relation to a cycle.");
            }

            // If a lazy user is one of the objects in the array, resolve its laziness now and
            // remove it from the list of things to save.
            //
            // This has to happen separately from everything else because there [PFUser save]
            // is special-cased to work for lazy users, but new users can't be created by
            // PFMultiCommand's regular save.
            //
            // Unfortunately, ACLs with lazy users still cannot be saved, because the ACL does
            // does not get updated after the user save completes.
            // TODO: (nlutsenko) Make the ACL update after the user is saved.
            if (currentUser._lazy && [current containsObject:currentUser]) {
                [enqueueTasks addObject:[currentUser _enqueueSaveEventuallyWithChildren:NO]];
                [finished addObject:currentUser];
                [current removeObject:currentUser];
                if (current.count == 0) {
                    continue;
                }
            }

            // TODO: (nlutsenko) Allow batching with saveEventually.
            for (PFObject *object in current) {
                [enqueueTasks addObject:[object _enqueueSaveEventuallyWithChildren:NO]];
            }

            [finished addObjectsFromArray:current];
        }
        return [BFTask taskForCompletionOfAllTasks:enqueueTasks];
    }];
}

- (BFTask *)_saveChildrenInBackgroundWithCurrentUser:(PFUser *)currentUser sessionToken:(NSString *)sessionToken {
    @synchronized (lock) {
        return [[self class] _deepSaveAsyncChildrenOfObject:self withCurrentUser:currentUser sessionToken:sessionToken];
    }
}

///--------------------------------------
#pragma mark - Dirtiness helper
///--------------------------------------

- (BOOL)isDirty:(BOOL)considerChildren {
    @synchronized (lock) {
        if (self._state.deleted || dirty || [self _hasChanges]) {
            return YES;
        }

        if (considerChildren) {
            NSMutableSet *seen = [NSMutableSet set];
            return [self _areChildrenDirty:seen];
        }

        return NO;
    }
}

- (void)_setDirty:(BOOL)aDirty {
    @synchronized (lock) {
        dirty = aDirty;
    }
}

- (BOOL)_areChildrenDirty:(NSMutableSet *)seenObjects {
    if ([seenObjects containsObject:self]) {
        return NO;
    }
    [seenObjects addObject:self];

    @synchronized(lock) {
        if (self._state.deleted || dirty || [self _hasChanges]) {
            return YES;
        }

        // We only need to consider the currently estimated children here,
        // because they're the only ones that might need to be saved in a
        // subsequent call to save, which is the meaning of "dirtiness".
        __block BOOL retValue = NO;
        [_estimatedData enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[PFObject class]] && [obj _areChildrenDirty:seenObjects]) {
                retValue = YES;
                *stop = YES;
            }
        }];
        return retValue;
    }
}

///--------------------------------------
#pragma mark - Data Availability
///--------------------------------------

// TODO: (nlutsenko) Remove this when rest of PFObject is decoupled.
- (void)setHasBeenFetched:(BOOL)fetched {
    @synchronized (lock) {
        if (self._state.complete != fetched) {
            self._state = [self._state copyByMutatingWithBlock:^(PFMutableObjectState *state) {
                state.complete = fetched;
            }];
        }
    }
}

- (void)_setDeleted:(BOOL)deleted {
    @synchronized (lock) {
        if (self._state.deleted != deleted) {
            self._state = [self._state copyByMutatingWithBlock:^(PFMutableObjectState *state) {
                state.deleted = deleted;
            }];
        }
    }
}

- (BOOL)isDataAvailableForKey:(NSString *)key {
    if (!key) {
        return NO;
    }

    @synchronized (lock) {
        if (self.dataAvailable) {
            return YES;
        }
        return [_availableKeys containsObject:key];
    }
}

///--------------------------------------
#pragma mark - Validations
///--------------------------------------

// Validations that are done on save. For now, there is nothing.
- (void)_checkSaveParametersWithCurrentUser:(PFUser *)currentUser {
    return;
}

/**
 Checks if Parse class name could be used to initialize a given instance of PFObject or it's subclass.
 */
+ (void)_assertValidInstanceClassName:(NSString *)className {
    PFParameterAssert(className, @"Class name can't be 'nil'.");
    PFParameterAssert(![className hasPrefix:@"_"], @"Invalid class name. Class names cannot start with an underscore.");
}

///--------------------------------------
#pragma mark - Serialization helpers
///--------------------------------------

- (NSString *)getOrCreateLocalId {
    @synchronized(lock) {
        if (!self.localId) {
            PFConsistencyAssert(!self._state.objectId,
                                @"A localId should not be created for an object with an objectId.");
            self.localId = [[Parse _currentManager].coreManager.objectLocalIdStore createLocalId];
        }
    }
    return self.localId;
}

- (void)resolveLocalId {
    @synchronized (lock) {
        PFConsistencyAssert(self.localId, @"Tried to resolve a localId for an object with no localId.");
        NSString *newObjectId = [[Parse _currentManager].coreManager.objectLocalIdStore objectIdForLocalId:self.localId];

        // If we are resolving local ids, then this object is about to go over the network.
        // But if it has local ids that haven't been resolved yet, then that's not going to
        // be possible.
        if (!newObjectId) {
            PFConsistencyAssertionFailure(@"Tried to save an object with a pointer to a new, unsaved object.");
        }

        // Nil out the localId so that the new objectId won't be saved back to the PFObjectLocalIdStore.
        self.localId = nil;
        self.objectId = newObjectId;
    }
}

+ (id)_objectFromDictionary:(NSDictionary *)dictionary
           defaultClassName:(NSString *)defaultClassName
               completeData:(BOOL)completeData {
    return [self _objectFromDictionary:dictionary
                      defaultClassName:defaultClassName
                          completeData:completeData
                               decoder:[PFDecoder objectDecoder]];
}

// When merging results from a query, ensure that any supplied `selectedKeys` are marked as available. This special
// handling is necessary because keys with an `undefined` value are not guaranteed to be included in the server's
// response data.
//
// See T3336562
+ (id)_objectFromDictionary:(NSDictionary *)dictionary
           defaultClassName:(NSString *)defaultClassName
               selectedKeys:(NSArray *)selectedKeys {
    PFObject *result =  [self _objectFromDictionary:dictionary
                                   defaultClassName:defaultClassName
                                       completeData:(selectedKeys == nil)
                                            decoder:[PFDecoder objectDecoder]];
    if (selectedKeys) {
        [result->_availableKeys addObjectsFromArray:selectedKeys];
    }
    return result;
}

/**
 Creates a PFObject from a dictionary object.

 @param dictionary Undecoded dictionary.
 @param defaultClassName The className of the resulting object if none is given by the dictionary.
 @param completeData Whether to use complete data.
 @param decoder Decoder used to decode the dictionary.
 */
+ (id)_objectFromDictionary:(NSDictionary *)dictionary
           defaultClassName:(NSString *)defaultClassName
               completeData:(BOOL)completeData
                    decoder:(PFDecoder *)decoder {
    NSString *objectId = nil;
    NSString *className = defaultClassName;
    if (dictionary != nil) {
        objectId = dictionary[@"objectId"];
        className = dictionary[@"className"] ?: defaultClassName;
    }
    PFObject *object = [PFObject objectWithoutDataWithClassName:className objectId:objectId];
    [object _mergeAfterFetchWithResult:dictionary decoder:decoder completeData:completeData];
    return object;
}

/**
 When the app was previously a non-LDS app and want to enable LDS, currentUser and currentInstallation
 will be discarded if we don't migrate them. This is a helper method to migrate user/installation
 from disk to pin.

 @param fileName the file in which the object was saved.
 @param pinName the name of the pin in which the object should be stored.
 */
+ (BFTask *)_migrateObjectInBackgroundFromFile:(NSString *)fileName
                                         toPin:(NSString *)pinName {
    return [self _migrateObjectInBackgroundFromFile:fileName toPin:pinName usingMigrationBlock:nil];
}

/**
 When the app was previously a non-LDS app and want to enable LDS, currentUser and currentInstallation
 will be discarded if we don't migrate them. This is a helper method to migrate user/installation
 from disk to pin.

 @param fileName the file in which the object was saved.
 @param pinName the name of the pin in which the object should be stored.
 @param migrationBlock The block that will be called if there is an object on disk and before the object is pinned.
 */
+ (BFTask *)_migrateObjectInBackgroundFromFile:(NSString *)fileName
                                         toPin:(NSString *)pinName
                           usingMigrationBlock:(BFContinuationBlock)migrationBlock {
    PFObjectFilePersistenceController *controller = [Parse _currentManager].coreManager.objectFilePersistenceController;
    BFTask *task = [controller loadPersistentObjectAsyncForKey:fileName];
    if (migrationBlock) {
        task = [task continueWithSuccessBlock:^id(BFTask *task) {
            PFObject *object = task.result;
            if (object) {
                return [[task continueWithBlock:migrationBlock] continueWithResult:object];
            }
            return task;
        }];
    }
    return [task continueWithSuccessBlock:^id(BFTask *task) {
        PFObject *object = task.result;
        return [[object _pinInBackgroundWithName:pinName includeChildren:NO] continueWithBlock:^id(BFTask *task) {
            BFTask *resultTask = [BFTask taskWithResult:object];

            // Only delete if we successfully pin it so that it retries the migration next time.
            if (!task.faulted && !task.cancelled) {
                NSString *path = [[Parse _currentManager].fileManager parseDataItemPathForPathComponent:fileName];
                return [[PFFileManager removeItemAtPathAsync:path] continueWithBlock:^id(BFTask *task) {
                    // We don't care if it fails to delete the file, so return the
                    return resultTask;
                }];
            }
            return resultTask;
        }];
    }];
}

///--------------------------------------
#pragma mark - REST operations
///--------------------------------------

/**
 Encodes parse object into NSDictionary suitable for persisting into LDS.
 */
- (NSDictionary *)RESTDictionaryWithObjectEncoder:(PFEncoder *)objectEncoder
                                operationSetUUIDs:(NSArray **)operationSetUUIDs {
    NSArray *operationQueue = nil;
    PFObjectState *state = nil;
    NSUInteger deletingEventuallyCount = 0;
    @synchronized (lock) {
        state = self._state;
        operationQueue = [[NSArray alloc] initWithArray:operationSetQueue copyItems:YES];
        deletingEventuallyCount = _deletingEventuallyCount;
    }

    return [self RESTDictionaryWithObjectEncoder:objectEncoder
                               operationSetUUIDs:operationSetUUIDs
                                           state:state
                               operationSetQueue:operationQueue
                         deletingEventuallyCount:deletingEventuallyCount];
}

- (NSDictionary *)RESTDictionaryWithObjectEncoder:(PFEncoder *)objectEncoder
                                operationSetUUIDs:(NSArray **)operationSetUUIDs
                                            state:(PFObjectState *)state
                                operationSetQueue:(NSArray *)queue
                          deletingEventuallyCount:(NSUInteger)deletingEventuallyCount {
    NSMutableDictionary *result = [[state dictionaryRepresentationWithObjectEncoder:objectEncoder] mutableCopy];
    result[PFObjectClassNameRESTKey] = state.parseClassName;
    result[PFObjectCompleteRESTKey] = @(state.complete);

    result[PFObjectIsDeletingEventuallyRESTKey] = @(deletingEventuallyCount);

    // TODO (hallucinogen): based on some note from Android's toRest, we'll need to put this
    // stuff somewhere else
    NSMutableArray *operations = [NSMutableArray array];
    NSMutableArray *mutableOperationSetUUIDs = [NSMutableArray array];
    for (PFOperationSet *operation in queue) {
        NSArray *ooSetUUIDs = nil;
        [operations addObject:[operation RESTDictionaryUsingObjectEncoder:objectEncoder
                                                        operationSetUUIDs:&ooSetUUIDs]];
        [mutableOperationSetUUIDs addObjectsFromArray:ooSetUUIDs];
    }

    *operationSetUUIDs = mutableOperationSetUUIDs;

    result[PFObjectOperationsRESTKey] = operations;
    return result;
}

- (void)mergeFromRESTDictionary:(NSDictionary *)object withDecoder:(PFDecoder *)decoder {
    @synchronized (lock) {
        BOOL mergeServerData = NO;

        PFMutableObjectState *state = [self._state mutableCopy];

        // If LDS has `updatedAt` and we have it - compare, then if stuff is newer - merge.
        // If LDS doesn't have `updatedAt` and we don't have it - merge anyway.
        NSString *updatedAtString = object[PFObjectUpdatedAtRESTKey];
        if (updatedAtString) {
            NSDate *updatedDate = [[PFDateFormatter sharedFormatter] dateFromString:updatedAtString];
            mergeServerData = ([state.updatedAt compare:updatedDate] != NSOrderedDescending);
        } else if (!state.updatedAt) {
            mergeServerData = YES;
        }
        [object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([key isEqualToString:PFObjectOperationsRESTKey]) {
                PFOperationSet *remoteOperationSet = nil;
                NSArray *operations = (NSArray *)obj;
                if (operations.count > 0) {
                    // Add and enqueue any saveEventually operations, roll forward any other
                    // operations sets (operations sets here are generally failed/incomplete saves).
                    PFOperationSet *current = nil;
                    for (id rawOperationSet in operations) {
                        PFOperationSet *operationSet = [PFOperationSet operationSetFromRESTDictionary:rawOperationSet
                                                                                         usingDecoder:decoder];
                        if (operationSet.saveEventually) {
                            if (current != nil) {
                                [[self unsavedChanges] mergeOperationSet:current];
                                current = nil;
                            }

                            // Check if queue already contains this operation set and discard it if does
                            if (![self _containsOperationSet:operationSet]) {
                                // Insert the `saveEventually` operationSet before the last operation set at all times.
                                NSUInteger index = (operationSetQueue.count == 0 ? 0 : operationSetQueue.count - 1);
                                [operationSetQueue insertObject:operationSet atIndex:index];
                                [self _enqueueSaveEventuallyOperationAsync:operationSet];
                            }

                            continue;
                        }

                        if (current != nil) {
                            [operationSet mergeOperationSet:current];
                        }
                        current = operationSet;
                    }
                    if (current != nil) {
                        remoteOperationSet = current;
                    }
                }

                PFOperationSet *localOperationSet = [self unsavedChanges];
                if (localOperationSet.updatedAt != nil && remoteOperationSet.updatedAt != nil &&
                    [localOperationSet.updatedAt compare:remoteOperationSet.updatedAt] != NSOrderedAscending) {
                    [localOperationSet mergeOperationSet:remoteOperationSet];
                } else {
                    PFConsistencyAssert(remoteOperationSet, @"'remoteOperationSet' should not be nil.");
                    NSUInteger index = [operationSetQueue indexOfObject:localOperationSet];
                    [remoteOperationSet mergeOperationSet:localOperationSet];
                    operationSetQueue[index] = remoteOperationSet;
                }

                return;
            }

            if ([key isEqualToString:PFObjectCompleteRESTKey]) {
                // If server data is complete, consider this object to be fetched
                state.complete = state.complete || [obj boolValue];
                return;
            }
            if ([key isEqualToString:PFObjectIsDeletingEventuallyRESTKey]) {
                _deletingEventuallyCount = [obj unsignedIntegerValue];
                return;
            }

            [_availableKeys addObject:key];

            // If server data in dictionary is older - don't merge it.
            if (!mergeServerData) {
                return;
            }

            if ([key isEqualToString:PFObjectTypeRESTKey] || [key isEqualToString:PFObjectClassNameRESTKey]) {
                return;
            }
            if ([key isEqualToString:PFObjectObjectIdRESTKey]) {
                state.objectId = obj;
                return;
            }
            if ([key isEqualToString:PFObjectCreatedAtRESTKey]) {
                [state setCreatedAtFromString:obj];
                return;
            }
            if ([key isEqualToString:PFObjectUpdatedAtRESTKey]) {
                [state setUpdatedAtFromString:obj];
                return;
            }

            if ([key isEqualToString:PFObjectACLRESTKey]) {
                PFACL *acl = [PFACL ACLWithDictionary:obj];
                [state setServerDataObject:acl forKey:PFObjectACLRESTKey];
                return;
            }

            // Should be decoded
            id decodedObject = [decoder decodeObject:obj];
            [state setServerDataObject:decodedObject forKey:key];
        }];
        if (state.updatedAt == nil && state.createdAt != nil) {
            state.updatedAt = state.createdAt;
        }
        BOOL previousDirtyState = dirty;
        self._state = state;
        dirty = previousDirtyState;

        if (mergeServerData) {
            if ([object[PFObjectCompleteRESTKey] boolValue]) {
                [self removeOldKeysAfterFetch:object];
            } else {
                // Unmark the object as fetched, because we merged from incomplete new data.
                [self setHasBeenFetched:NO];
            }
        }
        [self rebuildEstimatedData];
    }
}

///--------------------------------------
#pragma mark - Eventually Helper
///--------------------------------------

/**
 Enqueues saveEventually operation asynchronously.

 @return A task which result is a saveEventually task.
 */
- (BFTask *)_enqueueSaveEventuallyWithChildren:(BOOL)saveChildren {
    return [_eventuallyTaskQueue enqueue:^BFTask *(BFTask *toAwait) {
        PFUser *currentUser = [PFUser currentUser];
        NSString *sessionToken = currentUser.sessionToken;
        return [[toAwait continueAsyncWithBlock:^id(BFTask *task) {
            return [self _validateSaveEventuallyAsync];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            @synchronized (lock) {
                [self _objectWillSave];
                if (![self isDirty:NO]) {
                    return @YES;
                }
            }

            BFTask *saveChildrenTask = nil;
            if (saveChildren) {
                saveChildrenTask = [[self class] _enqueueSaveEventuallyChildrenOfObject:self currentUser:currentUser];
            } else {
                saveChildrenTask = [BFTask taskWithResult:nil];
            }

            return [saveChildrenTask continueWithSuccessBlock:^id(BFTask *task) {
                BFTask *saveTask = nil;
                @synchronized (lock) {
                    // Snapshot the current set of changes, and push a new changeset into the queue.
                    PFOperationSet *changes = [self unsavedChanges];
                    changes.saveEventually = YES;
                    [self startSave];
                    [self _checkSaveParametersWithCurrentUser:currentUser];
                    PFRESTCommand *command = [self _constructSaveCommandForChanges:changes
                                                                      sessionToken:sessionToken
                                                                     objectEncoder:[PFPointerOrLocalIdObjectEncoder objectEncoder]];

                    // Enqueue the eventually operation!
                    saveTask = [[Parse _currentManager].eventuallyQueue enqueueCommandInBackground:command withObject:self];
                    [self _enqueueSaveEventuallyOperationAsync:changes];
                }
                saveTask = [saveTask continueWithBlock:^id(BFTask *task) {
                    @try {
                        if (!task.isCancelled && !task.faulted) {
                            PFCommandResult *result = task.result;
                            // PFPinningEventuallyQueue handle save result directly.
                            if (![Parse _currentManager].offlineStoreLoaded) {
                                return [self handleSaveResultAsync:result.result];
                            }
                        }
                        return task;
                    } @finally {
                       
                    }
                }];
                return [BFTask taskWithResult:saveTask];
            }];
        }];
    }];
}


/**
 Enqueues the saveEventually PFOperationSet in PFObject taskQueue
 */
- (BFTask *)_enqueueSaveEventuallyOperationAsync:(PFOperationSet *)operationSet {
    if (!operationSet.isSaveEventually) {
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorOperationForbidden
                                                 message:@"Unable to enqueue non-saveEventually operation set."];
        return [BFTask taskWithError:error];
    }

    return [self.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        // Use default priority background to break a chain and make sure this operation is truly asynchronous
        return [toAwait continueWithExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id(BFTask *task) {
            PFEventuallyQueue *queue = [Parse _currentManager].eventuallyQueue;
            id<PFEventuallyQueueSubclass> queueSubClass = (id<PFEventuallyQueueSubclass>)queue;
            return [queueSubClass _waitForOperationSet:operationSet eventuallyPin:nil];
        }];
    }];
}

///--------------------------------------
#pragma mark - Data model manipulation
///--------------------------------------

- (NSMutableDictionary *)_convertToDictionaryForSaving:(PFOperationSet *)changes
                                     withObjectEncoder:(PFEncoder *)encoder {
    @synchronized (lock) {
        NSMutableDictionary *serialized = [NSMutableDictionary dictionary];
        [changes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            serialized[key] = obj;
        }];
        return [encoder encodeObject:serialized];
    }
}

/**
 performOperation:forKey: is like setObject:forKey, but instead of just taking a
 new value, it takes a PFFieldOperation that modifies the value.
 */
- (void)performOperation:(PFFieldOperation *)operation forKey:(NSString *)key {
    @synchronized (lock) {
        [_estimatedData applyFieldOperation:operation forKey:key];

        PFFieldOperation *oldOperation = [self unsavedChanges][key];
        PFFieldOperation *newOperation = [operation mergeWithPrevious:oldOperation];
        [self unsavedChanges][key] = newOperation;
        [_availableKeys addObject:key];
    }
}

- (BOOL)_containsOperationSet:(PFOperationSet *)operationSet {
    @synchronized (lock) {
        for (PFOperationSet *existingOperationSet in operationSetQueue) {
            if (existingOperationSet == operationSet ||
                [existingOperationSet.uuid isEqualToString:operationSet.uuid]) {
                return YES;
            }
        }
    }
    return NO;
}

/**
 Returns the set of PFFieldOperations that will be sent in the next save.
 */
- (PFOperationSet *)unsavedChanges {
    @synchronized (lock) {
        return operationSetQueue.lastObject;
    }
}

/**
 @return YES if there's unsaved changes in this object. This complements ivar `dirty` for `isDirty` check.
 */
- (BOOL)_hasChanges {
    @synchronized (lock) {
        return [self unsavedChanges].count > 0;
    }
}

/**
 @return YES if this PFObject has operations in operationSetQueue that haven't been completed yet,
 NO if there are no operations in the operationSetQueue.
 */
- (BOOL)_hasOutstandingOperations {
    @synchronized (lock) {
        // > 1 since 1 is unsaved changes.
        return operationSetQueue.count > 1;
    }
}

- (void)rebuildEstimatedData {
    @synchronized (lock) {
        _estimatedData = [PFObjectEstimatedData estimatedDataFromServerData:self._state.serverData
                                                          operationSetQueue:operationSetQueue];
    }
}

- (PFObject *)mergeFromObject:(PFObject *)other {
    @synchronized (lock) {
        if (self == other) {
            // If they point to the same instance, then don't merge.
            return self;
        }

        self._state = [self._state copyByMutatingWithBlock:^(PFMutableObjectState *state) {
            state.objectId = other.objectId;
            state.createdAt = other.createdAt;
            state.updatedAt = other.updatedAt;
            state.serverData = [other._state.serverData mutableCopy];
        }];

        dirty = NO;

        [self rebuildEstimatedData];
        return self;
    }
}

- (void)_mergeAfterFetchWithResult:(NSDictionary *)result decoder:(PFDecoder *)decoder completeData:(BOOL)completeData {
    @synchronized (lock) {
        [self _mergeFromServerWithResult:result decoder:decoder completeData:completeData];
        if (completeData) {
            [self removeOldKeysAfterFetch:result];
        }
        [self rebuildEstimatedData];
    }
}

- (void)removeOldKeysAfterFetch:(NSDictionary *)result {
    @synchronized (lock) {
        self._state = [self._state copyByMutatingWithBlock:^(PFMutableObjectState *state) {
            NSMutableDictionary *removedDictionary = [NSMutableDictionary dictionaryWithDictionary:state.serverData];
            [removedDictionary removeObjectsForKeys:result.allKeys];

            NSArray *removedKeys = removedDictionary.allKeys;
            [state removeServerDataObjectsForKeys:removedKeys];
            [_availableKeys minusSet:[NSSet setWithArray:removedKeys]];
        }];
    }
}

- (void)_mergeAfterSaveWithResult:(NSDictionary *)result decoder:(PFDecoder *)decoder {
    @synchronized (lock) {
        PFOperationSet *operationsBeforeSave = operationSetQueue[0];
        [operationSetQueue removeObjectAtIndex:0];

        if (!result) {
            // Merge the data from the failed save into the next save.
            PFOperationSet *operationsForNextSave = operationSetQueue[0];
            [operationsForNextSave mergeOperationSet:operationsBeforeSave];
        } else {
            self._state = [self._state copyByMutatingWithBlock:^(PFMutableObjectState *state) {
                [state applyOperationSet:operationsBeforeSave];
            }];

            [self _mergeFromServerWithResult:result decoder:decoder completeData:NO];
            [self rebuildEstimatedData];
        }
    }
}

- (void)_mergeFromServerWithResult:(NSDictionary *)result decoder:(PFDecoder *)decoder completeData:(BOOL)completeData {
    @synchronized (lock) {
        self._state = [self._state copyByMutatingWithBlock:^(PFMutableObjectState *state) {
            // If the server's data is complete, consider this object to be fetched.
            state.complete |= completeData;

            [result enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([key isEqualToString:PFObjectObjectIdRESTKey]) {
                    state.objectId = obj;
                } else if ([key isEqualToString:PFObjectCreatedAtRESTKey]) {
                    // These dates can be passed in as NSDate or as NSString,
                    // depending on whether they were wrapped inside JSONObject with __type: Date or not.
                    if ([obj isKindOfClass:[NSDate class]]) {
                        state.createdAt = obj;
                    } else {
                        [state setCreatedAtFromString:obj];
                    }
                } else if ([key isEqualToString:PFObjectUpdatedAtRESTKey]) {
                    // These dates can be passed in as NSDate or as NSString,
                    // depending on whether they were wrapped inside JSONObject with __type: Date or not.
                    if ([obj isKindOfClass:[NSDate class]]) {
                        state.updatedAt = obj;
                    } else {
                        [state setUpdatedAtFromString:obj];
                    }
                } else if ([key isEqualToString:PFObjectACLRESTKey]) {
                    PFACL *acl = [PFACL ACLWithDictionary:obj];
                    [state setServerDataObject:acl forKey:key];
                } else {
                    [state setServerDataObject:[decoder decodeObject:obj] forKey:key];
                }
            }];
            if (state.updatedAt == nil && state.createdAt != nil) {
                state.updatedAt = state.createdAt;
            }
        }];
        if (result.allKeys) {
            [_availableKeys addObjectsFromArray:result.allKeys];
        }

        dirty = NO;
    }
}

///--------------------------------------
#pragma mark - Command handlers
///--------------------------------------

// We can't get rid of these handlers, because subclasses override them
// to add special actions after operations.

- (BFTask *)handleSaveResultAsync:(NSDictionary *)result {
    NSDictionary *fetchedObjects = [self _collectFetchedObjects];

    BFTask *task = [BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id{
        PFKnownParseObjectDecoder *decoder = [PFKnownParseObjectDecoder decoderWithFetchedObjects:fetchedObjects];
        @synchronized (self.lock) {
            // TODO (hallucinogen): t5611821 we need to make mergeAfterSave that accepts decoder and operationBeforeSave
            [self _mergeAfterSaveWithResult:result decoder:decoder];
        }
        return nil;
    }];

    PFOfflineStore *store = [Parse _currentManager].offlineStore;
    if (store != nil) {
        task = [task continueWithBlock:^id(BFTask *task) {
            return [store updateDataForObjectAsync:self];
        }];
    }

    return [task continueWithBlock:^id(BFTask *task) {
        @synchronized (lock) {
            if (self.saveDelegate) {
                [self.saveDelegate invoke:self error:nil];
            }
            return @(result != nil);
        }
    }];
}

///--------------------------------------
#pragma mark - Asynchronous operations
///--------------------------------------

- (void)startSave {
    @synchronized (lock) {
        [operationSetQueue addObject:[[PFOperationSet alloc] init]];
    }
}

- (BFTask *)saveAsync:(BFTask *)toAwait {
    PFCurrentUserController *controller = [[self class] currentUserController];
    return [[controller getCurrentObjectAsync] continueWithBlock:^id(BFTask *task) {
        PFUser *currentUser = task.result;
        NSString *sessionToken = currentUser.sessionToken;

        BFTask *await = toAwait ?: [BFTask taskWithResult:nil];
        return [[await continueAsyncWithBlock:^id(BFTask *task) {
            PFOfflineStore *offlineStore = [Parse _currentManager].offlineStore;
            if (offlineStore != nil) {
                return [offlineStore fetchObjectLocallyAsync:self];
            }
            return nil;
        }] continueWithBlock:^id(BFTask *task) {
            @synchronized (lock) {
                if (![self isDirty:YES]) {
                    return @YES;
                }

                [self _objectWillSave];

                // Snapshot the current set of changes, and push a new changeset into the queue.
                PFOperationSet *changes = [self unsavedChanges];

                [self startSave];
                BFTask *childrenTask = [self _saveChildrenInBackgroundWithCurrentUser:currentUser
                                                                         sessionToken:sessionToken];
                if (!dirty && changes.count == 0) {
                    return childrenTask;
                }
                return [[childrenTask continueWithSuccessBlock:^id(BFTask *task) {
                    [self _checkSaveParametersWithCurrentUser:currentUser];
                    PFRESTCommand *command = [self _constructSaveCommandForChanges:changes
                                                                      sessionToken:sessionToken
                                                                     objectEncoder:[PFPointerObjectEncoder objectEncoder]];
                    return [[Parse _currentManager].commandRunner runCommandAsync:command
                                                                      withOptions:PFCommandRunningOptionRetryIfFailed];
                }] continueAsyncWithBlock:^id(BFTask *task) {
                    if (task.cancelled || task.faulted) {
                        // If there was an error, we want to roll forward the save changes before rethrowing.
                        BFTask *commandRunnerTask = task;
                        return [[self handleSaveResultAsync:nil] continueWithBlock:^id(BFTask *task) {
                            return commandRunnerTask;
                        }];
                    }
                    PFCommandResult *result = task.result;
                    return [self handleSaveResultAsync:result.result];
                }];
            }
        }];
    }];
}

- (BFTask *)fetchAsync:(BFTask *)toAwait {
    PFCurrentUserController *controller = [[self class] currentUserController];
    return [[controller getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
            return [[[self class] objectController] fetchObjectAsync:self withSessionToken:sessionToken];
        }];
    }];
}

- (BFTask *)deleteAsync:(BFTask *)toAwait {
    PFCurrentUserController *controller = [[self class] currentUserController];
    return [[controller getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
            return [[[self class] objectController] deleteObjectAsync:self withSessionToken:sessionToken];
        }];
    }];
}

///--------------------------------------
#pragma mark - Command constructors
///--------------------------------------

- (PFRESTCommand *)_constructSaveCommandForChanges:(PFOperationSet *)changes
                                      sessionToken:(NSString *)sessionToken
                                     objectEncoder:(PFEncoder *)encoder {
    @synchronized (lock) {
        NSDictionary *parameters = [self _convertToDictionaryForSaving:changes withObjectEncoder:encoder];

        if (self._state.objectId) {
            return [PFRESTObjectCommand updateObjectCommandForObjectState:self._state
                                                                  changes:parameters
                                                         operationSetUUID:changes.uuid
                                                             sessionToken:sessionToken];
        }

        return [PFRESTObjectCommand createObjectCommandForObjectState:self._state
                                                              changes:parameters
                                                     operationSetUUID:changes.uuid
                                                         sessionToken:sessionToken];

    }
}

- (PFRESTCommand *)_currentDeleteCommandWithSessionToken:(NSString *)sessionToken {
    return [PFRESTObjectCommand deleteObjectCommandForObjectState:self._state withSessionToken:sessionToken];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)_setObject:(id)object forKey:(NSString *)key onlyIfDifferent:(BOOL)onlyIfDifferent {
    PFParameterAssert(object != nil && key != nil,
                      @"Can't use nil for keys or values on PFObject. Use NSNull for values.");
    PFParameterAssert([key isKindOfClass:[NSString class]], @"PFObject keys must be NSStrings.");

    if (onlyIfDifferent) {
        id currentObject = self[key];
        if (currentObject == object ||
            [currentObject isEqual:object]) {
            return;
        }
    }

    @synchronized (lock) {
        if ([object isKindOfClass:[PFFieldOperation class]]) {
            [self performOperation:object forKey:key];
            return;
        }

        PFObjectAssertValueIsKindOfValidClass(object);
        [self performOperation:[PFSetOperation setWithValue:object] forKey:key];
    }
}

///--------------------------------------
#pragma mark - Misc helpers
///--------------------------------------

- (NSString *)displayObjectId {
    return self._state.objectId ?: @"new";
}

- (NSString *)displayClassName {
    return self._state.parseClassName;
}

- (void)registerSaveListener:(void (^)(id result, NSError *error))callback {
    @synchronized (lock) {
        if (!self.saveDelegate) {
            self.saveDelegate = [[PFMulticastDelegate alloc] init];
        }
        [self.saveDelegate subscribe:callback];
    }
}

- (void)unregisterSaveListener:(void (^)(id result, NSError *error))callback {
    @synchronized (lock) {
        if (!self.saveDelegate) {
            self.saveDelegate = [[PFMulticastDelegate alloc] init];
        }
        [self.saveDelegate unsubscribe:callback];
    }
}

- (PFACL *)ACLWithoutCopying {
    @synchronized (lock) {
        return _estimatedData[@"ACL"];
    }
}

// Overriden by classes which want to ignore the default ACL.
- (void)setDefaultValues {
    if ([self needsDefaultACL]) {
        PFACL *defaultACL = [PFACL defaultACL];
        if (defaultACL) {
            self.ACL = defaultACL;
        }
    }
}

- (BOOL)needsDefaultACL {
    return YES;
}

- (NSDictionary *)_collectFetchedObjects {
    NSMutableDictionary *fetchedObjects = [NSMutableDictionary dictionary];
    @synchronized (lock) {
        NSDictionary *dictionary = _estimatedData.dictionaryRepresentation;
        [PFInternalUtils traverseObject:dictionary usingBlock:^id(id obj) {
            if ([obj isKindOfClass:[PFObject class]]) {
                PFObject *object = obj;
                NSString *objectId = object.objectId;
                if (objectId && object.dataAvailable) {
                    fetchedObjects[objectId] = object;
                }
            }
            return obj;
        }];
    }
    return fetchedObjects;
}

@end

@implementation PFObject

@synthesize _availableKeys = _availableKeys;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    if (!_pfinternal_state) {
        PFConsistencyAssert([self conformsToProtocol:@protocol(PFSubclassing)],
                            @"Can only call -[PFObject init] on subclasses conforming to PFSubclassing.");
        [PFObject assertSubclassIsRegistered:[self class]];
        _pfinternal_state = [[self class] _newObjectStateWithParseClassName:[[self class] parseClassName]
                                                                   objectId:nil
                                                                 isComplete:YES];
    }
    [[self class] _assertValidInstanceClassName:_pfinternal_state.parseClassName];

    lock = [[NSObject alloc] init];
    operationSetQueue = [NSMutableArray arrayWithObject:[[PFOperationSet alloc] init]];
    _estimatedData = [PFObjectEstimatedData estimatedDataFromServerData:_pfinternal_state.serverData
                                                      operationSetQueue:operationSetQueue];
    _availableKeys = [NSMutableSet set];
    self.taskQueue = [[PFTaskQueue alloc] init];
    _eventuallyTaskQueue = [[PFTaskQueue alloc] init];

    if (_pfinternal_state.complete) {
        dirty = YES;
        [self setDefaultValues];
    }

    return self;
}

- (instancetype)initWithClassName:(NSString *)className {
    PFObjectState *state = [[self class] _newObjectStateWithParseClassName:className objectId:nil isComplete:YES];
    return [self initWithObjectState:state];
}

- (instancetype)initWithObjectState:(PFObjectState *)state {
    _pfinternal_state = state;
    return [self init];
}

+ (instancetype)objectWithClassName:(NSString *)className
                           objectId:(NSString *)objectId
                       completeData:(BOOL)completeData {
    Class class = [[[self class] subclassingController] subclassForParseClassName:className] ?: [PFObject class];
    PFObjectState *state = [class _newObjectStateWithParseClassName:className objectId:objectId isComplete:completeData];
    PFObject *object = [[class alloc] initWithObjectState:state];
    if (!completeData) {
        PFConsistencyAssert(![object _hasChanges],
                            @"The init method of %@ set values on the object, which is not allowed.", class);
    }
    return object;
}

+ (instancetype)objectWithClassName:(NSString *)className {
    return [self objectWithClassName:className objectId:nil completeData:YES];
}

+ (instancetype)objectWithClassName:(NSString *)className dictionary:(NSDictionary *)dictionary {
    PFObject *object = [self objectWithClassName:className];
    PFDecoder *objectDecoder = [PFDecoder objectDecoder];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        object[key] = [objectDecoder decodeObject:obj];
    }];
    return object;
}

+ (instancetype)objectWithoutDataWithClassName:(NSString *)className objectId:(NSString *)objectId {
    // Try get single instance from OfflineStore
    PFOfflineStore *store = [Parse _currentManager].offlineStore;
    if (store != nil && objectId != nil) {
        PFObject *singleObject = [store getOrCreateObjectWithoutDataWithClassName:className objectId:objectId];
        if (singleObject) {
            return singleObject;
        }
    }

    // Local Datastore is not enabled or cannot found the single instance using objectId, let's use the old way
    return [self objectWithClassName:className objectId:objectId completeData:NO];
}

#pragma mark Subclassing

+ (instancetype)object {
    PFConsistencyAssert([self conformsToProtocol:@protocol(PFSubclassing)],
                        @"Can only call +object on subclasses conforming to PFSubclassing");
    NSString *className = [(id<PFSubclassing>)self parseClassName];
    Class class = [[self subclassingController] subclassForParseClassName:className] ?: [PFObject class];
    return [class objectWithClassName:className];
}

+ (instancetype)objectWithoutDataWithObjectId:(NSString *)objectId {
    PFConsistencyAssert([self conformsToProtocol:@protocol(PFSubclassing)],
                        @"Can only call objectWithoutDataWithObjectId: on subclasses conforming to PFSubclassing");
    return [self objectWithoutDataWithClassName:[(id<PFSubclassing>)self parseClassName] objectId:objectId];
}

#pragma mark Private

+ (instancetype)objectWithoutDataWithClassName:(NSString *)className localId:(NSString *)localId {
    PFObject *object = [self objectWithoutDataWithClassName:className objectId:nil];
    object.localId = localId;
    return object;
}

///--------------------------------------
#pragma mark - PFObjectPrivateSubclass
///--------------------------------------

#pragma mark State

+ (PFObjectState *)_newObjectStateWithParseClassName:(NSString *)className
                                            objectId:(NSString *)objectId
                                          isComplete:(BOOL)complete {
    return [PFObjectState stateWithParseClassName:className objectId:objectId isComplete:complete];
}

///--------------------------------------
#pragma mark - Validation
///--------------------------------------

- (BFTask<PFVoid> *)_validateFetchAsync {
    if (!self._state.objectId) {
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorMissingObjectId
                                                 message:@"Can't fetch an object that hasn't been saved to the server."];
        return [BFTask taskWithError:error];
    }
    return [BFTask taskWithResult:nil];
}

- (BFTask<PFVoid> *)_validateDeleteAsync {
    return [BFTask taskWithResult:nil];
}

- (BFTask<PFVoid> *)_validateSaveEventuallyAsync {
    return [BFTask taskWithResult:nil];
}

#pragma mark Object Will Save

- (void)_objectWillSave {
    // Do nothing.
}

///--------------------------------------
#pragma mark - Properties
///--------------------------------------

- (void)set_state:(PFObjectState *)state {
    @synchronized(lock) {
        NSString *oldObjectId = _pfinternal_state.objectId;
        if (self._state != state) {
            _pfinternal_state = [state copy];
        }

        NSString *newObjectId = _pfinternal_state.objectId;
        if (![PFObjectUtilities isObject:oldObjectId equalToObject:newObjectId]) {
            [self _notifyObjectIdChangedFrom:oldObjectId toObjectId:newObjectId];
        }
    }
}

- (PFObjectState *)_state {
    @synchronized(lock) {
        return _pfinternal_state;
    }
}

- (PFObjectEstimatedData *)_estimatedData {
    @synchronized (lock) {
        return _estimatedData;
    }
}

- (void)setObjectId:(NSString *)objectId {
    @synchronized (lock) {
        NSString *oldObjectId = self._state.objectId;
        if ([PFObjectUtilities isObject:oldObjectId equalToObject:objectId]) {
            return;
        }

        dirty = YES;

        // Use ivar directly to avoid going through the custom setter.
        _pfinternal_state = [self._state copyByMutatingWithBlock:^(PFMutableObjectState *state) {
            state.objectId = objectId;
        }];

        [self _notifyObjectIdChangedFrom:oldObjectId toObjectId:objectId];
    }
}

- (NSString *)objectId {
    return self._state.objectId;
}

- (void)_notifyObjectIdChangedFrom:(NSString *)fromObjectId toObjectId:(NSString *)toObjectId {
    @synchronized (self.lock) {
        // The OfflineStore might raise exception if this object already had a different objectId.
        PFOfflineStore *store = [Parse _currentManager].offlineStore;
        if (store != nil) {
            [store updateObjectIdForObject:self oldObjectId:fromObjectId newObjectId:toObjectId];
        }
        if (self.localId) {
            [[Parse _currentManager].coreManager.objectLocalIdStore setObjectId:toObjectId forLocalId:self.localId];
            self.localId = nil;
        }
    }
}

- (NSString *)parseClassName {
    return self._state.parseClassName;
}

- (NSDate *)updatedAt {
    return self._state.updatedAt;
}

- (NSDate *)createdAt {
    return self._state.createdAt;
}

- (PFACL *)ACL {
    return self[@"ACL"];
}

- (void)setACL:(PFACL *)ACL {
    if (!ACL) {
        [self removeObjectForKey:@"ACL"];
    } else {
        self[@"ACL"] = ACL;
    }
}

// PFObject():
@synthesize localId;
@synthesize taskQueue;

// PFObject(Private):
@synthesize saveDelegate;

///--------------------------------------
#pragma mark - PFObject factory methods for Subclassing
///--------------------------------------

// Reverse compatibility note: many people may have built PFObject subclasses before
// we officially supported them. Our implementation can do cool stuff, but requires
// the parseClassName class method.
+ (void)registerSubclass {
    [[self subclassingController] registerSubclass:self];
}

+ (PFQuery *)query {
    PFConsistencyAssert([self conformsToProtocol:@protocol(PFSubclassing)],
                        @"+[PFObject query] can only be called on subclasses conforming to PFSubclassing.");
    [PFObject assertSubclassIsRegistered:self];
    return [PFQuery queryWithClassName:[(id<PFSubclassing>)self parseClassName]];
}

+ (PFQuery *)queryWithPredicate:(NSPredicate *)predicate {
    PFConsistencyAssert([self conformsToProtocol:@protocol(PFSubclassing)],
                        @"+[PFObject queryWithPredicate:] can only be called on subclasses conforming to PFSubclassing.");
    [PFObject assertSubclassIsRegistered:[self class]];
    return [PFQuery queryWithClassName:[(id<PFSubclassing>)self parseClassName] predicate:predicate];
}

+ (void)assertSubclassIsRegistered:(Class)subclass {
    // If people hacked their own subclass together before we supported it officially, we shouldn't break their app.
    if ([subclass conformsToProtocol:@protocol(PFSubclassing)]) {
        Class registration = [[self subclassingController] subclassForParseClassName:[subclass parseClassName]];

        // It's OK to subclass a subclass (i.e. custom PFUser implementation)
        PFConsistencyAssert(registration && (registration == subclass || [registration isSubclassOfClass:subclass]),
                            @"The class %@ must be registered with registerSubclass before using Parse.", subclass);
    }
}

///--------------------------------------
#pragma mark - Delete commands
///--------------------------------------

- (BFTask *)deleteInBackground {
    return [self.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [[self deleteAsync:toAwait] continueWithSuccessResult:@YES];
    }];
}

- (void)deleteInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [[self deleteInBackground] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

///--------------------------------------
#pragma mark - Save commands
///--------------------------------------

- (BFTask *)saveInBackground {
    return [self.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [self saveAsync:toAwait];
    }];
}

- (void)saveInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [[self saveInBackground] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

- (BFTask *)saveEventually {
    return [[self _enqueueSaveEventuallyWithChildren:YES] continueWithSuccessBlock:^id(BFTask *task) {
        // The result of the previous task will be an instance of BFTask.
        // Returning it here will trigger the whole task stack become an actual save task.
        return task.result;
    }];
}

- (void)saveEventually:(PFBooleanResultBlock)block {
    [[self saveEventually] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

- (BFTask *)deleteEventually {
    return [[[_eventuallyTaskQueue enqueue:^BFTask *(BFTask *toAwait) {
        NSString *sessionToken = [PFUser currentSessionToken];
        return [[toAwait continueAsyncWithBlock:^id(BFTask *task) {
            return [self _validateDeleteAsync];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            @synchronized (lock) {
                _deletingEventuallyCount += 1;

                PFOfflineStore *store = [Parse _currentManager].offlineStore;
                BFTask *updateDataTask = store ? [store updateDataForObjectAsync:self] : [BFTask taskWithResult:nil];

                PFRESTCommand *command = [self _currentDeleteCommandWithSessionToken:sessionToken];
                BFTask *deleteTask = [updateDataTask continueWithBlock:^id(BFTask *task) {
                    return [[Parse _currentManager].eventuallyQueue enqueueCommandInBackground:command withObject:self];
                }];
                deleteTask = [deleteTask continueWithSuccessBlock:^id(BFTask *task) {
                    // PFPinningEventuallyQueue handles delete result directly.
                    if (![Parse _currentManager].offlineStoreLoaded) {
                        PFCommandResult *result = task.result;
                        return [[[self class] objectController] processDeleteResultAsync:result.result forObject:self];
                    }
                    return task;
                }];
                return deleteTask;
            }
        }];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        // The result of the previous task will be an instance of BFTask.
        // Returning it here will trigger the whole task stack become an actual save task.
        return task.result;
    }] continueWithSuccessResult:@YES];
}

///--------------------------------------
#pragma mark - Dirtiness
///--------------------------------------

- (BOOL)isDirty {
    return [self isDirty:YES];
}

- (BOOL)isDirtyForKey:(NSString *)key {
    @synchronized (lock) {
        return ([self unsavedChanges][key] != nil);
    }
}

///--------------------------------------
#pragma mark - Fetch
///--------------------------------------

- (BOOL)isDataAvailable {
    return self._state.complete;
}

- (instancetype)refresh {
    return [self fetch];
}

- (instancetype)refresh:(NSError **)error {
    return [self fetch:error];
}

- (void)refreshInBackgroundWithBlock:(PFObjectResultBlock)block {
    [self fetchInBackgroundWithBlock:block];
}

- (BFTask *)fetchInBackground {
    if (!self._state.objectId) {
        NSError *error = [PFErrorUtilities errorWithCode:kPFErrorMissingObjectId
                                                 message:@"Can't refresh an object that hasn't been saved to the server."];
        return [BFTask taskWithError:error];
    }
    return [self.taskQueue enqueue:^BFTask *(BFTask *toAwait) {
        return [self fetchAsync:toAwait];
    }];
}

- (void)fetchInBackgroundWithBlock:(PFObjectResultBlock)block {
    [[self fetchInBackground] thenCallBackOnMainThreadAsync:block];
}

- (BFTask *)fetchIfNeededInBackground {
    if (self.dataAvailable) {
        return [BFTask taskWithResult:self];
    }
    return [self fetchInBackground];
}

- (void)fetchIfNeededInBackgroundWithBlock:(PFObjectResultBlock)block {
    [[self fetchIfNeededInBackground] thenCallBackOnMainThreadAsync:block];
}

///--------------------------------------
#pragma mark - Fetching Many Objects
///--------------------------------------

+ (BFTask *)fetchAllInBackground:(NSArray *)objects {
    // Snapshot the objects array.
    NSArray *fetchObjects = [objects copy];

    if (fetchObjects.count == 0) {
        return [BFTask taskWithResult:fetchObjects];
    }
    NSArray *uniqueObjects = [PFObjectBatchController uniqueObjectsArrayFromArray:fetchObjects omitObjectsWithData:NO];
    return [[[[self currentUserController] getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        return [PFObject _enqueue:^BFTask *(BFTask *toAwait) {
            return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
                return [[self objectBatchController] fetchObjectsAsync:uniqueObjects withSessionToken:sessionToken];
            }];
        } forObjects:uniqueObjects];
    }] continueWithSuccessResult:fetchObjects];
}

+ (void)fetchAllInBackground:(NSArray *)objects block:(PFArrayResultBlock)block {
    [[self fetchAllInBackground:objects] thenCallBackOnMainThreadAsync:block];
}

+ (BFTask *)fetchAllIfNeededInBackground:(NSArray *)objects {
    NSArray *fetchObjects = [objects copy];
    if (fetchObjects.count == 0) {
        return [BFTask taskWithResult:fetchObjects];
    }
    NSArray *uniqueObjects = [PFObjectBatchController uniqueObjectsArrayFromArray:fetchObjects omitObjectsWithData:YES];
    return [[[[self currentUserController] getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;
        return [PFObject _enqueue:^BFTask *(BFTask *toAwait) {
            return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
                return [[self objectBatchController] fetchObjectsAsync:uniqueObjects withSessionToken:sessionToken];
            }];
        } forObjects:uniqueObjects];
    }] continueWithSuccessResult:fetchObjects];
}

+ (void)fetchAllIfNeededInBackground:(NSArray *)objects block:(PFArrayResultBlock)block {
    [[self fetchAllIfNeededInBackground:objects] thenCallBackOnMainThreadAsync:block];
}

///--------------------------------------
#pragma mark - Fetch From Local Datastore
///--------------------------------------

- (void)fetchFromLocalDatastoreInBackgroundWithBlock:(PFObjectResultBlock)block {
    [[self fetchFromLocalDatastoreInBackground] thenCallBackOnMainThreadAsync:block];
}

- (BFTask *)fetchFromLocalDatastoreInBackground {
    PFOfflineStore *store = [Parse _currentManager].offlineStore;
    PFConsistencyAssert(store != nil, @"You must enable the local datastore before calling fetchFromLocalDatastore().");
    return [store fetchObjectLocallyAsync:self];
}

///--------------------------------------
#pragma mark - Key/Value Accessors
///--------------------------------------

- (void)setObject:(id)object forKey:(NSString *)key {
    [self _setObject:object forKey:key onlyIfDifferent:NO];
}

- (void)setObject:(id)object forKeyedSubscript:(NSString *)key {
    [self setObject:object forKey:key];
}

- (id)objectForKey:(NSString *)key {
    @synchronized (lock) {
        PFConsistencyAssert([self isDataAvailableForKey:key],
                            @"Key \"%@\" has no data.  Call fetchIfNeeded before getting its value.", key);

        id result = _estimatedData[key];
        if ([key isEqualToString:PFObjectACLRESTKey] && [result isKindOfClass:[PFACL class]]) {
            PFACL *acl = result;
            if ([acl isShared]) {
                PFACL *copy = [acl createUnsharedCopy];
                self[PFObjectACLRESTKey] = copy;
                return copy;
            }
        }

        // A relation may be deserialized without a parent or key. Either way, make sure it's consistent.
        // TODO: (nlutsenko) This should be removable after we clean up the serialization code.
        if ([result isKindOfClass:[PFRelation class]]) {
            [result ensureParentIs:self andKeyIs:key];
        }

        return result;
    }
}

- (id)objectForKeyedSubscript:(NSString *)key {
    return [self objectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key {
    @synchronized (lock) {
        if (self[key]) {
            PFDeleteOperation *operation = [[PFDeleteOperation alloc] init];
            [self performOperation:operation forKey:key];
        }
    }
}

- (void)revert {
    @synchronized (self.lock) {
        if (self.dirty) {
            NSMutableSet *persistentKeys = [NSMutableSet setWithArray:self._state.serverData.allKeys];

            PFOperationSet *unsavedChanges = [self unsavedChanges];
            for (PFOperationSet *operationSet in operationSetQueue) {
                if (operationSet != unsavedChanges) {
                    [persistentKeys addObjectsFromArray:operationSet.keyEnumerator.allObjects];
                }
            }

            [unsavedChanges removeAllObjects];
            [_availableKeys intersectSet:persistentKeys];

            [self rebuildEstimatedData];
        }
    }
}

- (void)revertObjectForKey:(NSString *)key {
    @synchronized (self.lock) {
        if ([self isDirtyForKey:key]) {
            [[self unsavedChanges] removeObjectForKey:key];
            [self rebuildEstimatedData];
            [_availableKeys removeObject:key];
        }
    }
}

#pragma mark Relations

- (PFRelation *)relationforKey:(NSString *)key {
    return [self relationForKey:key];
}

- (PFRelation *)relationForKey:(NSString *)key {
    @synchronized (lock) {
        // All the sanity checking is done when addObject or
        // removeObject is called on the relation.
        PFRelation *relation = [PFRelation relationForObject:self forKey:key];

        id object = _estimatedData[key];
        if ([object isKindOfClass:[PFRelation class]]) {
            relation.targetClass = ((PFRelation *)object).targetClass;
        }
        return relation;
    }
}

#pragma mark Array

- (void)addObject:(id)object forKey:(NSString *)key {
    [self addObjectsFromArray:@[ object ] forKey:key];
}

- (void)addObjectsFromArray:(NSArray *)objects forKey:(NSString *)key {
    [self performOperation:[PFAddOperation addWithObjects:objects] forKey:key];
}

- (void)addUniqueObject:(id)object forKey:(NSString *)key {
    [self addUniqueObjectsFromArray:@[ object ] forKey:key];
}

- (void)addUniqueObjectsFromArray:(NSArray *)objects forKey:(NSString *)key {
    [self performOperation:[PFAddUniqueOperation addUniqueWithObjects:objects] forKey:key];
}

- (void)removeObject:(id)object forKey:(NSString *)key {
    [self removeObjectsInArray:@[ object ] forKey:key];
}

- (void)removeObjectsInArray:(NSArray *)objects forKey:(NSString *)key {
    [self performOperation:[PFRemoveOperation removeWithObjects:objects] forKey:key];
}

#pragma mark Increment

- (void)incrementKey:(NSString *)key {
    [self incrementKey:key byAmount:@1];
}

- (void)incrementKey:(NSString *)key byAmount:(NSNumber *)amount {
    [self performOperation:[PFIncrementOperation incrementWithAmount:amount] forKey:key];
}

///--------------------------------------
#pragma mark - Key Value Coding
///--------------------------------------

- (id)valueForUndefinedKey:(NSString *)key {
    return self[key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    self[key] = value;
}

- (void)setValuesForKeysWithDictionary:(NSDictionary<NSString *,id> *)keyedValues {
    // This is overwritten to make sure we don't use `nil` instead of `NSNull` (the default NSObject implementation).
    // Remove this if we 100% conform to KVC.
    [keyedValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key];
    }];
}

///--------------------------------------
#pragma mark - Misc
///--------------------------------------

- (NSArray *)allKeys {
    @synchronized (lock) {
        return _estimatedData.allKeys;
    }
}

- (NSString *)description {
    static NSString *descriptionKey = @"PFObject-PrintingDescription";

    NSMutableDictionary *threadDictionary = [NSThread currentThread].threadDictionary;
    if ([threadDictionary[descriptionKey] boolValue]) {
        return [self _flatDescription];
    }
    threadDictionary[descriptionKey] = @YES;
    NSString *description = [self _recursiveDescription];
    [threadDictionary removeObjectForKey:descriptionKey];
    return description;
}

- (NSString *)_recursiveDescription {
    @synchronized (lock) {
        return [NSString stringWithFormat:@"%@ %@",
                [self _flatDescription], _estimatedData.dictionaryRepresentation.description];
    }
}

- (NSString *)_flatDescription {
    @synchronized (lock) {
        return [NSString stringWithFormat:@"<%@: %p, objectId: %@, localId: %@>",
                self.displayClassName, self, [self displayObjectId], localId];
    }
}

///--------------------------------------
#pragma mark - Save all
///--------------------------------------

+ (BFTask *)saveAllInBackground:(NSArray *)objects {
    PFCurrentUserController *controller = [[self class] currentUserController];
    return [[controller getCurrentObjectAsync] continueWithBlock:^id(BFTask *task) {
        PFUser *currentUser = task.result;
        NSString *sessionToken = currentUser.sessionToken;
        return [self _deepSaveAsyncChildrenOfObject:objects withCurrentUser:currentUser sessionToken:sessionToken];
    }];
}

+ (void)saveAllInBackground:(NSArray *)objects block:(PFBooleanResultBlock)block {
    [[PFObject saveAllInBackground:objects] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

///--------------------------------------
#pragma mark - Delete all
///--------------------------------------

+ (BFTask<NSNumber *> *)deleteAllInBackground:(NSArray *)objects {
    NSArray *deleteObjects = [objects copy]; // Snapshot the objects.
    if (deleteObjects.count == 0) {
        return [BFTask<NSNumber *> taskWithResult:@YES];
    }
    return [[[[self currentUserController] getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        NSString *sessionToken = task.result;

        NSArray *uniqueObjects = [PFObjectBatchController uniqueObjectsArrayFromArray:deleteObjects usingFilter:^BOOL(PFObject *object) {
            return (object.objectId != nil);
        }];
        NSMutableArray<BFTask<PFVoid> *> *validationTasks = [NSMutableArray array];
        for (PFObject *object in uniqueObjects) {
            [validationTasks addObject:[object _validateDeleteAsync]];
        }
        return [[BFTask taskForCompletionOfAllTasks:validationTasks] continueWithSuccessBlock:^id(BFTask *task) {
            return [self _enqueue:^BFTask *(BFTask *toAwait) {
                return [toAwait continueAsyncWithBlock:^id(BFTask *task) {
                    return [[self objectBatchController] deleteObjectsAsync:uniqueObjects
                                                           withSessionToken:sessionToken];
                }];
            } forObjects:uniqueObjects];
        }];
    }] continueWithSuccessResult:@YES];
}

+ (void)deleteAllInBackground:(NSArray *)objects block:(PFBooleanResultBlock)block {
    [[self deleteAllInBackground:objects] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

///--------------------------------------
#pragma mark - Dynamic synthesizers
///--------------------------------------

// NOTE: The ONLY reason this needs to exist is to support mocking PFObject subclasses.
//
// The reason mocking doesn't work is because OCMClassMock looks for methods that exist on the class already, and will
// not be able to use our dynamic instance-level method resolving. By implementing this, we give this method a signature
// once, and then tell the runtime to forward that message on from there.
//
// Note that by implementing it this way, we no longer need to implement -methodSignatureForSelector: or
// -respondsToSelector:, as the method will be dynamically resolved by the runtime when either of those methods is
// invoked.
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (self == [PFObject class]) {
        return NO;
    }

    NSMethodSignature *signature = [[self subclassingController] forwardingMethodSignatureForSelector:sel ofClass:self];
    if (!signature) {
        return NO;
    }

    // Convert the method signature *back* into a objc type string (sidenote, why isn't this a built in?).
    NSMutableString *typeString = [NSMutableString stringWithFormat:@"%s", signature.methodReturnType];
    for (NSUInteger argumentIndex = 0; argumentIndex < signature.numberOfArguments; argumentIndex++) {
        [typeString appendFormat:@"%s", [signature getArgumentTypeAtIndex:argumentIndex]];
    }

    // TODO: (richardross) Support stret return here (will need to introspect the method signature to do so).
    class_addMethod(self, sel, _objc_msgForward, typeString.UTF8String);

    return YES;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if (![[[self class] subclassingController] forwardObjectInvocation:anInvocation
                                                            withObject:(PFObject<PFSubclassing> *)self]) {
        [self doesNotRecognizeSelector:anInvocation.selector];
    }
}

///--------------------------------------
#pragma mark - Pinning
///--------------------------------------

- (BFTask<NSNumber *> *)pinInBackground {
    return [self pinInBackgroundWithName:PFObjectDefaultPin];
}

- (void)pinInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [[self pinInBackground] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

- (void)pinInBackgroundWithName:(NSString *)name block:(PFBooleanResultBlock)block {
    [[self pinInBackgroundWithName:name] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

- (BFTask<NSNumber *> *)pinInBackgroundWithName:(NSString *)name {
    return [self _pinInBackgroundWithName:name includeChildren:YES];
}

- (BFTask<NSNumber *> *)_pinInBackgroundWithName:(NSString *)name includeChildren:(BOOL)includeChildren {
    return [[self class] _pinAllInBackground:@[ self ] withName:name includeChildren:includeChildren];
}

///--------------------------------------
#pragma mark - Pinning Many Objects
///--------------------------------------

+ (BFTask<NSNumber *> *)pinAllInBackground:(NSArray *)objects {
    return [self pinAllInBackground:objects withName:PFObjectDefaultPin];
}

+ (void)pinAllInBackground:(NSArray *)objects
                     block:(PFBooleanResultBlock)block {
    [[self pinAllInBackground:objects] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

+ (BFTask<NSNumber *> *)pinAllInBackground:(NSArray *)objects withName:(NSString *)name {
    return [self _pinAllInBackground:objects withName:name includeChildren:YES];
}

+ (void)pinAllInBackground:(NSArray *)objects
                  withName:(NSString *)name
                     block:(PFBooleanResultBlock)block {
    [[self pinAllInBackground:objects withName:name] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

+ (BFTask<NSNumber *> *)_pinAllInBackground:(NSArray *)objects withName:(NSString *)name includeChildren:(BOOL)includeChildren {
    return [[[self pinningObjectStore] pinObjectsAsync:objects
                                           withPinName:name
                                       includeChildren:includeChildren] continueWithSuccessResult:@YES];
}

///--------------------------------------
#pragma mark - Unpinning
///--------------------------------------

- (BFTask<NSNumber *> *)unpinInBackground {
    return [self unpinInBackgroundWithName:PFObjectDefaultPin];
}

- (void)unpinInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [[self unpinInBackground] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

- (BFTask<NSNumber *> *)unpinInBackgroundWithName:(NSString *)name {
    return [[self class] unpinAllInBackground:@[ self ] withName:name];
}

- (void)unpinInBackgroundWithName:(NSString *)name block:(PFBooleanResultBlock)block {
    [[self unpinInBackgroundWithName:name] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

///--------------------------------------
#pragma mark - Unpinning Many Objects
///--------------------------------------

+ (BFTask<NSNumber *> *)unpinAllObjectsInBackground {
    return [self unpinAllObjectsInBackgroundWithName:PFObjectDefaultPin];
}

+ (void)unpinAllObjectsInBackgroundWithBlock:(PFBooleanResultBlock)block {
    [[self unpinAllObjectsInBackground] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

+ (void)unpinAllObjectsInBackgroundWithName:(NSString *)name block:(PFBooleanResultBlock)block {
    [[self unpinAllObjectsInBackgroundWithName:name] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

+ (BFTask<NSNumber *> *)unpinAllObjectsInBackgroundWithName:(NSString *)name {
    return [[[self pinningObjectStore] unpinAllObjectsAsyncWithPinName:name] continueWithSuccessResult:@YES];
}

+ (BFTask *)unpinAllInBackground:(NSArray *)objects {
    return [self unpinAllInBackground:objects withName:PFObjectDefaultPin];
}

+ (void)unpinAllInBackground:(NSArray *)objects block:(PFBooleanResultBlock)block {
    [[self unpinAllInBackground:objects] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

+ (BFTask<NSNumber *> *)unpinAllInBackground:(NSArray *)objects withName:(NSString *)name {
    return [[[self pinningObjectStore] unpinObjectsAsync:objects withPinName:name] continueWithSuccessResult:@YES];
}

+ (void)unpinAllInBackground:(NSArray *)objects withName:(NSString *)name block:(PFBooleanResultBlock)block {
    [[self unpinAllInBackground:objects withName:name] thenCallBackOnMainThreadWithBoolValueAsync:block];
}

///--------------------------------------
#pragma mark - Data Source
///--------------------------------------

+ (id<PFObjectControlling>)objectController {
    return [Parse _currentManager].coreManager.objectController;
}

+ (PFObjectFileCodingLogic *)objectFileCodingLogic {
    return [PFObjectFileCodingLogic codingLogic];
}

+ (PFObjectBatchController *)objectBatchController {
    return [Parse _currentManager].coreManager.objectBatchController;
}

+ (PFPinningObjectStore *)pinningObjectStore {
    return [Parse _currentManager].coreManager.pinningObjectStore;
}

+ (PFCurrentUserController *)currentUserController {
    return [Parse _currentManager].coreManager.currentUserController;
}

+ (PFObjectSubclassingController *)subclassingController {
    return [Parse _currentManager].coreManager.objectSubclassingController;
}

@end

///--------------------------------------
#pragma mark - Synchronous
///--------------------------------------

@implementation PFObject (Synchronous)

#pragma mark Saving Objects

- (BOOL)save {
    return [self save:nil];
}

- (BOOL)save:(NSError **)error {
    return [[[self saveInBackground] waitForResult:error] boolValue];
}

#pragma mark Saving Many Objects

+ (BOOL)saveAll:(NSArray *)objects {
    return [PFObject saveAll:objects error:nil];
}

+ (BOOL)saveAll:(NSArray *)objects error:(NSError **)error {
    return [[[self saveAllInBackground:objects] waitForResult:error] boolValue];
}

#pragma mark Getting an Object

- (instancetype)fetch {
    return [self fetch:nil];
}

- (instancetype)fetch:(NSError **)error {
    return [[self fetchInBackground] waitForResult:error];
}

- (instancetype)fetchIfNeeded {
    return [self fetchIfNeeded:nil];
}

- (instancetype)fetchIfNeeded:(NSError **)error {
    return [[self fetchIfNeededInBackground] waitForResult:error];
}

#pragma mark Getting Many Objects

+ (NSArray *)fetchAll:(NSArray *)objects {
    return [self fetchAll:objects error:nil];
}

+ (NSArray *)fetchAll:(NSArray *)objects error:(NSError **)error {
    return [[self fetchAllInBackground:objects] waitForResult:error];
}

+ (NSArray *)fetchAllIfNeeded:(NSArray *)objects {
    return [self fetchAllIfNeeded:objects error:nil];
}

+ (NSArray *)fetchAllIfNeeded:(NSArray *)objects error:(NSError **)error {
    return [[self fetchAllIfNeededInBackground:objects] waitForResult:error];
}

#pragma mark Fetching From Local Datastore

- (instancetype)fetchFromLocalDatastore {
    return [self fetchFromLocalDatastore:nil];
}

- (instancetype)fetchFromLocalDatastore:(NSError **)error {
    return [[self fetchFromLocalDatastoreInBackground] waitForResult:error];
}

#pragma mark Deleting an Object

- (BOOL)delete {
    return [self delete:nil];
}

- (BOOL)delete:(NSError **)error {
    return [[[self deleteInBackground] waitForResult:error] boolValue];
}

#pragma mark Deleting Many Objects

+ (BOOL)deleteAll:(NSArray *)objects {
    return [PFObject deleteAll:objects error:nil];
}

+ (BOOL)deleteAll:(NSArray *)objects error:(NSError **)error {
    return [[[self deleteAllInBackground:objects] waitForResult:error] boolValue];
}

#pragma mark Pinning

- (BOOL)pin {
    return [self pin:nil];
}

- (BOOL)pin:(NSError **)error {
    return [self pinWithName:PFObjectDefaultPin error:error];
}

- (BOOL)pinWithName:(NSString *)name {
    return [self pinWithName:name error:nil];
}

- (BOOL)pinWithName:(NSString *)name error:(NSError **)error {
    return [[[self pinInBackgroundWithName:name] waitForResult:error] boolValue];
}

#pragma mark Pinning Many Objects

+ (BOOL)pinAll:(NSArray *)objects {
    return [self pinAll:objects error:nil];
}

+ (BOOL)pinAll:(NSArray *)objects error:(NSError **)error {
    return [self pinAll:objects withName:PFObjectDefaultPin error:error];
}

+ (BOOL)pinAll:(NSArray *)objects withName:(NSString *)name {
    return [self pinAll:objects withName:name error:nil];
}

+ (BOOL)pinAll:(NSArray *)objects withName:(NSString *)name error:(NSError **)error {
    return [[[self pinAllInBackground:objects withName:name] waitForResult:error] boolValue];
}

#pragma mark Unpinning

- (BOOL)unpin {
    return [self unpinWithName:PFObjectDefaultPin];
}

- (BOOL)unpin:(NSError **)error {
    return [self unpinWithName:PFObjectDefaultPin error:error];
}

- (BOOL)unpinWithName:(NSString *)name {
    return [self unpinWithName:name error:nil];
}

- (BOOL)unpinWithName:(NSString *)name error:(NSError **)error {
    return [[[self unpinInBackgroundWithName:name] waitForResult:error] boolValue];
}

#pragma mark Unpinning Many Objects

+ (BOOL)unpinAllObjects {
    return [self unpinAllObjects:nil];
}

+ (BOOL)unpinAllObjects:(NSError **)error {
    return [self unpinAllObjectsWithName:PFObjectDefaultPin error:error];
}

+ (BOOL)unpinAllObjectsWithName:(NSString *)name {
    return [self unpinAllObjectsWithName:name error:nil];
}

+ (BOOL)unpinAllObjectsWithName:(NSString *)name error:(NSError **)error {
    return [[[self unpinAllObjectsInBackgroundWithName:name] waitForResult:error] boolValue];
}

+ (BOOL)unpinAll:(NSArray *)objects {
    return [self unpinAll:objects error:nil];
}

+ (BOOL)unpinAll:(NSArray *)objects error:(NSError **)error {
    return [self unpinAll:objects withName:PFObjectDefaultPin error:error];
}

+ (BOOL)unpinAll:(NSArray *)objects withName:(NSString *)name {
    return [self unpinAll:objects withName:name error:nil];
}

+ (BOOL)unpinAll:(NSArray *)objects withName:(NSString *)name error:(NSError **)error {
    return [[[self unpinAllInBackground:objects withName:name] waitForResult:error] boolValue];
}

@end

///--------------------------------------
#pragma mark - Deprecated
///--------------------------------------

@implementation PFObject (Deprecated)

#pragma mark Saving Objects

- (void)saveInBackgroundWithTarget:(nullable id)target selector:(nullable SEL)selector {
    [self saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

#pragma mark Saving Many Objects

+ (void)saveAllInBackground:(NSArray<PFObject *> *)objects target:(nullable id)target selector:(nullable SEL)selector {
    [self saveAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

#pragma mark Getting an Object

- (void)refreshInBackgroundWithTarget:(nullable id)target selector:(nullable SEL)selector {
    [self fetchInBackgroundWithTarget:target selector:selector];
}

- (void)fetchInBackgroundWithTarget:(nullable id)target selector:(nullable SEL)selector {
    [self fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:object object:error];
    }];
}

- (void)fetchIfNeededInBackgroundWithTarget:(nullable id)target selector:(nullable SEL)selector {
    [self fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:object object:error];
    }];
}

#pragma mark Getting Many Objects

+ (void)fetchAllInBackground:(NSArray<PFObject *> *)objects target:(nullable id)target selector:(nullable SEL)selector {
    [self fetchAllInBackground:objects block:^(NSArray *objects, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:objects object:error];
    }];
}

+ (void)fetchAllIfNeededInBackground:(NSArray<PFObject *> *)objects target:(nullable id)target selector:(nullable SEL)selector {
    [self fetchAllIfNeededInBackground:objects block:^(NSArray *objects, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:objects object:error];
    }];
}

#pragma mark Deleting an Object

- (void)deleteInBackgroundWithTarget:(nullable id)target selector:(nullable SEL)selector {
    [self deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

#pragma mark Deleting Many Objects

+ (void)deleteAllInBackground:(NSArray<PFObject *> *)objects target:(nullable id)target selector:(nullable SEL)selector {
    [self deleteAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
        [PFInternalUtils safePerformSelector:selector withTarget:target object:@(succeeded) object:error];
    }];
}

@end
