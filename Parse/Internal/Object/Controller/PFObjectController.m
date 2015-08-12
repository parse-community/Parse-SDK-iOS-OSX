/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectController.h"
#import "PFObjectController_Private.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandResult.h"
#import "PFCommandRunning.h"
#import "PFErrorUtilities.h"
#import "PFMacros.h"
#import "PFObjectPrivate.h"
#import "PFObjectState.h"
#import "PFRESTObjectCommand.h"
#import "PFTaskQueue.h"

@implementation PFObjectController

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
#pragma mark - PFObjectControlling
///--------------------------------------

#pragma mark Fetch

- (BFTask *)fetchObjectAsync:(PFObject *)object withSessionToken:(NSString *)sessionToken {
    @weakify(self);
    return [[[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        PFObjectState *state = [object._state copy];
        if (!state.objectId) {
            NSError *error = [PFErrorUtilities errorWithCode:kPFErrorMissingObjectId
                                                     message:@"Can't fetch an object that hasn't been saved to the server."];
            return [BFTask taskWithError:error];
        }
        PFRESTCommand *command = [PFRESTObjectCommand fetchObjectCommandForObjectState:state
                                                                      withSessionToken:sessionToken];
        return [self _runFetchCommand:command forObject:object];
    }] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        PFCommandResult *result = task.result;
        return [self processFetchResultAsync:result.result forObject:object];
    }] continueWithSuccessResult:object];
}

- (BFTask *)_runFetchCommand:(PFRESTCommand *)command forObject:(PFObject *)object {
    return [self.dataSource.commandRunner runCommandAsync:command withOptions:PFCommandRunningOptionRetryIfFailed];
}

- (BFTask *)processFetchResultAsync:(NSDictionary *)result forObject:(PFObject *)object {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        NSDictionary *fetchedObjects = [object _collectFetchedObjects];
        @synchronized (object.lock) {
            PFKnownParseObjectDecoder *decoder = [PFKnownParseObjectDecoder decoderWithFetchedObjects:fetchedObjects];
            [object _mergeAfterFetchWithResult:result decoder:decoder completeData:YES];
        }
        return nil;
    }];
}

#pragma mark Delete

- (BFTask *)deleteObjectAsync:(PFObject *)object withSessionToken:(nullable NSString *)sessionToken {
    @weakify(self);
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        PFObjectState *state = [object._state copy];
        if (!state.objectId) {
            return nil;
        }

        PFRESTCommand *command = [PFRESTObjectCommand deleteObjectCommandForObjectState:state
                                                                       withSessionToken:sessionToken];
        return [[self _runDeleteCommand:command forObject:object] continueWithBlock:^id(BFTask *fetchTask) {
            @strongify(self);
            PFCommandResult *result = fetchTask.result;
            return [[self processDeleteResultAsync:result.result forObject:object] continueWithBlock:^id(BFTask *task) {
                // Propagate the result of network task if it's faulted, cancelled.
                if (fetchTask.faulted || fetchTask.cancelled) {
                    return fetchTask;
                }
                // Propagate the result of processDeleteResult otherwise.
                return task;
            }];
        }];
    }];
}

- (BFTask *)_runDeleteCommand:(PFRESTCommand *)command forObject:(PFObject *)object {
    return [self.dataSource.commandRunner runCommandAsync:command withOptions:PFCommandRunningOptionRetryIfFailed];
}

- (BFTask *)processDeleteResultAsync:(NSDictionary *)result forObject:(PFObject *)object {
    return [BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        BOOL deleted = (result != nil);
        [object _setDeleted:deleted];
        return nil;
    }];
}

@end
