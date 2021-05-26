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

@interface PFCurrentConfigController : NSObject

@property (nonatomic, weak, readonly) id<PFPersistenceControllerProvider> dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFPersistenceControllerProvider>)dataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(id<PFPersistenceControllerProvider>)dataSource;

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (BFTask *)getCurrentConfigAsync;
- (BFTask *)setCurrentConfigAsync:(PFConfig *)config;

- (BFTask *)clearCurrentConfigAsync;
- (BFTask *)clearMemoryCachedCurrentConfigAsync;

@end
