/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFQueryController.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFOfflineQueryController : PFQueryController <PFQueryControllerSubclass>

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider, PFOfflineStoreProvider> commonDataSource;
@property (nonatomic, weak, readonly) id<PFPinningObjectStoreProvider> coreDataSource;

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider>)dataSource NS_UNAVAILABLE;
+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider>)dataSource NS_UNAVAILABLE;

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider, PFOfflineStoreProvider>)dataSource
                          coreDataSource:(id<PFPinningObjectStoreProvider>)coreDataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider, PFOfflineStoreProvider>)dataSource
                                coreDataSource:(id<PFPinningObjectStoreProvider>)coreDataSource;

@end

NS_ASSUME_NONNULL_END
