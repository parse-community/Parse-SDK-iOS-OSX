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

@class BFTask PF_GENERIC(__covariant BFGenericType);

NS_ASSUME_NONNULL_BEGIN

PF_WATCH_UNAVAILABLE @interface PFPushChannelsController : NSObject

@property (nonatomic, weak, readonly) id<PFCurrentInstallationControllerProvider> dataSource;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFCurrentInstallationControllerProvider>)dataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)controllerWithDataSource:(id<PFCurrentInstallationControllerProvider>)dataSource;

///--------------------------------------
/// @name Get
///--------------------------------------

- (BFTask *)getSubscribedChannelsAsync;

///--------------------------------------
/// @name Subscribe
///--------------------------------------

- (BFTask *)subscribeToChannelAsyncWithName:(NSString *)name;
- (BFTask *)unsubscribeFromChannelAsyncWithName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
