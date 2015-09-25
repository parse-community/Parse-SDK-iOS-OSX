/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFCoreManager.h"

#import "PFAssert.h"
#import "PFCachedQueryController.h"
#import "PFCloudCodeController.h"
#import "PFConfigController.h"
#import "PFCurrentInstallationController.h"
#import "PFCurrentUserController.h"
#import "PFFileController.h"
#import "PFInstallationController.h"
#import "PFLocationManager.h"
#import "PFMacros.h"
#import "PFObjectBatchController.h"
#import "PFObjectController.h"
#import "PFObjectFilePersistenceController.h"
#import "PFObjectLocalIdStore.h"
#import "PFObjectSubclassingController.h"
#import "PFOfflineObjectController.h"
#import "PFOfflineQueryController.h"
#import "PFPinningObjectStore.h"
#import "PFSessionController.h"
#import "PFUserAuthenticationController.h"
#import "PFUserController.h"

@interface PFCoreManager () {
    dispatch_queue_t _locationManagerAccessQueue;
    dispatch_queue_t _controllerAccessQueue;
    dispatch_queue_t _objectLocalIdStoreAccessQueue;
}

@end

@implementation PFCoreManager

@synthesize locationManager = _locationManager;

@synthesize queryController = _queryController;
@synthesize fileController = _fileController;
@synthesize cloudCodeController = _cloudCodeController;
@synthesize configController = _configController;
@synthesize objectController = _objectController;
@synthesize objectBatchController = _objectBatchController;
@synthesize objectFilePersistenceController = _objectFilePersistenceController;
@synthesize objectLocalIdStore = _objectLocalIdStore;
@synthesize pinningObjectStore = _pinningObjectStore;
@synthesize userAuthenticationController = _userAuthenticationController;
@synthesize sessionController = _sessionController;
@synthesize currentInstallationController = _currentInstallationController;
@synthesize currentUserController = _currentUserController;
@synthesize userController = _userController;
@synthesize installationController = _installationController;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    PFNotDesignatedInitializer();
}

- (instancetype)initWithDataSource:(id<PFCoreManagerDataSource>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    _locationManagerAccessQueue = dispatch_queue_create("com.parse.core.locationManager", DISPATCH_QUEUE_SERIAL);
    _controllerAccessQueue = dispatch_queue_create("com.parse.core.controller.accessQueue", DISPATCH_QUEUE_SERIAL);
    _objectLocalIdStoreAccessQueue = dispatch_queue_create("com.parse.core.object.localIdStore", DISPATCH_QUEUE_SERIAL);

    return self;
}

+ (instancetype)managerWithDataSource:(id<PFCoreManagerDataSource>)dataSource {
    return [[self alloc] initWithDataSource:dataSource];
}

///--------------------------------------
#pragma mark - LocationManager
///--------------------------------------

- (PFLocationManager *)locationManager {
    __block PFLocationManager *manager;
    dispatch_sync(_locationManagerAccessQueue, ^{
        if (!_locationManager) {
            _locationManager = [[PFLocationManager alloc] init];
        }
        manager = _locationManager;
    });
    return manager;
}

///--------------------------------------
#pragma mark - QueryController
///--------------------------------------

- (PFQueryController *)queryController {
    __block PFQueryController *queryController;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_queryController) {
            id<PFCoreManagerDataSource> dataSource = self.dataSource;
            if (dataSource.offlineStoreLoaded) {
                _queryController = [PFOfflineQueryController controllerWithCommonDataSource:dataSource
                                                                             coreDataSource:self];
            } else {
                _queryController = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
            }
        }
        queryController = _queryController;
    });
    return queryController;
}

- (void)setQueryController:(PFQueryController *)queryController {
    dispatch_sync(_controllerAccessQueue, ^{
        _queryController = queryController;
    });
}

///--------------------------------------
#pragma mark - FileController
///--------------------------------------

- (PFFileController *)fileController {
    __block PFFileController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_fileController) {
            _fileController = [PFFileController controllerWithDataSource:self.dataSource];
        }
        controller = _fileController;
    });
    return controller;
}

