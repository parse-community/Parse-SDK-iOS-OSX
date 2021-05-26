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

@interface PFCachedQueryController : PFQueryController <PFQueryControllerSubclass>

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider, PFKeyValueCacheProvider> commonDataSource;

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider, PFKeyValueCacheProvider>)dataSource;
+ (instancetype)controllerWithCommonDataSource:(id<PFCommandRunnerProvider, PFKeyValueCacheProvider>)dataSource;

@end

NS_ASSUME_NONNULL_END
