/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ParseManager.h"

#import <Bolts/BFExecutor.h>

#import "BFTask+Private.h"
#import "PFAnalyticsController.h"
#import "PFAssert.h"
#import "PFCommandCache.h"
#import "PFConfig.h"
#import "PFCoreManager.h"
#import "PFFileManager.h"
#import "PFInstallationIdentifierStore.h"
#import "PFKeyValueCache.h"
#import "PFKeychainStore.h"
#import "PFLogging.h"
#import "PFMultiProcessFileLockController.h"
#import "PFPinningEventuallyQueue.h"
#import "PFUser.h"
#import "PFURLSessionCommandRunner.h"
#import "PFPersistenceController.h"

#if !TARGET_OS_WATCH && !TARGET_OS_TV
#import "PFPushManager.h"
#import "PFInstallation.h"
#endif

#if TARGET_OS_IOS || TARGET_OS_TV
#import "PFPurchaseController.h"
#import "PFProduct.h"
#endif

#if TARGET_OS_TV
#import "PFMemoryEventuallyQueue.h"
#endif

static NSString *const _ParseApplicationIdFileName = @"applicationId";

@interface ParseManager () <PFCoreManagerDataSource>
{
    dispatch_queue_t _offlineStoreAccessQueue;
    dispatch_queue_t _eventuallyQueueAccessQueue;
    dispatch_queue_t _keychainStoreAccessQueue;
    dispatch_queue_t _fileManagerAccessQueue;
    dispatch_queue_t _persistenceControllerAccessQueue;
    dispatch_queue_t _installationIdentifierStoreAccessQueue;
    dispatch_queue_t _commandRunnerAccessQueue;
    dispatch_queue_t _keyValueCacheAccessQueue;
    dispatch_queue_t _coreManagerAccessQueue;
    dispatch_queue_t _pushManagerAccessQueue;
    dispatch_queue_t _controllerAccessQueue;

    dispatch_queue_t _preloadQueue;
}

@end

@implementation ParseManager

@synthesize keychainStore = _keychainStore;
@synthesize fileManager = _fileManager;
@synthesize persistenceController = _persistenceController;
@synthesize offlineStore = _offlineStore;
@synthesize eventuallyQueue = _eventuallyQueue;
@synthesize installationIdentifierStore = _installationIdentifierStore;
@synthesize commandRunner = _commandRunner;
@synthesize keyValueCache = _keyValueCache;
@synthesize coreManager = _coreManager;
@synthesize analyticsController = _analyticsController;
#if !TARGET_OS_WATCH && !TARGET_OS_TV
@synthesize pushManager = _pushManager;
#endif
#if TARGET_OS_IOS || TARGET_OS_TV
@synthesize purchaseController = _purchaseController;
#endif

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithConfiguration:(ParseClientConfiguration *)configuration {
    self = [super init];
    if (!self) return nil;

    _offlineStoreAccessQueue = dispatch_queue_create("com.parse.offlinestore.access", DISPATCH_QUEUE_CONCURRENT);
    _eventuallyQueueAccessQueue = dispatch_queue_create("com.parse.eventuallyqueue.access", DISPATCH_QUEUE_SERIAL);
    _keychainStoreAccessQueue = dispatch_queue_create("com.parse.keychainstore.access", DISPATCH_QUEUE_SERIAL);
    _fileManagerAccessQueue = dispatch_queue_create("com.parse.filemanager.access", DISPATCH_QUEUE_SERIAL);
    _persistenceControllerAccessQueue = dispatch_queue_create("com.parse.persistanceController.access", DISPATCH_QUEUE_SERIAL);
    _installationIdentifierStoreAccessQueue = dispatch_queue_create("com.parse.installationidentifierstore.access",
                                                                    DISPATCH_QUEUE_SERIAL);
    _commandRunnerAccessQueue = dispatch_queue_create("com.parse.commandrunner.access", DISPATCH_QUEUE_SERIAL);
    _keyValueCacheAccessQueue = dispatch_queue_create("com.parse.keyvaluecache.access", DISPATCH_QUEUE_SERIAL);
    _coreManagerAccessQueue = dispatch_queue_create("com.parse.coreManager.access", DISPATCH_QUEUE_SERIAL);
    _pushManagerAccessQueue = dispatch_queue_create("com.parse.pushManager.access", DISPATCH_QUEUE_SERIAL);
    _controllerAccessQueue = dispatch_queue_create("com.parse.controller.access", DISPATCH_QUEUE_SERIAL);
    _preloadQueue = dispatch_queue_create("com.parse.preload", DISPATCH_QUEUE_SERIAL);

    _configuration = [configuration copy];

    return self;
}

