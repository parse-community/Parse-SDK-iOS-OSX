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

extern NSString *const PFCurrentInstallationFileName;
extern NSString *const PFCurrentInstallationPinName;

@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFInstallation;

@interface PFCurrentInstallationController : NSObject <PFCurrentObjectControlling>

@property (nonatomic, weak, readonly) id<PFFileManagerProvider, PFInstallationIdentifierStoreProvider> commonDataSource;
@property (nonatomic, weak, readonly) id<PFObjectFilePersistenceControllerProvider> coreDataSource;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithStorageType:(PFCurrentObjectStorageType)dataStorageType
                   commonDataSource:(id<PFFileManagerProvider, PFInstallationIdentifierStoreProvider>)commonDataSource
                     coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource;

+ (instancetype)controllerWithStorageType:(PFCurrentObjectStorageType)dataStorageType
                         commonDataSource:(id<PFFileManagerProvider, PFInstallationIdentifierStoreProvider>)commonDataSource
                           coreDataSource:(id<PFObjectFilePersistenceControllerProvider>)coreDataSource;

///--------------------------------------
/// @name Installation
///--------------------------------------

@property (nonatomic, strong, readonly) PFInstallation *memoryCachedCurrentInstallation;

- (BFTask *)clearCurrentInstallationAsync;
- (BFTask *)clearMemoryCachedCurrentInstallationAsync;

@end
