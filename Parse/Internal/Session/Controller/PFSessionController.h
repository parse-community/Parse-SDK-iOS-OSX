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
@class PFSession;

NS_ASSUME_NONNULL_BEGIN

@interface PFSessionController : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider> dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource;
+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider>)dataSource;

///--------------------------------------
#pragma mark - Current Session
///--------------------------------------

- (BFTask *)getCurrentSessionAsyncWithSessionToken:(nullable NSString *)sessionToken;

@end

NS_ASSUME_NONNULL_END
