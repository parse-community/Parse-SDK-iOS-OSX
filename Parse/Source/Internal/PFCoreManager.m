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
#import "PFCurrentUserController.h"
#import "PFDefaultACLController.h"
#import "PFFileController.h"
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

#if !TARGET_OS_WATCH
#import "PFCurrentInstallationController.h"
#import "PFInstallationController.h"
#endif

@interface PFCoreManager () {
    dispatch_queue_t _locationManagerAccessQueue;
    dispatch_queue_t _controllerAccessQueue;
    dispatch_queue_t _objectLocalIdStoreAccessQueue;
}

@end

@implementation PFCoreManager

@synthesize locationManager = _locationManager;
@synthesize defaultACLController = _defaultACLController;

@synthesize queryController = _queryController;
@synthesize fileController = _fileController;
@synthesize cloudCodeController = _cloudCodeController;
@synthesize configController = _configController;
@synthesize objectController = _objectController;
@synthesize objectSubclassingController = _objectSubclassingController;
@synthesize objectBatchController = _objectBatchController;
@synthesize objectFilePersistenceController = _objectFilePersistenceController;
@synthesize objectLocalIdStore = _objectLocalIdStore;
@synthesize pinningObjectStore = _pinningObjectStore;
@synthesize userAuthenticationController = _userAuthenticationController;
@synthesize sessionController = _sessionController;
@synthesize currentUserController = _currentUserController;
@synthesize userController = _userController;

#if !TARGET_OS_WATCH
@synthesize currentInstallationController = _currentInstallationController;
@synthesize installationController = _installationController;
#endif


///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFCoreManagerDataSource>)dataSource {
    self = [super init];
    if (!self) return nil;

    _dataSource = dataSource;

    _locationManagerAccessQueue = dispatch_queue_create("com.parse.core.locationManager", DISPATCH_QUEUE_SERIAL);
    _controllerAccessQueue = dispatch_queue_create("com.parse.core.controller.accessQueue", DISPATCH_QUEUE_SERIAL);
    _objectLocalIdStoreAccessQueue = dispatch_queue_create("com.parse.core.object.localIdStore", DISPATCH_QUEUE_SERIAL);
    [self objectSubclassingController];
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
        if (!self->_locationManager) {
            self->_locationManager = [[PFLocationManager alloc] init];
        }
        manager = self->_locationManager;
    });
    return manager;
}

///--------------------------------------
#pragma mark - DefaultACLController
///--------------------------------------

- (PFDefaultACLController *)defaultACLController {
    __block PFDefaultACLController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_defaultACLController) {
            self->_defaultACLController = [PFDefaultACLController controllerWithDataSource:self];
        }
        controller = self->_defaultACLController;
    });
    return controller;
}

///--------------------------------------
#pragma mark - QueryController
///--------------------------------------

- (PFQueryController *)queryController {
    __block PFQueryController *queryController;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_queryController) {
            id<PFCoreManagerDataSource> dataSource = self.dataSource;
            if (dataSource.offlineStoreLoaded) {
                self->_queryController = [PFOfflineQueryController controllerWithCommonDataSource:dataSource
                                                                             coreDataSource:self];
            } else {
                self->_queryController = [PFCachedQueryController controllerWithCommonDataSource:dataSource];
            }
        }
        queryController = self->_queryController;
    });
    return queryController;
}

- (void)setQueryController:(PFQueryController *)queryController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_queryController = queryController;
    });
}

///--------------------------------------
#pragma mark - FileController
///--------------------------------------

- (PFFileController *)fileController {
    __block PFFileController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_fileController) {
            self->_fileController = [PFFileController controllerWithDataSource:self.dataSource];
        }
        controller = self->_fileController;
    });
    return controller;
}

- (void)setFileController:(PFFileController *)fileController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_fileController = fileController;
    });
}

///--------------------------------------
#pragma mark - CloudCodeController
///--------------------------------------

