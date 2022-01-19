/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPinningObjectStore.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFMacros.h"
#import "PFOfflineStore.h"
#import "PFPin.h"
#import "PFQueryPrivate.h"

@interface PFPinningObjectStore () {
    NSMapTable<NSString *, BFTask<PFPin *> *> *_pinCacheTable;
    dispatch_queue_t _pinCacheAccessQueue;
    BFExecutor *_pinCacheAccessExecutor;
}

@end

@implementation PFPinningObjectStore

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFOfflineStoreProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _pinCacheTable = [NSMapTable strongToWeakObjectsMapTable];
    _pinCacheAccessQueue = dispatch_queue_create("com.parse.object.pin.cache", DISPATCH_QUEUE_SERIAL);
    _pinCacheAccessExecutor = [BFExecutor executorWithDispatchQueue:_pinCacheAccessQueue];

    _dataSource = dataSource;

    return self;
}

+ (instancetype)storeWithDataSource:(id<PFOfflineStoreProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Pin
///--------------------------------------

- (BFTask<PFPin *> *)fetchPinAsyncWithName:(NSString *)name {
    @weakify(self);
    return [BFTask taskFromExecutor:_pinCacheAccessExecutor withBlock:^id{
        BFTask *cachedTask = [self->_pinCacheTable objectForKey:name] ?: [BFTask taskWithResult:nil];
        // We need to call directly to OfflineStore since we don't want/need a user to query for ParsePins
        cachedTask = [cachedTask continueWithBlock:^id(BFTask *task) {
            @strongify(self);
            PFQuery *query = [[PFPin query] whereKey:PFPinKeyName equalTo:name];
            PFOfflineStore *store = self.dataSource.offlineStore;
            return [[store findAsyncForQueryState:query.state
                                             user:nil
                                              pin:nil] continueWithSuccessBlock:^id(BFTask *task) {
                NSArray *result = task.result;
                // TODO (hallucinogen): What do we do if there are more than 1 result?
                PFPin *pin = (result.count != 0 ? result.firstObject : [PFPin pinWithName:name]);
                return pin;
            }];
        }];
        // Put the task back into the cache.
        [self->_pinCacheTable setObject:cachedTask forKey:name];
        return cachedTask;
    }];
}

- (BFTask<PFVoid> *)pinObjectsAsync:(NSArray *)objects withPinName:(NSString *)name includeChildren:(BOOL)includeChildren {
    if (objects.count == 0) {
        return [BFTask taskWithResult:nil];
    }

    @weakify(self);
    return [[self fetchPinAsyncWithName:name] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        PFPin *pin = task.result;
        PFOfflineStore *store = self.dataSource.offlineStore;
        //TODO (hallucinogen): some stuff @grantland mentioned can't be done maybe needs to be done here
        //TODO (grantland): change to use relations. currently the related PO are only getting saved
        //TODO (grantland): can't add and then remove

        // Hack to store collection in a pin
        NSMutableArray *modified = pin.objects;
        if (modified == nil) {
            modified = [objects mutableCopy];
        } else {
            for (PFObject *object in objects) {
                if (![modified containsObject:object]) {
                    [modified addObject:object];
                }
            }
        }
        pin.objects = modified;

        BFTask *saveTask = nil;
        if (includeChildren) {
            saveTask = [store saveObjectLocallyAsync:pin includeChildren:YES];
        } else {
            saveTask = [store saveObjectLocallyAsync:pin withChildren:pin.objects];
        }
        return saveTask;
    }];
}

///--------------------------------------
#pragma mark - Unpin
///--------------------------------------

- (BFTask<PFVoid> *)unpinObjectsAsync:(NSArray *)objects withPinName:(NSString *)name {
    if (objects.count == 0) {
        return [BFTask taskWithResult:nil];
    }

    @weakify(self);
    return [[self fetchPinAsyncWithName:name] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        PFPin *pin = task.result;
        NSMutableArray *modified = pin.objects;
        if (!modified) {
            // Nothing to unpin
            return nil;
        }

        //TODO (hallucinogen): some stuff @grantland mentioned can't be done maybe needs to be done here
        //TODO (grantland): change to use relations. currently the related PO are only getting saved
        //TODO (grantland): can't add and then remove

        PFOfflineStore *store = self.dataSource.offlineStore;

        [modified removeObjectsInArray:objects];
        if (modified.count == 0) {
            return [store unpinObjectAsync:pin];
        }
        pin.objects = modified;

        return [store saveObjectLocallyAsync:pin includeChildren:YES];
    }];
}

- (BFTask<PFVoid> *)unpinAllObjectsAsyncWithPinName:(NSString *)name {
    @weakify(self);
    return [[self fetchPinAsyncWithName:name] continueWithSuccessBlock:^id(BFTask *task) {
        @strongify(self);
        return [self.dataSource.offlineStore unpinObjectAsync:task.result];
    }];
}

@end
