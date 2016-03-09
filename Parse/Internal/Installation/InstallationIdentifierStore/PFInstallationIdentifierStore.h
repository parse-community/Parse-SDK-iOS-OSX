/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFDataProvider.h"

#import <Parse/PFConstants.h>

@class BFTask<__covariant BFGenericType>;

@interface PFInstallationIdentifierStore : NSObject

@property (nonatomic, weak, readonly) id<PFPersistenceControllerProvider> dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFPersistenceControllerProvider>)dataSource NS_DESIGNATED_INITIALIZER;

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

/**
 Returns a cached installationId or creates a new one, saves it to disk and returns it.
 */
- (BFTask<NSString *> *)getInstallationIdentifierAsync;

///--------------------------------------
#pragma mark - Clear
///--------------------------------------

/**
 Clears installation identifier on disk and in-memory.
 */
- (BFTask *)clearInstallationIdentifierAsync;

@end