- (PFCloudCodeController *)cloudCodeController {
    __block PFCloudCodeController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_cloudCodeController) {
            self->_cloudCodeController = [[PFCloudCodeController alloc] initWithDataSource:self.dataSource];
        }
        controller = self->_cloudCodeController;
    });
    return controller;
}

- (void)setCloudCodeController:(PFCloudCodeController *)cloudCodeController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_cloudCodeController = cloudCodeController;
    });
}

///--------------------------------------
#pragma mark - ConfigController
///--------------------------------------

- (PFConfigController *)configController {
    __block PFConfigController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_configController) {
            self->_configController = [[PFConfigController alloc] initWithDataSource:self.dataSource];
        }
        controller = self->_configController;
    });
    return controller;
}

- (void)setConfigController:(PFConfigController *)configController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_configController = configController;
    });
}

///--------------------------------------
#pragma mark - ObjectController
///--------------------------------------

- (PFObjectController *)objectController {
    __block PFObjectController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_objectController) {
            id<PFCoreManagerDataSource> dataSource = self.dataSource;
            if (dataSource.offlineStoreLoaded) {
                self->_objectController = [PFOfflineObjectController controllerWithDataSource:dataSource];
            } else {
                self->_objectController = [PFObjectController controllerWithDataSource:dataSource];
            }
        }
        controller = self->_objectController;
    });
    return controller;
}

- (void)setObjectController:(PFObjectController *)controller {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_objectController = controller;
    });
}

///--------------------------------------
#pragma mark - ObjectSubclassingController
///--------------------------------------

- (PFObjectSubclassingController *)objectSubclassingController {
    __block PFObjectSubclassingController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_objectSubclassingController) {
            self->_objectSubclassingController = [[PFObjectSubclassingController alloc] init];
            [self->_objectSubclassingController scanForUnregisteredSubclasses:YES];
        }
        controller = self->_objectSubclassingController;
    });
    return controller;
}

- (void)setObjectSubclassingController:(PFObjectSubclassingController *)objectSubclassingController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_objectSubclassingController = objectSubclassingController;
    });
}

///--------------------------------------
#pragma mark - ObjectBatchController
///--------------------------------------

- (PFObjectBatchController *)objectBatchController {
    __block PFObjectBatchController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_objectBatchController) {
            self->_objectBatchController = [PFObjectBatchController controllerWithDataSource:self.dataSource];
        }
        controller = self->_objectBatchController;
    });
    return controller;
}

///--------------------------------------
#pragma mark - ObjectFilePersistenceController
///--------------------------------------

- (PFObjectFilePersistenceController *)objectFilePersistenceController {
    __block PFObjectFilePersistenceController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_objectFilePersistenceController) {
            self->_objectFilePersistenceController = [PFObjectFilePersistenceController controllerWithDataSource:self.dataSource];
        }
        controller = self->_objectFilePersistenceController;
    });
    return controller;
}

- (void)unloadObjectFilePersistenceController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_objectFilePersistenceController = nil;
    });
}

///--------------------------------------
#pragma mark - Pinning Object Store
///--------------------------------------

- (PFPinningObjectStore *)pinningObjectStore {
    __block PFPinningObjectStore *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_pinningObjectStore) {
            self->_pinningObjectStore = [PFPinningObjectStore storeWithDataSource:self.dataSource];
        }
        controller = self->_pinningObjectStore;
    });
    return controller;
}

- (void)setPinningObjectStore:(PFPinningObjectStore *)pinningObjectStore {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_pinningObjectStore = pinningObjectStore;
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
        if (!self->_objectLocalIdStore) {
            self->_objectLocalIdStore = [[PFObjectLocalIdStore alloc] initWithDataSource:self.dataSource];
        }
        store = self->_objectLocalIdStore;
    });
    return store;
}

