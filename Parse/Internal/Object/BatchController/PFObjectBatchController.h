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

@class BFTask;

NS_ASSUME_NONNULL_BEGIN

@interface PFObjectBatchController : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider> dataSource;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider>)dataSource;

///--------------------------------------
/// @name Fetch
///--------------------------------------

- (BFTask *)fetchObjectsAsync:(nullable NSArray *)objects withSessionToken:(nullable NSString *)sessionToken;

///--------------------------------------
/// @name Utilities
///--------------------------------------

+ (nullable NSArray *)uniqueObjectsArrayFromArray:(nullable NSArray *)objects omitObjectsWithData:(BOOL)omitFetched;

@end

NS_ASSUME_NONNULL_END
