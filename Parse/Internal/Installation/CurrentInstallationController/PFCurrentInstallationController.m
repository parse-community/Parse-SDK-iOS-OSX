/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCurrentInstallationController.h"

#import "BFTask+Private.h"
#import "PFAsyncTaskQueue.h"
#import "PFInstallationIdentifierStore.h"
#import "PFInstallationPrivate.h"
#import "PFMacros.h"
#import "PFObjectFilePersistenceController.h"
#import "PFObjectPrivate.h"
#import "PFPushPrivate.h"
#import "PFQuery.h"

NSString *const PFCurrentInstallationFileName = @"currentInstallation";
NSString *const PFCurrentInstallationPinName = @"_currentInstallation";

@interface PFCurrentInstallationController () {
    dispatch_queue_t _dataQueue;
    PFAsyncTaskQueue *_dataTaskQueue;
}

@property (nonatomic, strong, readonly) PFFileManager *fileManager;
@property (nonatomic, strong, readonly) PFInstallationIdentifierStore *installationIdentifierStore;

@property (nonatomic, strong) PFInstallation *currentInstallation;
@property (nonatomic, assign) BOOL currentInstallationMatchesDisk;

@end

@implementation PFCurrentInstallationController

@synthesize storageType = _storageType;

@synthesize currentInstallation = _currentInstallation;
@synthesize currentInstallationMatchesDisk = _currentInstallationMatchesDisk;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithStorageType:(PFCurrentObjectStorageType)storageType
                   commonDataSource:(id<PFInstallationIdentifierStoreProvider>)commonDataSource
                     coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource {
    self = [super init];
    if (!self) return nil;

    _dataQueue = dispatch_queue_create("com.parse.installation.current", DISPATCH_QUEUE_CONCURRENT);
    _dataTaskQueue = [[PFAsyncTaskQueue alloc] init];

    _storageType = storageType;
    _commonDataSource = commonDataSource;
    _coreDataSource = coreDataSource;

    return self;
}

+ (instancetype)controllerWithStorageType:(PFCurrentObjectStorageType)storageType
                         commonDataSource:(id<PFInstallationIdentifierStoreProvider>)commonDataSource
                           coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource {
    return [[self alloc] initWithStorageType:storageType
                            commonDataSource:commonDataSource
                              coreDataSource:coreDataSource];
}

///--------------------------------------
#pragma mark - PFCurrentObjectControlling
///--------------------------------------

- (BFTask *)getCurrentObjectAsync {
    @weakify(self);
    return [_dataTaskQueue enqueue:^BFTask *(BFTask *unused) {
        return [[[BFTask taskFromExecutor:[BFExecutor defaultExecutor] withBlock:^id {
            @strongify(self);
            if (self.currentInstallation) {
                return self.currentInstallation;
            }

            if (!self.currentInstallationMatchesDisk) {
                return [[self _loadCurrentInstallationFromDiskAsync] continueWithBlock:^id(BFTask *task) {
                    PFInstallation *installation = task.result;
                    if (installation) {
                        // If there is no objectId, but there is some data
                        // it means that the data wasn't yet saved to the server
                        // so we should mark everything as dirty
                        if (!installation.objectId && installation.allKeys.count) {
                            [installation _markAllFieldsDirty];
                        }
                    }
                    return task;
                }];
            }
            return nil;
        }] continueWithBlock:^id(BFTask *task) {
            @strongify(self);
            if (task.faulted) {
                return task;
            }

            PFInstallation *installation = task.result;
            //TODO: (nlutsenko) Make it not terrible aka actually use task chaining here.
            NSString *installationId = [[self.installationIdentifierStore getInstallationIdentifierAsync] waitForResult:nil];
            installationId = installationId.lowercaseString;
            if (!installation || ![installationId isEqualToString:installation.installationId]) {
                // If there's no installation object, or the object's installation
                // ID doesn't match this device's installation ID, create a new
                // installation. Try to keep track of the previously stored device
                // token: if there was an installation already stored just re-use
                // its device token, otherwise try loading from the keychain (where
                // old SDKs stored the token). Discard the old installation.
                NSString *oldDeviceToken = nil;
                if (installation) {
                    oldDeviceToken = installation.deviceToken;
                } else {
                    oldDeviceToken = [[PFPush pushInternalUtilClass] getDeviceTokenFromKeychain];
                }

                installation = [PFInstallation object];
                installation.deviceType = kPFDeviceType;
                installation.installationId = installationId;
                if (oldDeviceToken) {
                    installation.deviceToken = oldDeviceToken;
                }
            }

            return installation;
        }] continueWithBlock:^id(BFTask *task) {
            dispatch_barrier_sync(_dataQueue, ^{
                _currentInstallation = task.result;
                _currentInstallationMatchesDisk = !task.faulted;
            });
            return task;
        }];
    }];
}