- (void)setFileController:(PFFileController *)fileController {
    dispatch_sync(_controllerAccessQueue, ^{
        _fileController = fileController;
    });
}

///--------------------------------------
#pragma mark - CloudCodeController
///--------------------------------------

- (PFCloudCodeController *)cloudCodeController {
    __block PFCloudCodeController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_cloudCodeController) {
            _cloudCodeController = [[PFCloudCodeController alloc] initWithCommandRunner:self.dataSource.commandRunner];
        }
        controller = _cloudCodeController;
    });
    return controller;
}

- (void)setCloudCodeController:(PFCloudCodeController *)cloudCodeController {
    dispatch_sync(_controllerAccessQueue, ^{
        _cloudCodeController = cloudCodeController;
    });
}

///--------------------------------------
#pragma mark - ConfigController
///--------------------------------------

- (PFConfigController *)configController {
    __block PFConfigController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_configController) {
            id<PFCoreManagerDataSource> dataSource = self.dataSource;
            _configController = [[PFConfigController alloc] initWithFileManager:dataSource.fileManager
                                                                  commandRunner:dataSource.commandRunner];
        }
        controller = _configController;
    });
    return controller;
}

- (void)setConfigController:(PFConfigController *)configController {
    dispatch_sync(_controllerAccessQueue, ^{
        _configController = configController;
    });
}

///--------------------------------------
#pragma mark - ObjectController
///--------------------------------------

- (PFObjectController *)objectController {
    __block PFObjectController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_objectController) {
            id<PFCoreManagerDataSource> dataSource = self.dataSource;
            if (dataSource.offlineStoreLoaded) {
                _objectController = [PFOfflineObjectController controllerWithDataSource:dataSource];
            } else {
                _objectController = [PFObjectController controllerWithDataSource:dataSource];
            }
        }
        controller = _objectController;
    });
    return controller;
}

- (void)setObjectController:(PFObjectController *)controller {
    dispatch_sync(_controllerAccessQueue, ^{
        _objectController = controller;
    });
}

///--------------------------------------
#pragma mark - ObjectBatchController
///--------------------------------------

- (PFObjectBatchController *)objectBatchController {
    __block PFObjectBatchController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_objectBatchController) {
            _objectBatchController = [PFObjectBatchController controllerWithDataSource:self.dataSource];
        }
        controller = _objectBatchController;
    });
    return controller;
}

///--------------------------------------
#pragma mark - ObjectFilePersistenceController
///--------------------------------------

- (PFObjectFilePersistenceController *)objectFilePersistenceController {
    __block PFObjectFilePersistenceController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_objectFilePersistenceController) {
            _objectFilePersistenceController = [PFObjectFilePersistenceController controllerWithDataSource:self.dataSource];
        }
        controller = _objectFilePersistenceController;
    });
    return controller;
}

- (void)unloadObjectFilePersistenceController {
    dispatch_sync(_controllerAccessQueue, ^{
        _objectFilePersistenceController = nil;
    });
}

///--------------------------------------
#pragma mark - Pinning Object Store
///--------------------------------------

- (PFPinningObjectStore *)pinningObjectStore {
    __block PFPinningObjectStore *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_pinningObjectStore) {
            _pinningObjectStore = [PFPinningObjectStore storeWithDataSource:self.dataSource];
        }
        controller = _pinningObjectStore;
    });
    return controller;
}

- (void)setPinningObjectStore:(PFPinningObjectStore *)pinningObjectStore {
    dispatch_sync(_controllerAccessQueue, ^{
        _pinningObjectStore = pinningObjectStore;
    });
}

///--------------------------------------
#pragma mark - Object LocalId Store
///--------------------------------------

- (PFObjectLocalIdStore *)objectLocalIdStore {
    __block PFObjectLocalIdStore *store = nil;
    @weakify(self);
    dispatch_sync(_objectLocalIdStoreAccessQueue, ^{
        @strongify(self);
        if (!_objectLocalIdStore) {
            _objectLocalIdStore = [[PFObjectLocalIdStore alloc] initWithDataSource:self.dataSource];
        }
        store = _objectLocalIdStore;
    });
    return store;
}