- (void)startManaging {
    // Migrate any data if it's required.
    [self _migrateSandboxDataToApplicationGroupContainerIfNeeded];

    // TODO: (nlutsenko) Make it not terrible!
    [[self.persistenceController getPersistenceGroupAsync] waitForResult:nil withMainThreadWarning:NO];

    if (self.configuration.localDatastoreEnabled) {
        PFOfflineStoreOptions options = (self.configuration.applicationGroupIdentifier ?
                                         PFOfflineStoreOptionAlwaysFetchFromSQLite : 0);
        [self loadOfflineStoreWithOptions:options];
    }
}

///--------------------------------------
#pragma mark - Offline Store
///--------------------------------------

- (void)loadOfflineStoreWithOptions:(PFOfflineStoreOptions)options {
    dispatch_barrier_sync(_offlineStoreAccessQueue, ^{
        PFConsistencyAssert(!_offlineStore, @"Can't load offline store more than once.");
        _offlineStore = [[PFOfflineStore alloc] initWithFileManager:self.fileManager options:options];
    });
}

- (void)setOfflineStore:(PFOfflineStore *)offlineStore {
    dispatch_barrier_sync(_offlineStoreAccessQueue, ^{
        _offlineStore = offlineStore;
    });
}

- (PFOfflineStore *)offlineStore {
    __block PFOfflineStore *offlineStore = nil;
    dispatch_sync(_offlineStoreAccessQueue, ^{
        offlineStore = _offlineStore;
    });
    return offlineStore;
}

- (BOOL)isOfflineStoreLoaded {
    return self.configuration.localDatastoreEnabled;
}

///--------------------------------------
#pragma mark - Eventually Queue
///--------------------------------------

- (PFEventuallyQueue *)eventuallyQueue {
    __block PFEventuallyQueue *queue = nil;
    dispatch_sync(_eventuallyQueueAccessQueue, ^{
#if TARGET_OS_TV
        if (!_eventuallyQueue) {
            _eventuallyQueue = [PFMemoryEventuallyQueue newDefaultMemoryEventuallyQueueWithDataSource:self];
        }
#else
        if (!_eventuallyQueue ||
            (self.offlineStoreLoaded && [_eventuallyQueue isKindOfClass:[PFCommandCache class]]) ||
            (!self.offlineStoreLoaded && [_eventuallyQueue isKindOfClass:[PFPinningEventuallyQueue class]])) {

            PFCommandCache *commandCache = [self _newCommandCache];
            _eventuallyQueue = (self.offlineStoreLoaded ?
                                [PFPinningEventuallyQueue newDefaultPinningEventuallyQueueWithDataSource:self]
                                :
                                commandCache);

            // We still need to clear out the old command cache even if we're using Pinning in case
            // anything is left over when the user upgraded. Checking number of pending and then
            // clearing should be enough.
            if (self.offlineStoreLoaded && commandCache.commandCount > 0) {
                [commandCache removeAllCommands];
            }
        }
#endif
        queue = _eventuallyQueue;
    });
    return queue;
}

- (PFCommandCache *)_newCommandCache {
    // Construct the path to the cache directory in <Application Home>/Library/Private Documents/Parse/Command Cache
    // This isn't in the "Library/Caches" directory because we don't want the OS clearing it for us.
    // It falls under the category of "offline data".
    // See https://developer.apple.com/library/ios/#qa/qa1699/_index.html
    NSString *folderPath = [self.fileManager parseDefaultDataDirectoryPath];
    return [PFCommandCache newDefaultCommandCacheWithCommonDataSource:self coreDataSource:self.coreManager cacheFolderPath:folderPath];
}

