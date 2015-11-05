/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFInstallationController.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFCurrentInstallationController.h"
#import "PFInstallationPrivate.h"
#import "PFObjectController.h"
#import "PFObjectPrivate.h"

@implementation PFInstallationController

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFObjectControllerProvider, PFCurrentInstallationControllerProvider>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    return self;
}

+ (instancetype)controllerWithDataSource:(id<PFObjectControllerProvider, PFCurrentInstallationControllerProvider>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - Fetch
///--------------------------------------

- (BFTask *)fetchObjectAsync:(PFObject *)object withSessionToken:(nullable NSString *)sessionToken {
    PFInstallation *installation = (PFInstallation *)object;
    @weakify(self);
    return [[[self.objectController fetchObjectAsync:installation
                                    withSessionToken:sessionToken] continueWithBlock:^id(BFTask *task) {
        @strongify(self);

        // Do not attempt to resave an object if LDS is enabled, since changing objectId is not allowed.
        if (self.currentInstallationController.storageType == PFCurrentObjectStorageTypeOfflineStore) {
            return task;
        }

        if (task.faulted && task.error.code == kPFErrorObjectNotFound) {
            @synchronized (installation.lock) {
                // Retry the fetch as a save operation because this Installation was deleted on the server.
                // We always want [currentInstallation fetch] to succeed.
                installation.objectId = nil;
                [installation _markAllFieldsDirty];
                return [[installation saveAsync:nil] continueWithSuccessResult:installation];
            }
        }
        return task;
    }] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        // Roll-forward the previous task.
        return [[self.currentInstallationController saveCurrentObjectAsync:installation] continueWithResult:task];
    }];
}

- (BFTask *)processFetchResultAsync:(NSDictionary *)result forObject:(PFObject *)object {
    PFInstallation *installation = (PFInstallation *)object;
    @weakify(self);
    return [[self.objectController processFetchResultAsync:result forObject:installation] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        // Roll-forward the previous task.
        return [[self.currentInstallationController saveCurrentObjectAsync:installation] continueWithResult:task];
    }];
}

///--------------------------------------
#pragma mark - Delete
///--------------------------------------

- (BFTask *)deleteObjectAsync:(PFObject *)object withSessionToken:(nullable NSString *)sessionToken {
    PFConsistencyAssert(NO, @"Installations cannot be deleted.");
    return nil;
}

- (BFTask *)processDeleteResultAsync:(nullable NSDictionary *)result forObject:(PFObject *)object {
    PFConsistencyAssert(NO, @"Installations cannot be deleted.");
    return nil;
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

- (id<PFObjectControlling>)objectController {
    return self.dataSource.objectController;
}

- (PFCurrentInstallationController *)currentInstallationController {
    return self.dataSource.currentInstallationController;
}

@end