- (void)setObjectLocalIdStore:(PFObjectLocalIdStore *)objectLocalIdStore {
    dispatch_sync(_objectLocalIdStoreAccessQueue, ^{
        self->_objectLocalIdStore = objectLocalIdStore;
    });
}

///--------------------------------------
#pragma mark - UserAuthenticationController
///--------------------------------------

- (PFUserAuthenticationController *)userAuthenticationController {
    __block PFUserAuthenticationController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_userAuthenticationController) {
            self->_userAuthenticationController = [PFUserAuthenticationController controllerWithDataSource:self];
        }
        controller = self->_userAuthenticationController;
    });
    return controller;
}

- (void)setUserAuthenticationController:(PFUserAuthenticationController *)userAuthenticationController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_userAuthenticationController = userAuthenticationController;
    });
}

///--------------------------------------
#pragma mark - SessionController
///--------------------------------------

- (PFSessionController *)sessionController {
    __block PFSessionController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_sessionController) {
            self->_sessionController = [PFSessionController controllerWithDataSource:self.dataSource];
        }
        controller = self->_sessionController;
    });
    return controller;
}

- (void)setSessionController:(PFSessionController *)sessionController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_sessionController = sessionController;
    });
}

#if !TARGET_OS_WATCH

///--------------------------------------
#pragma mark - Current Installation Controller
///--------------------------------------

- (PFCurrentInstallationController *)currentInstallationController {
    __block PFCurrentInstallationController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_currentInstallationController) {
            id<PFCoreManagerDataSource> dataSource = self.dataSource;
            PFCurrentObjectStorageType storageType = (dataSource.offlineStore ?
                                                      PFCurrentObjectStorageTypeOfflineStore :
                                                      PFCurrentObjectStorageTypeFile);
            self->_currentInstallationController = [PFCurrentInstallationController controllerWithStorageType:storageType
                                                                                             commonDataSource:dataSource
                                                                                               coreDataSource:self];
        }
        controller = self->_currentInstallationController;
    });
    return controller;
}

- (void)setCurrentInstallationController:(PFCurrentInstallationController *)controller {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_currentInstallationController = controller;
    });
}

#endif

///--------------------------------------
#pragma mark - Current User Controller
///--------------------------------------

- (PFCurrentUserController *)currentUserController {
    __block PFCurrentUserController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_currentUserController) {
            id<PFCoreManagerDataSource> dataSource = self.dataSource;
            PFCurrentObjectStorageType storageType = (dataSource.offlineStore ?
                                                      PFCurrentObjectStorageTypeOfflineStore :
                                                      PFCurrentObjectStorageTypeFile);
            self->_currentUserController = [PFCurrentUserController controllerWithStorageType:storageType
                                                                           commonDataSource:dataSource
                                                                             coreDataSource:self];
        }
        controller = self->_currentUserController;
    });
    return controller;
}

- (void)setCurrentUserController:(PFCurrentUserController *)currentUserController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_currentUserController = currentUserController;
    });
}

#if !TARGET_OS_WATCH

///--------------------------------------
#pragma mark - Installation Controller
///--------------------------------------

- (PFInstallationController *)installationController {
    __block PFInstallationController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_installationController) {
            self->_installationController = [PFInstallationController controllerWithDataSource:self];
        }
        controller = self->_installationController;
    });
    return controller;
}

- (void)setInstallationController:(PFInstallationController *)installationController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_installationController = installationController;
    });
}

#endif

///--------------------------------------
#pragma mark - User Controller
///--------------------------------------

- (PFUserController *)userController {
    __block PFUserController *controller = nil;
    dispatch_sync(_controllerAccessQueue, ^{
        if (!self->_userController) {
            self->_userController = [PFUserController controllerWithCommonDataSource:self.dataSource
                                                                      coreDataSource:self];
        }
        controller = self->_userController;
    });
    return controller;
}

- (void)setUserController:(PFUserController *)userController {
    dispatch_sync(_controllerAccessQueue, ^{
        self->_userController = userController;
    });
}

@end
