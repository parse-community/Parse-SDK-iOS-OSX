/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFOfflineObjectController.h"

#import "BFTask+Private.h"
#import "PFMacros.h"
#import "PFObjectController_Private.h"
#import "PFObjectPrivate.h"
#import "PFObjectState.h"
#import "PFOfflineStore.h"

@interface PFOfflineObjectController ()

@property (nonatomic, strong, readonly) PFOfflineStore *offlineStore;

@end

@implementation PFOfflineObjectController

@dynamic dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider, PFOfflineStoreProvider>)dataSource {
    return [super initWithDataSource:dataSource];
}

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider, PFOfflineStoreProvider>)dataSource {
    return [super controllerWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - PFObjectController
///--------------------------------------

- (BFTask *)processFetchResultAsync:(NSDictionary *)result forObject:(PFObject *)object {
    return [[[[self.offlineStore fetchObjectLocallyAsync:object] continueWithBlock:^id(BFTask *task) {
        // Catch CacheMiss error and ignore it.
        if ([task.error.domain isEqualToString:PFParseErrorDomain] &&
            task.error.code == kPFErrorCacheMiss) {
            return nil;
        }
        return task;
    }] continueWithBlock:^id(BFTask *task) {
        return [super processFetchResultAsync:result forObject:object];
    }] continueWithBlock:^id(BFTask *task) {
        return [[self.offlineStore updateDataForObjectAsync:object] continueWithBlock:^id(BFTask *task) {
            // Catch CACHE_MISS and ignore it.
            if ([task.error.domain isEqualToString:PFParseErrorDomain] &&
                task.error.code == kPFErrorCacheMiss) {
                return [BFTask taskWithResult:nil];
            }
            return task;
        }];
    }];
}

- (BFTask *)processDeleteResultAsync:(nullable NSDictionary *)result forObject:(PFObject *)object {
    @weakify(self);
    return [[super processDeleteResultAsync:result forObject:object] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        if (object._state.deleted) {
            return [self.offlineStore deleteDataForObjectAsync:object];
        }
        return [self.offlineStore updateDataForObjectAsync:object];
    }];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (PFOfflineStore *)offlineStore {
    return self.dataSource.offlineStore;
}

@end