- (void)clearEventuallyQueue {
    dispatch_sync(_preloadQueue, ^{
        dispatch_sync(_eventuallyQueueAccessQueue, ^{
            [_eventuallyQueue removeAllCommands];
            [_eventuallyQueue pause];
            _eventuallyQueue = nil;
        });
    });
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

#pragma mark KeychainStore

- (PFKeychainStore *)keychainStore {
    __block PFKeychainStore *store = nil;
    dispatch_sync(_keychainStoreAccessQueue, ^{
        if (!_keychainStore) {
            NSString *bundleIdentifier = (self.configuration.containingApplicationBundleIdentifier ?: [NSBundle mainBundle].bundleIdentifier);
            NSString *service = [NSString stringWithFormat:@"%@.%@", bundleIdentifier, PFKeychainStoreDefaultService];
            _keychainStore = [[PFKeychainStore alloc] initWithService:service];
        }
        store = _keychainStore;
    });
    return store;
}

#pragma mark FileManager

- (PFFileManager *)fileManager {
    __block PFFileManager *fileManager = nil;
    dispatch_sync(_fileManagerAccessQueue, ^{
        if (!_fileManager) {
            _fileManager = [[PFFileManager alloc] initWithApplicationIdentifier:self.configuration.applicationId
                                                     applicationGroupIdentifier:self.configuration.applicationGroupIdentifier];
        }
        fileManager = _fileManager;
    });
    return fileManager;
}

#pragma mark PersistenceController

- (PFPersistenceController *)persistenceController {
    __block PFPersistenceController *controller = nil;
    dispatch_sync(_persistenceControllerAccessQueue, ^{
        if (!_persistenceController) {
            _persistenceController = [self _createPersistenceController];
        }
        controller = _persistenceController;
    });
    return controller;
}

- (PFPersistenceController *)_createPersistenceController {
    @weakify(self);
    PFPersistenceGroupValidationHandler validationHandler = ^BFTask *(id<PFPersistenceGroup> group) {
        @strongify(self);

        return [[[[[group beginLockedContentAccessAsyncToDataForKey:_ParseApplicationIdFileName] continueWithSuccessBlock:^id(BFTask *task) {
            return [group getDataAsyncForKey:_ParseApplicationIdFileName];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            NSData *data = task.result;
            if (!data) {
                return nil;
            }

            return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }] continueWithSuccessBlock:^id(BFTask *task) {
            if (task.result) {
                if ([self.configuration.applicationId isEqualToString:task.result]) {
                    // Everything is valid, no need to remove, set applicationId here.
                    return nil;
                }

                [self.keychainStore removeAllObjects];
                [self.keyValueCache removeAllObjects];
            }
            return [[group removeAllDataAsync] continueWithSuccessBlock:^id(BFTask *task) {
                NSData *applicationIdData = [self.configuration.applicationId dataUsingEncoding:NSUTF8StringEncoding];
                return [group setDataAsync:applicationIdData forKey:_ParseApplicationIdFileName];
            }];
        }] continueWithBlock:^id(BFTask *task) {
            return [group endLockedContentAccessAsyncToDataForKey:_ParseApplicationIdFileName];
        }];
    };
    return [[PFPersistenceController alloc] initWithApplicationIdentifier:self.configuration.applicationId
                                               applicationGroupIdentifier:self.configuration.applicationGroupIdentifier
                                                   groupValidationHandler:validationHandler];
}

#pragma mark InstallationIdentifierStore

- (PFInstallationIdentifierStore *)installationIdentifierStore {
    __block PFInstallationIdentifierStore *store = nil;
    dispatch_sync(_installationIdentifierStoreAccessQueue, ^{
        if (!_installationIdentifierStore) {
            _installationIdentifierStore = [[PFInstallationIdentifierStore alloc] initWithDataSource:self];
        }
        store = _installationIdentifierStore;
    });
    return store;
}

#pragma mark CommandRunner

- (id<PFCommandRunning>)commandRunner {
    __block id<PFCommandRunning> runner = nil;
    dispatch_sync(_commandRunnerAccessQueue, ^{
        if (!_commandRunner) {
            _commandRunner = [PFURLSessionCommandRunner commandRunnerWithDataSource:self
                                                                      retryAttempts:self.configuration.networkRetryAttempts
                                                                      applicationId:self.configuration.applicationId
                                                                          clientKey:self.configuration.clientKey
                                                                          serverURL:[NSURL URLWithString:self.configuration.server]];
        }
        runner = _commandRunner;
    });
    return runner;
}

#pragma mark KeyValueCache

- (PFKeyValueCache *)keyValueCache {
    __block PFKeyValueCache *cache = nil;
    dispatch_sync(_keyValueCacheAccessQueue, ^{
        if (!_keyValueCache) {
            NSString *path = [self.fileManager parseCacheItemPathForPathComponent:@"../ParseKeyValueCache/"];
            _keyValueCache = [[PFKeyValueCache alloc] initWithCacheDirectoryPath:path];
        }
        cache = _keyValueCache;
    });
    return cache;
}

#pragma mark CoreManager

- (PFCoreManager *)coreManager {
    __block PFCoreManager *manager = nil;
    dispatch_sync(_coreManagerAccessQueue, ^{
        if (!_coreManager) {
            _coreManager = [PFCoreManager managerWithDataSource:self];
        }
        manager = _coreManager;
    });
    return manager;
}

- (void)unloadCoreManager {
    dispatch_sync(_coreManagerAccessQueue, ^{
        _coreManager = nil;
    });
}

#if !TARGET_OS_WATCH && !TARGET_OS_TV

#pragma mark PushManager

- (PFPushManager *)pushManager {
    __block PFPushManager *manager = nil;
    dispatch_sync(_pushManagerAccessQueue, ^{
        if (!_pushManager) {
            _pushManager = [PFPushManager managerWithCommonDataSource:self coreDataSource:self.coreManager];
        }
        manager = _pushManager;
    });
    return manager;
}

- (void)setPushManager:(PFPushManager *)pushManager {
    dispatch_sync(_pushManagerAccessQueue, ^{
        _pushManager = pushManager;
    });
}

#endif

#pragma mark AnalyticsController

- (PFAnalyticsController *)analyticsController {
    __block PFAnalyticsController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_analyticsController) {
            _analyticsController = [[PFAnalyticsController alloc] initWithDataSource:self];
        }
        controller = _analyticsController;
    });
    return controller;
}

