/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFCoreDataProvider.h"
#import "PFDataProvider.h"

@class PFInstallationIdentifierStore;

NS_ASSUME_NONNULL_BEGIN

@protocol PFCoreManagerDataSource
<PFCommandRunnerProvider,
PFKeychainStoreProvider,
PFFileManagerProvider,
PFOfflineStoreProvider,
PFKeyValueCacheProvider,
PFInstallationIdentifierStoreProvider>

@property (nonatomic, strong, readonly) PFInstallationIdentifierStore *installationIdentifierStore;

@end

@class PFCloudCodeController;
@class PFConfigController;
@class PFFileController;
@class PFObjectFilePersistenceController;
@class PFObjectSubclassingController;
@class PFPinningObjectStore;
@class PFQueryController;
@class PFSessionController;

@interface PFCoreManager : NSObject
<PFLocationManagerProvider,
PFObjectControllerProvider,
PFObjectBatchController,
PFObjectFilePersistenceControllerProvider,
PFPinningObjectStoreProvider,
PFObjectLocalIdStoreProvider,
PFUserAuthenticationControllerProvider,
PFCurrentInstallationControllerProvider,
PFCurrentUserControllerProvider,
PFInstallationControllerProvider,
PFUserControllerProvider>

@property (nonatomic, weak, readonly) id<PFCoreManagerDataSource> dataSource;

@property (nonatomic, strong) PFQueryController *queryController;
@property (nonatomic, strong) PFFileController *fileController;
@property (nonatomic, strong) PFCloudCodeController *cloudCodeController;
@property (nonatomic, strong) PFConfigController *configController;
@property (nonatomic, strong) PFSessionController *sessionController;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFCoreManagerDataSource>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)managerWithDataSource:(id<PFCoreManagerDataSource>)dataSource;

///--------------------------------------
/// @name ObjectFilePersistenceController
///--------------------------------------

- (void)unloadObjectFilePersistenceController;

@end

NS_ASSUME_NONNULL_END
