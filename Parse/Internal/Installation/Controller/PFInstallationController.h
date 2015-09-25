/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFCoreDataProvider.h"
#import "PFObjectControlling.h"

NS_ASSUME_NONNULL_BEGIN

PF_WATCH_UNAVAILABLE @interface PFInstallationController : NSObject <PFObjectControlling>

@property (nonatomic, weak, readonly) id<PFObjectControllerProvider, PFCurrentInstallationControllerProvider> dataSource;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFObjectControllerProvider, PFCurrentInstallationControllerProvider>)dataSource;
+ (instancetype)controllerWithDataSource:(id<PFObjectControllerProvider, PFCurrentInstallationControllerProvider>)dataSource;

@end

NS_ASSUME_NONNULL_END
