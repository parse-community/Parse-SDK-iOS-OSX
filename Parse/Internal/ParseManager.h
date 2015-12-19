/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/ParseClientConfiguration.h>
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
PFPersistenceControllerProvider,
PFOfflineStoreProvider,
PFEventuallyQueueProvider,
PFKeychainStoreProvider,
PFKeyValueCacheProvider,
PFInstallationIdentifierStoreProvider>

@property (nonatomic, copy, readonly) ParseClientConfiguration *configuration;

@property (nonatomic, strong, readonly) PFCoreManager *coreManager;

#if !TARGET_OS_WATCH && !TARGET_OS_TV
@property (nonatomic, strong) PFPushManager *pushManager;
#endif

@property (nonatomic, strong) PFAnalyticsController *analyticsController;

#if TARGET_OS_IOS || TARGET_OS_TV
@property (nonatomic, strong) PFPurchaseController *purchaseController;
#endif

///--------------------------------------
/// @name Initialization
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;

/**
 Initializes an instance of ParseManager class.

 @param configuration                   Configuration of parse app.

 @return `ParseManager` instance.
 */
- (instancetype)initWithConfiguration:(ParseClientConfiguration *)configuration;

/**
 Begins all necessary operations for this manager to become active.
 */
- (void)startManaging;

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
