/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

#import "PFDataProvider.h"
#import "PFOfflineStore.h"
#import "PFMacros.h"

@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFAnalyticsController;
@class PFCoreManager;
@class PFInstallationIdentifierStore;
@class PFKeychainStore;
@class PFPurchaseController;
@class PFPushManager;

@interface ParseManager : NSObject <PFCommandRunnerProvider,
PFFileManagerProvider,
PFOfflineStoreProvider,
PFEventuallyQueueProvider,
PFKeychainStoreProvider,
PFKeyValueCacheProvider,
PFInstallationIdentifierStoreProvider>

@property (nonatomic, copy, readonly) NSString *applicationId;
@property (nonatomic, copy, readonly) NSString *clientKey;

@property (nonatomic, copy, readonly) NSString *applicationGroupIdentifier;
@property (nonatomic, copy, readonly) NSString *containingApplicationIdentifier;

@property (nonatomic, strong, readonly) PFCoreManager *coreManager;
@property (nonatomic, strong) PFPushManager *pushManager;

@property (nonatomic, strong) PFAnalyticsController *analyticsController;

#if TARGET_OS_IPHONE
@property (nonatomic, strong) PFPurchaseController *purchaseController;
#endif

///--------------------------------------
/// @name Initialization
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;

/*!
 Initializes an instance of ParseManager class.

 @param applicationId                   ApplicationId of Parse app.
 @param clientKey                       ClientKey of Parse app.

 @returns `ParseManager` instance.
 */
- (instancetype)initWithApplicationId:(NSString *)applicationId
                            clientKey:(NSString *)clientKey NS_DESIGNATED_INITIALIZER;

/*!
 Configures ParseManager with specified properties.

 @param applicationGroupIdentifier      Shared AppGroup container identifier.
 @param containingApplicationIdentifier Containg application bundle identifier (for extensions).
 @param localDataStoreEnabled           `BOOL` flag to enable local datastore or not.
 */
- (void)configureWithApplicationGroupIdentifier:(NSString *)applicationGroupIdentifier
                containingApplicationIdentifier:(NSString *)containingApplicationIdentifier
                          enabledLocalDataStore:(BOOL)localDataStoreEnabled;

///--------------------------------------
/// @name Offline Store
///--------------------------------------

- (void)loadOfflineStoreWithOptions:(PFOfflineStoreOptions)options;

///--------------------------------------
/// @name Eventually Queue
///--------------------------------------

- (void)clearEventuallyQueue;

///--------------------------------------
/// @name Core Manager
///--------------------------------------

- (void)unloadCoreManager;

///--------------------------------------
/// @name Preloading
///--------------------------------------

- (BFTask *)preloadDiskObjectsToMemoryAsync;

@end
