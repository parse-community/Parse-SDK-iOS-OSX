/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectBatchController.h"

#import <Bolts/Bolts.h>

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFErrorUtilities.h"
#import "PFMacros.h"
#import "PFObjectController.h"
#import "PFObjectPrivate.h"
#import "PFQueryPrivate.h"
#import "PFRESTQueryCommand.h"
#import "PFRESTObjectCommand.h"
#import "PFRESTObjectBatchCommand.h"

@implementation PFObjectBatchController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Fetch
///--------------------------------------

- (BFTask *)fetchObjectsAsync:(NSArray *)objects withSessionToken:(NSString *)sessionToken {
    if (objects.count == 0) {
        return [BFTask taskWithResult:objects];
    }

    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        PFRESTCommand *command = [self _fetchCommandForObjects:objects withSessionToken:sessionToken];
        return [self.dataSource.commandRunner runCommandAsync:command
                                                  withOptions:PFCommandRunningOptionRetryIfFailed];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        PFCommandResult *result = task.result;
        return [self _processFetchResultAsync:result.result forObjects:objects];
    }];
}

- (PFRESTCommand *)_fetchCommandForObjects:(NSArray *)objects withSessionToken:(NSString *)sessionToken {
    NSArray *objectIds = [objects valueForKey:@keypath(PFObject, objectId)];
    PFQuery *query = [PFQuery queryWithClassName:[objects.firstObject parseClassName]];
    [query whereKey:@keypath(PFObject, objectId) containedIn:objectIds];
    query.limit = objectIds.count;
    return [PFRESTQueryCommand findCommandForQueryState:query.state withSessionToken:sessionToken];
}

- (BFTask *)_processFetchResultAsync:(NSDictionary *)result forObjects:(NSArray *)objects {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSArray *results = result[@"results"]; // TODO: (nlutsenko) Move this logic into command itself?
        NSArray *objectIds = [results valueForKey:@keypath(PFObject, objectId)];
        NSDictionary *objectResults = [NSDictionary dictionaryWithObjects:results forKeys:objectIds];

        NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:objects.count];
        for (PFObject *object in objects) {
            PFObjectController *controller = [[object class] objectController];
            NSDictionary *objectResult = objectResults[object.objectId];

            BFTask *task = nil;
            if (objectResult) {
                task = [controller processFetchResultAsync:objectResult forObject:object];
            } else {
                NSError *error = [PFErrorUtilities errorWithCode:kPFErrorObjectNotFound
                                                         message:@"Object not found on the server."];
                task = [BFTask taskWithError:error];
            }
            [tasks addObject:task];
        }
        return [BFTask taskForCompletionOfAllTasks:tasks];
    }];
}

///--------------------------------------
#pragma mark - Delete
///--------------------------------------

- (BFTask *)deleteObjectsAsync:(NSArray *)objects withSessionToken:(NSString *)sessionToken {
    if (objects.count == 0) {
        return [BFTask taskWithResult:objects];
    }

    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        NSArray *objectBatches = [PFInternalUtils arrayBySplittingArray:objects
                                        withMaximumComponentsPerSegment:PFRESTObjectBatchCommandSubcommandsLimit];
        NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:objectBatches.count];
        for (NSArray *batch in objectBatches) {
            PFRESTCommand *command = [self _deleteCommandForObjects:batch withSessionToken:sessionToken];
            BFTask *task = [[self.dataSource.commandRunner runCommandAsync:command
                                                              withOptions:PFCommandRunningOptionRetryIfFailed] continueWithSuccessBlock:^id(BFTask *task) {
                PFCommandResult *result = task.result;
                return [self _processDeleteResultsAsync:[result result] forObjects:batch];
            }];
            [tasks addObject:task];
        }
        return [[BFTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id(BFTask *task) {
            NSError *taskError = task.error;
            if (taskError && [taskError.domain isEqualToString:BFTaskErrorDomain]) {
                NSArray *taskErrors = taskError.userInfo[@"errors"];
                NSMutableArray *errors = [NSMutableArray array];
                for (NSError *error in taskErrors) {
                    if ([error.domain isEqualToString:BFTaskErrorDomain]) {
                        [errors addObjectsFromArray:error.userInfo[@"errors"]];
                    } else {
                        [errors addObject:error];
                    }
                }
                return [BFTask taskWithError:[NSError errorWithDomain:BFTaskErrorDomain
                                                                 code:kBFMultipleErrorsError
                                                             userInfo:@{ @"errors" : errors }]];
            }
            return task;
        }];
    }] continueWithSuccessResult:objects];
}

