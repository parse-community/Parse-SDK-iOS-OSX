/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFConstants.h"

#import "PFCoreDataProvider.h"
#import "PFCurrentObjectControlling.h"
#import "PFDataProvider.h"
#import "PFMacros.h"

PF_WATCH_UNAVAILABLE_WARNING

extern NSString *const PFCurrentInstallationFileName;
extern NSString *const PFCurrentInstallationPinName;

@class BFTask<__covariant BFGenericType>;
@class PFInstallation;

PF_WATCH_UNAVAILABLE @interface PFCurrentInstallationController : NSObject <PFCurrentObjectControlling>

@property (nonatomic, weak, readonly) id<PFInstallationIdentifierStoreProvider> commonDataSource;
@property (nonatomic, weak, readonly) id<PFObjectFilePersistenceControllerProvider> coreDataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStorageType:(PFCurrentObjectStorageType)dataStorageType
                   commonDataSource:(id<PFInstallationIdentifierStoreProvider>)commonDataSource
                     coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource;

+ (instancetype)controllerWithStorageType:(PFCurrentObjectStorageType)dataStorageType
                         commonDataSource:(id<PFInstallationIdentifierStoreProvider>)commonDataSource
                           coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource;

///--------------------------------------
#pragma mark - Installation
///--------------------------------------

@property (nonatomic, strong, readonly) PFInstallation *memoryCachedCurrentInstallation;

- (BFTask *)clearCurrentInstallationAsync;
- (BFTask *)clearMemoryCachedCurrentInstallationAsync;

@end
