/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectBatchController.h"

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
#pragma mark - Utilities
///--------------------------------------

+ (NSArray *)uniqueObjectsArrayFromArray:(NSArray *)objects omitObjectsWithData:(BOOL)omitFetched {
    if (objects.count == 0) {
        return objects;
    }

    NSMutableSet *set = [NSMutableSet setWithCapacity:[objects count]];
    NSString *className = [objects.firstObject parseClassName];
    for (PFObject *object in objects) {
        @synchronized (object.lock) {
            if (omitFetched && [object isDataAvailable]) {
                continue;
            }

            PFParameterAssert([className isEqualToString:object.parseClassName],
                              @"All object should be in the same class.");
            PFParameterAssert(object.objectId != nil,
                              @"All objects must exist on the server.");

            [set addObject:object];
        }
    }
    return [set allObjects];
}

@end