- (void)setAnalyticsController:(PFAnalyticsController *)analyticsController {
    dispatch_sync(_controllerAccessQueue, ^{
        if (_analyticsController != analyticsController) {
            _analyticsController = analyticsController;
        }
    });
}

#if TARGET_OS_IOS || TARGET_OS_TV

#pragma mark PurchaseController

- (PFPurchaseController *)purchaseController {
    __block PFPurchaseController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_purchaseController) {
            _purchaseController = [PFPurchaseController controllerWithDataSource:self bundle:[NSBundle mainBundle]];
        }
        controller = _purchaseController;
    });
    return controller;
}

- (void)setPurchaseController:(PFPurchaseController *)purchaseController {
    dispatch_sync(_controllerAccessQueue, ^{
        _purchaseController = purchaseController;
    });
}

#endif

///--------------------------------------
#pragma mark - Preloading
///--------------------------------------

- (BFTask *)preloadDiskObjectsToMemoryAsync {
    @weakify(self);
    return [BFTask taskFromExecutor:[BFExecutor executorWithDispatchQueue:_preloadQueue] withBlock:^id{
        @strongify(self);

        NSArray *tasks = @[
                           [PFUser getCurrentUserInBackground],
                           [PFConfig getCurrentConfigInBackground],
#if !TARGET_OS_WATCH && !TARGET_OS_TV
                           [PFInstallation getCurrentInstallationInBackground],
#endif
                           ];
        [[BFTask taskForCompletionOfAllTasks:tasks] waitUntilFinished]; // Wait synchronously to make sure we are blocking preload queue.
        [self eventuallyQueue];

        return nil;
    }];
}

///--------------------------------------
#pragma mark - Data Sharing
///--------------------------------------

- (void)_migrateSandboxDataToApplicationGroupContainerIfNeeded {
    // There is no need to migrate anything on OSX, since we are using globally available folder.
#if TARGET_OS_IOS
    // Do nothing if there is no application group container or containing application is specified.
    if (!self.configuration.applicationGroupIdentifier || self.configuration.containingApplicationBundleIdentifier) {
        return;
    }

    NSString *localSandboxDataPath = [self.fileManager parseLocalSandboxDataDirectoryPath];
    NSString *dataPath = [self.fileManager parseDefaultDataDirectoryPath];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:localSandboxDataPath error:nil];
    if (contents.count != 0) {
        // If moving files fails - just log the error, but don't fail.
        NSError *error = nil;
        [[PFFileManager moveContentsOfDirectoryAsyncAtPath:localSandboxDataPath
                                         toDirectoryAtPath:dataPath
                                                  executor:[BFExecutor immediateExecutor]] waitForResult:&error];
        if (error) {
            PFLogError(PFLoggingTagCommon,
                       @"Failed to migrate local sandbox data to shared container with error %@",
                       [error localizedDescription]);
        } else {
            [[PFFileManager removeItemAtPathAsync:localSandboxDataPath withFileLock:NO] waitForResult:nil];
        }
    }
#endif
}

@end