- (PFRESTCommand *)_deleteCommandForObjects:(NSArray *)objects withSessionToken:(NSString *)sessionToken {
    NSMutableArray *commands = [NSMutableArray arrayWithCapacity:objects.count];
    for (PFObject *object in objects) {
        PFRESTCommand *deleteCommand = [PFRESTObjectCommand deleteObjectCommandForObjectState:object._state
                                                                             withSessionToken:sessionToken];
        [commands addObject:deleteCommand];
    }
    return [PFRESTObjectBatchCommand batchCommandWithCommands:commands sessionToken:sessionToken];
}

- (BFTask *)_processDeleteResultsAsync:(NSArray *)results forObjects:(NSArray *)objects {
    NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:results.count];
    [results enumerateObjectsUsingBlock:^(NSDictionary *result, NSUInteger idx, BOOL *stop) {
        PFObject *object = objects[idx];
        NSDictionary *errorResult = result[@"error"];
        NSDictionary *successResult = result[@"success"];

        id<PFObjectControlling> controller = [[object class] objectController];
        BFTask *task = [controller processDeleteResultAsync:successResult forObject:object];
        if (errorResult) {
            task = [task continueWithBlock:^id(BFTask *task) {
                return [BFTask taskWithError:[PFErrorUtilities errorFromResult:errorResult]];
            }];
        }
        [tasks addObject:task];
    }];
    return [BFTask taskForCompletionOfAllTasks:tasks];
}

///--------------------------------------
#pragma mark - Utilities
///--------------------------------------

//TODO: (nlutsenko) Convert to use `uniqueObjectsArrayFromArray:usingFilter:`
+ (NSArray *)uniqueObjectsArrayFromArray:(NSArray *)objects omitObjectsWithData:(BOOL)omitFetched {
    if (objects.count == 0) {
        return objects;
    }

    NSMutableSet *set = [NSMutableSet setWithCapacity:[objects count]];
    NSString *className = [objects.firstObject parseClassName];
    for (PFObject *object in objects) {
        @synchronized (object.lock) {
            if (omitFetched && object.dataAvailable) {
                continue;
            }

            //TODO: (nlutsenko) Convert to using errors instead of assertions.
            PFParameterAssert([className isEqualToString:object.parseClassName],
                              @"All object should be in the same class.");
            PFParameterAssert(object.objectId != nil,
                              @"All objects must exist on the server.");

            [set addObject:object];
        }
    }
    return [set allObjects];
}

+ (NSArray *)uniqueObjectsArrayFromArray:(NSArray *)objects usingFilter:(BOOL (^)(PFObject *object))filter {
    if (objects.count == 0) {
        return objects;
    }

    NSMutableDictionary *uniqueObjects = [NSMutableDictionary dictionary];
    for (PFObject *object in objects) {
        if (!filter(object)) {
            continue;
        }

        // Use stringWithFormat: in case objectId or parseClassName are nil.
        NSString *objectIdentifier = [NSString stringWithFormat:@"%@%@", object.parseClassName, object.objectId];
        if (!uniqueObjects[objectIdentifier]) {
            uniqueObjects[objectIdentifier] = object;
        }
    }
    return [uniqueObjects allValues];
}

@end