- (void)setObjectLocalIdStore:(PFObjectLocalIdStore *)objectLocalIdStore {
    dispatch_sync(_objectLocalIdStoreAccessQueue, ^{
        _objectLocalIdStore = objectLocalIdStore;
    });
}

///--------------------------------------
#pragma mark - UserAuthenticationController
///--------------------------------------

- (PFUserAuthenticationController *)userAuthenticationController {
    __block PFUserAuthenticationController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_userAuthenticationController) {
            _userAuthenticationController = [PFUserAuthenticationController controllerWithDataSource:self];
        }
        controller = _userAuthenticationController;
    });
    return controller;
}

- (void)setUserAuthenticationController:(PFUserAuthenticationController *)userAuthenticationController {
    dispatch_sync(_controllerAccessQueue, ^{
        _userAuthenticationController = userAuthenticationController;
    });
}

///--------------------------------------
#pragma mark - SessionController
///--------------------------------------

- (PFSessionController *)sessionController {
    __block PFSessionController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_sessionController) {
            _sessionController = [PFSessionController controllerWithDataSource:self.dataSource];
        }
        controller = _sessionController;
    });
    return controller;
}

- (void)setSessionController:(PFSessionController *)sessionController {
    dispatch_sync(_controllerAccessQueue, ^{
        _sessionController = sessionController;
    });
}

#if !TARGET_OS_WATCH

///--------------------------------------
#pragma mark - Current Installation Controller
///--------------------------------------

- (PFCurrentInstallationController *)currentInstallationController {
    __block PFCurrentInstallationController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_currentInstallationController) {
            id<PFCoreManagerDataSource> dataSource = self.dataSource;
            PFCurrentObjectStorageType storageType = (dataSource.offlineStore ?
                                                      PFCurrentObjectStorageTypeOfflineStore :
                                                      PFCurrentObjectStorageTypeFile);
            _currentInstallationController = [PFCurrentInstallationController controllerWithStorageType:storageType
                                                                                       commonDataSource:dataSource
                                                                                         coreDataSource:self];
        }
        controller = _currentInstallationController;
    });
    return controller;
}

- (void)setCurrentInstallationController:(PFCurrentInstallationController *)controller {
    dispatch_sync(_controllerAccessQueue, ^{
        _currentInstallationController = controller;
    });
}

#endif

///--------------------------------------
#pragma mark - Current User Controller
///--------------------------------------

- (PFCurrentUserController *)currentUserController {
    __block PFCurrentUserController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_currentUserController) {
            id<PFCoreManagerDataSource> dataSource = self.dataSource;
            PFCurrentObjectStorageType storageType = (dataSource.offlineStore ?
                                                      PFCurrentObjectStorageTypeOfflineStore :
                                                      PFCurrentObjectStorageTypeFile);
            _currentUserController = [PFCurrentUserController controllerWithStorageType:storageType
                                                                       commonDataSource:dataSource
                                                                         coreDataSource:self];
        }
        controller = _currentUserController;
    });
    return controller;
}

- (void)setCurrentUserController:(PFCurrentUserController *)currentUserController {
    dispatch_sync(_controllerAccessQueue, ^{
        _currentUserController = currentUserController;
    });
}

#if !TARGET_OS_WATCH

///--------------------------------------
#pragma mark - Installation Controller
///--------------------------------------

- (PFInstallationController *)installationController {
    __block PFInstallationController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_installationController) {
            _installationController = [PFInstallationController controllerWithDataSource:self];
        }
        controller = _installationController;
    });
    return controller;
}

- (void)setInstallationController:(PFInstallationController *)installationController {
    dispatch_sync(_controllerAccessQueue, ^{
        _installationController = installationController;
    });
}

#endif

///--------------------------------------
#pragma mark - User Controller
///--------------------------------------

- (PFUserController *)userController {
    __block PFUserController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!_userController) {
            _userController = [PFUserController controllerWithCommonDataSource:self.dataSource
                                                                coreDataSource:self];
        }
        controller = _userController;
    });
    return controller;
}

- (void)setUserController:(PFUserController *)userController {
    dispatch_sync(_controllerAccessQueue, ^{
        _userController = userController;
    });
}

@end
