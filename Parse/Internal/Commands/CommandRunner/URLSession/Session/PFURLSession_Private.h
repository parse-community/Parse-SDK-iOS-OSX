/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSession.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFURLSession ()

- (instancetype)initWithURLSession:(NSURLSession *)session
                          delegate:(id<PFURLSessionDelegate>)delegate NS_DESIGNATED_INITIALIZER;

+ (instancetype)sessionWithURLSession:(NSURLSession *)session
                             delegate:(id<PFURLSessionDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
