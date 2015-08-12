/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFOfflineQueryController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCommandRunning.h"
#import "PFObjectPrivate.h"
#import "PFOfflineStore.h"
#import "PFPin.h"
#import "PFPinningObjectStore.h"
#import "PFQueryState.h"
#import "PFRESTCommand.h"
#import "PFRelationPrivate.h"

@interface PFOfflineQueryController () {
    PFOfflineStore *_offlineStore; // TODO: (nlutsenko) Lazy-load this via self.dataSource.
}

@end

@implementation PFOfflineQueryController

@dynamic commonDataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider, PFOfflineStoreProvider>)dataSource {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider, PFOfflineStoreProvider>)dataSource
                          coreDataSource:(id<PFPinningObjectStoreProvider>)coreDataSource {
    self = [super initWithCommonDataSource:dataSource];
    if (!self) return nil;

    _offlineStore = dataSource.offlineStore;
    _coreDataSource = coreDataSource;

    return self;
}

+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider, PFOfflineStoreProvider>)dataSource
                                coreDataSource:(id<PFPinningObjectStoreProvider>)coreDataSource {
    return [[self alloc] initWithCommonDataSource:dataSource coreDataSource:coreDataSource];
}

///--------------------------------------
#pragma mark - Find
///--------------------------------------

- (BFTask *)findObjectsAsyncForQueryState:(PFQueryState *)queryState
                    withCancellationToken:(BFCancellationToken *)cancellationToken
                                     user:(PFUser *)user {
    if (queryState.queriesLocalDatastore) {
        return [self _findObjectsFromLocalDatastoreAsyncForQueryState:queryState
                                                withCancellationToken:cancellationToken
                                                                 user:user];
    }

    NSDictionary *relationCondition = queryState.conditions[@"$relatedTo"];
    if (relationCondition) {
        PFObject *object = relationCondition[@"object"];
        NSString *key = relationCondition[@"key"];
        if ([object isDataAvailableForKey:key]) {
            PFRelation *relation = object[key];
            return [self _findObjectsAsyncInRelation:relation
                                            ofObject:object
                                       forQueryState:queryState
                               withCancellationToken:cancellationToken
                                                user:user];
        }
    }

    return [super findObjectsAsyncForQueryState:queryState withCancellationToken:cancellationToken user:user];
}

- (BFTask *)_findObjectsAsyncInRelation:(PFRelation *)relation
                               ofObject:(PFObject *)parentObject
                          forQueryState:(PFQueryState *)queryState
                  withCancellationToken:(BFCancellationToken *)cancellationToken
                                   user:(PFUser *)user {
    return [[super findObjectsAsyncForQueryState:queryState
                           withCancellationToken:cancellationToken
                                            user:user] continueWithSuccessBlock:^id(BFTask *fetchTask) {

        NSArray *objects = fetchTask.result;
        for (PFObject *object in objects) {
            [relation _addKnownObject:object];
        }

        return [[_offlineStore updateDataForObjectAsync:parentObject] continueWithBlock:^id(BFTask *task) {
            // Roll-forward the result of find task instead of a result of update task.
            return fetchTask;
        } cancellationToken:cancellationToken];
    } cancellationToken:cancellationToken];
}


- (BFTask *)_findObjectsFromLocalDatastoreAsyncForQueryState:(PFQueryState *)queryState
                                       withCancellationToken:(BFCancellationToken *)cancellationToken
                                                        user:(PFUser *)user {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        if (cancellationToken.cancellationRequested) {
            return [BFTask cancelledTask];
        }

        NSString *pinName = queryState.localDatastorePinName;
        if (pinName) {
            PFPinningObjectStore *objectStore = self.coreDataSource.pinningObjectStore;
            return [objectStore fetchPinAsyncWithName:pinName];
        }
        return nil;
    }] continueWithSuccessBlock:^id(BFTask *task) {
        PFPin *pin = task.result;
        return [_offlineStore findAsyncForQueryState:queryState user:user pin:pin];
    } cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - Count
///--------------------------------------

- (BFTask *)countObjectsAsyncForQueryState:(PFQueryState *)queryState
                     withCancellationToken:(BFCancellationToken *)cancellationToken
                                      user:(PFUser *)user {
    if (queryState.queriesLocalDatastore) {
        return [self _countObjectsFromLocalDatastoreAsyncForQueryState:queryState
                                                 withCancellationToken:cancellationToken
                                                                  user:user];
    }
    return [super countObjectsAsyncForQueryState:queryState withCancellationToken:cancellationToken user:user];
}

- (BFTask *)_countObjectsFromLocalDatastoreAsyncForQueryState:(PFQueryState *)queryState
                                        withCancellationToken:(BFCancellationToken *)cancellationToken
                                                         user:(PFUser *)user {
    @weakify(self);
    return [[BFTask taskFromExecutor:[BFExecutor defaultPriorityBackgroundExecutor] withBlock:^id{
        @strongify(self);
        if (cancellationToken.cancellationRequested) {
            return [BFTask cancelledTask];
        }

        NSString *pinName = queryState.localDatastorePinName;
        if (pinName) {
            PFPinningObjectStore *controller = self.coreDataSource.pinningObjectStore;
            return [controller fetchPinAsyncWithName:pinName];
        }
        return nil;
    }] continueWithSuccessBlock:^id(BFTask *task) {
        PFPin *pin = task.result;
        return [_offlineStore countAsyncForQueryState:queryState user:user pin:pin];
    } cancellationToken:cancellationToken];
}

///--------------------------------------
#pragma mark - PFQueryControllerSubclass
///--------------------------------------

- (BFTask *)runNetworkCommandAsync:(PFRESTCommand *)command
             withCancellationToken:(BFCancellationToken *)cancellationToken
                     forQueryState:(PFQueryState *)queryState {
    return [self.commonDataSource.commandRunner runCommandAsync:command
                                                    withOptions:PFCommandRunningOptionRetryIfFailed
                                              cancellationToken:cancellationToken];
}

@end
