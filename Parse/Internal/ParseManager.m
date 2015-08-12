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
#import "PFInstallation.h"
#import "PFInstallationIdentifierStore.h"
#import "PFKeyValueCache.h"
#import "PFKeychainStore.h"
#import "PFLogging.h"
#import "PFMultiProcessFileLockController.h"
#import "PFPinningEventuallyQueue.h"
#import "PFPushManager.h"
#import "PFUser.h"
#import "PFURLSessionCommandRunner.h"

#if TARGET_OS_IPHONE
#import "PFPurchaseController.h"
#import "PFProduct.h"
#endif

static NSString *const _ParseApplicationIdFileName = @"applicationId";

@interface ParseManager () <PFCoreManagerDataSource>
{
    dispatch_queue_t _offlineStoreAccessQueue;
    dispatch_queue_t _eventuallyQueueAccessQueue;
    dispatch_queue_t _keychainStoreAccessQueue;
    dispatch_queue_t _fileManagerAccessQueue;
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
@synthesize offlineStore = _offlineStore;
@synthesize eventuallyQueue = _eventuallyQueue;
@synthesize installationIdentifierStore = _installationIdentifierStore;
@synthesize commandRunner = _commandRunner;
@synthesize keyValueCache = _keyValueCache;
@synthesize coreManager = _coreManager;
@synthesize analyticsController = _analyticsController;
@synthesize pushManager = _pushManager;
#if TARGET_OS_IPHONE
@synthesize purchaseController = _purchaseController;
#endif

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithApplicationId:(NSString *)applicationId clientKey:(NSString *)clientKey {
    self = [super init];
    if (!self) return nil;

    _offlineStoreAccessQueue = dispatch_queue_create("com.parse.offlinestore.access", DISPATCH_QUEUE_CONCURRENT);
    _eventuallyQueueAccessQueue = dispatch_queue_create("com.parse.eventuallyqueue.access", DISPATCH_QUEUE_SERIAL);
    _keychainStoreAccessQueue = dispatch_queue_create("com.parse.keychainstore.access", DISPATCH_QUEUE_SERIAL);
    _fileManagerAccessQueue = dispatch_queue_create("com.parse.filemanager.access", DISPATCH_QUEUE_SERIAL);
    _installationIdentifierStoreAccessQueue = dispatch_queue_create("com.parse.installationidentifierstore.access",
                                                                    DISPATCH_QUEUE_SERIAL);
    _commandRunnerAccessQueue = dispatch_queue_create("com.parse.commandrunner.access", DISPATCH_QUEUE_SERIAL);
    _keyValueCacheAccessQueue = dispatch_queue_create("com.parse.keyvaluecache.access", DISPATCH_QUEUE_SERIAL);
    _coreManagerAccessQueue = dispatch_queue_create("com.parse.coreManager.access", DISPATCH_QUEUE_SERIAL);
    _pushManagerAccessQueue = dispatch_queue_create("com.parse.pushManager.access", DISPATCH_QUEUE_SERIAL);
    _controllerAccessQueue = dispatch_queue_create("com.parse.controller.access", DISPATCH_QUEUE_SERIAL);
    _preloadQueue = dispatch_queue_create("com.parse.preload", DISPATCH_QUEUE_SERIAL);

    _applicationId = [applicationId copy];
    _clientKey = [clientKey copy];

    return self;
}

- (void)configureWithApplicationGroupIdentifier:(NSString *)applicationGroupIdentifier
                containingApplicationIdentifier:(NSString *)containingApplicationIdentifier
                          enabledLocalDataStore:(BOOL)localDataStoreEnabled {
    _applicationGroupIdentifier = [applicationGroupIdentifier copy];
    _containingApplicationIdentifier = [containingApplicationIdentifier copy];

    // Migrate any data if it's required.
    [self _migrateSandboxDataToApplicationGroupContainerIfNeeded];

    // Make sure the data on disk for Parse is for the current application.
    [self _checkApplicationId];

    if (localDataStoreEnabled) {
        PFOfflineStoreOptions options = (_applicationGroupIdentifier ?
                                         PFOfflineStoreOptionAlwaysFetchFromSQLite : 0);
        [self loadOfflineStoreWithOptions:options];
    }
}

///--------------------------------------
#pragma mark - Offline Store
///--------------------------------------

- (void)loadOfflineStoreWithOptions:(PFOfflineStoreOptions)options {
    PFConsistencyAssert(!_offlineStore, @"Can't load offline store more than once.");
    dispatch_barrier_sync(_offlineStoreAccessQueue, ^{
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
    return (self.offlineStore != nil);
}

///--------------------------------------
#pragma mark - Eventually Queue
///--------------------------------------

- (PFEventuallyQueue *)eventuallyQueue {
    __block PFEventuallyQueue *queue = nil;
    dispatch_sync(_eventuallyQueueAccessQueue, ^{
        if (!_eventuallyQueue ||
            (self.offlineStoreLoaded && [_eventuallyQueue isKindOfClass:[PFCommandCache class]]) ||
            (!self.offlineStoreLoaded && [_eventuallyQueue isKindOfClass:[PFPinningEventuallyQueue class]])) {

            id<PFCommandRunning> commandRunner = self.commandRunner;

            PFCommandCache *commandCache = [self _newCommandCache];
            _eventuallyQueue = (self.offlineStoreLoaded ?
                                [PFPinningEventuallyQueue newDefaultPinningEventuallyQueueWithCommandRunner:commandRunner]
                                :
                                commandCache);

            // We still need to clear out the old command cache even if we're using Pinning in case
            // anything is left over when the user upgraded. Checking number of pending and then
            // clearing should be enough.
            if (self.offlineStoreLoaded && commandCache.commandCount > 0) {
                [commandCache removeAllCommands];
            }
        }
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
    return [PFCommandCache newDefaultCommandCacheWithCommandRunner:self.commandRunner cacheFolderPath:folderPath];
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
            NSString *bundleIdentifier = (_containingApplicationIdentifier ?: [[NSBundle mainBundle] bundleIdentifier]);
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
            _fileManager = [[PFFileManager alloc] initWithApplicationIdentifier:self.applicationId
                                                     applicationGroupIdentifier:self.applicationGroupIdentifier];
        }
        fileManager = _fileManager;
    });
    return fileManager;
}

#pragma mark InstallationIdentifierStore

- (PFInstallationIdentifierStore *)installationIdentifierStore {
    __block PFInstallationIdentifierStore *store = nil;
    dispatch_sync(_installationIdentifierStoreAccessQueue, ^{
        if (!_installationIdentifierStore) {
            _installationIdentifierStore = [[PFInstallationIdentifierStore alloc] initWithFileManager:self.fileManager];
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
                                                                      applicationId:self.applicationId
                                                                          clientKey:self.clientKey];
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

#pragma mark AnalyticsController

- (PFAnalyticsController *)analyticsController {
    __block PFAnalyticsController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_analyticsController) {
            _analyticsController = [[PFAnalyticsController alloc] initWithEventuallyQueue:self.eventuallyQueue];
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

#if TARGET_OS_IPHONE

#pragma mark PurchaseController

- (PFPurchaseController *)purchaseController {
    __block PFPurchaseController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_purchaseController) {
            _purchaseController = [PFPurchaseController controllerWithCommandRunner:self.commandRunner
                                                                        fileManager:self.fileManager];
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
        [PFUser currentUser];
        [PFConfig currentConfig];
        [PFInstallation currentInstallation];

        [self eventuallyQueue];

        return nil;
    }];
}

///--------------------------------------
#pragma mark - ApplicationId
///--------------------------------------

/*!
 Verifies that the data stored on disk for Parse was generated using the same application that is running now.
 */
- (void)_checkApplicationId {
    NSFileManager *systemFileManager = [NSFileManager defaultManager];

    // Make sure the current version of the cache is for this application id.
    NSString *applicationIdFile = [self.fileManager parseDataItemPathForPathComponent:_ParseApplicationIdFileName];
    [[PFMultiProcessFileLockController sharedController] beginLockedContentAccessForFileAtPath:applicationIdFile];

    if ([systemFileManager fileExistsAtPath:applicationIdFile]) {
        NSError *error = nil;
        NSString *applicationId = [NSString stringWithContentsOfFile:applicationIdFile
                                                            encoding:NSUTF8StringEncoding
                                                               error:&error];
        if (!error && ![applicationId isEqualToString:self.applicationId]) {
            // The application id has changed, so everything on disk is invalid.
            [self.keychainStore removeAllObjects];
            [self.keyValueCache removeAllObjects];

            NSArray *tasks = @[
                               // Remove the contents only, but don't delete the folder.
                               [PFFileManager removeDirectoryContentsAsyncAtPath:[self.fileManager parseDefaultDataDirectoryPath]],
                               // Completely remove everything in deprecated folder.
                               [PFFileManager removeItemAtPathAsync:[self.fileManager parseDataDirectoryPath_DEPRECATED]]
                               ];
            [[BFTask taskForCompletionOfAllTasks:tasks] waitForResult:nil withMainThreadWarning:NO];
        }
    }

    if (![systemFileManager fileExistsAtPath:applicationIdFile]) {
        NSError *error = nil;
        BFTask *writeTask = [PFFileManager writeStringAsync:self.applicationId toFile:applicationIdFile];
        [writeTask waitForResult:&error withMainThreadWarning:NO];
        if (error) {
            PFLogError(PFLoggingTagCommon, @"Unable to create applicationId file with error: %@", error);
        }
    }

    [[PFMultiProcessFileLockController sharedController] endLockedContentAccessForFileAtPath:applicationIdFile];
}

///--------------------------------------
#pragma mark - Data Sharing
///--------------------------------------

- (void)_migrateSandboxDataToApplicationGroupContainerIfNeeded {
    // There is no need to migrate anything on OSX, since we are using globally available folder.
#if TARGET_OS_IPHONE
    // Do nothing if there is no application group container or containing application is specified.
    if (!self.applicationGroupIdentifier || self.containingApplicationIdentifier) {
        return;
    }

    NSString *localSandboxDataPath = [self.fileManager parseLocalSandboxDataDirectoryPath];
    NSString *dataPath = [self.fileManager parseDefaultDataDirectoryPath];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:localSandboxDataPath error:nil];
    if ([contents count] != 0) {
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