- (BFTask *)saveCurrentObjectAsync:(PFObject *)object {
    PFInstallation *installation = (PFInstallation *)object;

    @weakify(self);
    return [_dataTaskQueue enqueue:^BFTask *(BFTask *unused) {
        @strongify(self);

        if (installation != self.currentInstallation) {
            return nil;
        }
        return [[self _saveCurrentInstallationToDiskAsync:installation] continueWithBlock:^id(BFTask *task) {
            self.currentInstallationMatchesDisk = (!task.faulted && !task.cancelled);
            return nil;
        }];
    }];
}

///--------------------------------------
#pragma mark - Installation
///--------------------------------------

- (PFInstallation *)memoryCachedCurrentInstallation {
    return self.currentInstallation;
}

- (BFTask *)clearCurrentInstallationAsync {
    @weakify(self);
    return [_dataTaskQueue enqueue:^BFTask *(BFTask *unused) {
        @strongify(self);

        dispatch_barrier_sync(_dataQueue, ^{
            _currentInstallation = nil;
            _currentInstallationMatchesDisk = NO;
        });

        NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:2];
        if (self.storageType == PFCurrentObjectStorageTypeOfflineStore) {
            BFTask *unpinTask = [PFObject unpinAllObjectsInBackgroundWithName:PFCurrentInstallationPinName];
            [tasks addObject:unpinTask];
        }

        BFTask *fileTask = [self.coreDataSource.objectFilePersistenceController removePersistentObjectAsyncForKey:PFCurrentInstallationFileName];
        [tasks addObject:fileTask];

        return [BFTask taskForCompletionOfAllTasks:tasks];
    }];
}

- (BFTask *)clearMemoryCachedCurrentInstallationAsync {
    return [_dataTaskQueue enqueue:^BFTask *(BFTask *unused) {
        self.currentInstallation = nil;
        self.currentInstallationMatchesDisk = NO;

        return nil;
    }];
}

///--------------------------------------
#pragma mark - Data Storage
///--------------------------------------

- (BFTask *)_loadCurrentInstallationFromDiskAsync {
    if (self.storageType == PFCurrentObjectStorageTypeOfflineStore) {
        // Try loading from OfflineStore
        PFQuery *query = [[[PFQuery queryWithClassName:[PFInstallation parseClassName]]
                           fromPinWithName:PFCurrentInstallationPinName] ignoreACLs];

        return [[query findObjectsInBackground] continueWithSuccessBlock:^id(BFTask *task) {
            NSArray *results = task.result;
            if (results.count == 1) {
                return [BFTask taskWithResult:results.firstObject];
            } else if (results.count != 0) {
                return [[PFObject unpinAllObjectsInBackgroundWithName:PFCurrentInstallationPinName]
                        continueWithSuccessResult:nil];
            }

            // Backward compatibility if we previously have non-LDS currentInstallation.
            return [PFObject _migrateObjectInBackgroundFromFile:PFCurrentInstallationFileName
                                                          toPin:PFCurrentInstallationPinName];
        }];
    }

    PFObjectFilePersistenceController *controller = self.objectFilePersistenceController;
    return [controller loadPersistentObjectAsyncForKey:PFCurrentInstallationFileName];
}

- (BFTask *)_saveCurrentInstallationToDiskAsync:(PFInstallation *)installation {
    if (self.storageType == PFCurrentObjectStorageTypeOfflineStore) {
        BFTask *task = [PFObject unpinAllObjectsInBackgroundWithName:PFCurrentInstallationPinName];
        return [task continueWithBlock:^id(BFTask *task) {
            // Make sure to not pin children of PFInstallation automatically, as it can create problems
            // if any of the children are of Installation class.
            return [installation _pinInBackgroundWithName:PFCurrentInstallationPinName includeChildren:NO];
        }];
    }

    PFObjectFilePersistenceController *controller = self.objectFilePersistenceController;
    return [controller persistObjectAsync:installation forKey:PFCurrentInstallationFileName];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (PFObjectFilePersistenceController *)objectFilePersistenceController {
    return self.coreDataSource.objectFilePersistenceController;
}

- (PFInstallationIdentifierStore *)installationIdentifierStore {
    return self.commonDataSource.installationIdentifierStore;
}

- (PFInstallation *)currentInstallation {
    __block PFInstallation *installation = nil;
    dispatch_sync(_dataQueue, ^{
        installation = _currentInstallation;
    });
    return installation;
}

- (void)setCurrentInstallation:(PFInstallation *)currentInstallation {
    dispatch_barrier_sync(_dataQueue, ^{
        if (_currentInstallation != currentInstallation) {
            _currentInstallation = currentInstallation;
        }
    });
}

- (BOOL)currentInstallationMatchesDisk {
    __block BOOL matches = NO;
    dispatch_sync(_dataQueue, ^{
        matches = _currentInstallationMatchesDisk;
    });
    return matches;
}

- (void)setCurrentInstallationMatchesDisk:(BOOL)currentInstallationMatchesDisk {
    dispatch_barrier_sync(_dataQueue, ^{
        _currentInstallationMatchesDisk = currentInstallationMatchesDisk;
    });
}

@end
