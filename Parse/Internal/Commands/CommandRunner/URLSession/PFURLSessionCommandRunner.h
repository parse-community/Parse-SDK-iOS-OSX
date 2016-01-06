/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFCommandRunning.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFURLSessionCommandRunner : NSObject <PFCommandRunning>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)commandRunnerWithDataSource:(id<PFInstallationIdentifierStoreProvider>)dataSource
                              retryAttempts:(NSUInteger)retryAttempts
                              applicationId:(NSString *)applicationId
                                  clientKey:(NSString *)clientKey
                                  serverURL:(NSURL *)serverURL;

@end

NS_ASSUME_NONNULL_END
