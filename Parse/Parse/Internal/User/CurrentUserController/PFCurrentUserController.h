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

#import "PFCoreDataProvider.h"
#import "PFCurrentObjectControlling.h"
#import "PFDataProvider.h"
#import "PFMacros.h"

@class BFTask<__covariant BFGenericType>;
@class PFUser;

typedef NS_OPTIONS(NSUInteger, PFCurrentUserLoadingOptions) {
    PFCurrentUserLoadingOptionCreateLazyIfNotAvailable = 1 << 0,
};

@interface PFCurrentUserController : NSObject <PFCurrentObjectControlling>

@property (nonatomic, weak, readonly) id<PFKeychainStoreProvider> commonDataSource;
@property (nonatomic, weak, readonly) id<PFObjectFilePersistenceControllerProvider> coreDataSource;

@property (atomic, assign) BOOL automaticUsersEnabled;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithStorageType:(PFCurrentObjectStorageType)storageType
                   commonDataSource:(id<PFKeychainStoreProvider>)commonDataSource
                     coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)controllerWithStorageType:(PFCurrentObjectStorageType)storageType
                         commonDataSource:(id<PFKeychainStoreProvider>)commonDataSource
                           coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource;

///--------------------------------------
#pragma mark - User
///--------------------------------------

- (BFTask *)getCurrentUserAsyncWithOptions:(PFCurrentUserLoadingOptions)options;

- (BFTask *)logOutCurrentUserAsync;

///--------------------------------------
#pragma mark - Session Token
///--------------------------------------

- (BFTask *)getCurrentUserSessionTokenAsync;

@end
