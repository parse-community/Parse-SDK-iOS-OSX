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

@class BFTask<__covariant BFGenericType>;
@class PFConfig;
@class PFCurrentConfigController;

@interface PFConfigController : NSObject

@property (nonatomic, weak, readonly) id<PFPersistenceControllerProvider, PFCommandRunnerProvider> dataSource;

@property (nonatomic, strong, readonly) PFCurrentConfigController *currentConfigController;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFPersistenceControllerProvider, PFCommandRunnerProvider>)dataSource NS_DESIGNATED_INITIALIZER;

///--------------------------------------
#pragma mark - Fetch
///--------------------------------------

/**
 Fetches current config from network async.

 @param sessionToken Current user session token.

 @return `BFTask` with result set to `PFConfig`.
 */
- (BFTask *)fetchConfigAsyncWithSessionToken:(NSString *)sessionToken;

@end
