/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSessionCommandRunner.h"

@class PFCommandURLRequestConstructor;
@class PFURLSession;

NS_ASSUME_NONNULL_BEGIN

@interface PFURLSessionCommandRunner ()

@property (nonatomic, strong, readonly) PFURLSession *session;
@property (nonatomic, strong, readonly) PFCommandURLRequestConstructor *requestConstructor;

- (instancetype)initWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                           session:(PFURLSession *)session
                requestConstructor:(PFCommandURLRequestConstructor *)requestConstructor
                notificationCenter:(NSNotificationCenter *)notificationCenter NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
