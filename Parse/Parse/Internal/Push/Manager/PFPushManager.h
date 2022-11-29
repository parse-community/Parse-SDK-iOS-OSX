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
#import "PFDataProvider.h"

PF_WATCH_UNAVAILABLE_WARNING

@class PFPushChannelsController;
@class PFPushController;

NS_ASSUME_NONNULL_BEGIN

PF_WATCH_UNAVAILABLE @interface PFPushManager : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider> commonDataSource;
@property (nonatomic, weak, readonly) id<PFCurrentInstallationControllerProvider> coreDataSource;

@property (null_resettable, nonatomic, strong) PFPushController *pushController;
@property (null_resettable, nonatomic, strong) PFPushChannelsController *channelsController;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                          coreDataSource:(id<PFCurrentInstallationControllerProvider>)coreDataSource NS_DESIGNATED_INITIALIZER;

+ (instancetype)managerWithCommonDataSource:(id<PFCommandRunnerProvider>)commonDataSource
                             coreDataSource:(id<PFCurrentInstallationControllerProvider>)coreDataSource;

@end

NS_ASSUME_NONNULL_END
