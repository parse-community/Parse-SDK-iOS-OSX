/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSessionDataTaskDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFURLSessionDataTaskDelegate ()

@property (nonatomic, strong, readonly) dispatch_queue_t dataQueue;

/**
 Defaults to to-memory output stream if not overwritten.
 */
@property (nonatomic, strong, readonly) NSOutputStream *dataOutputStream;
@property (nonatomic, assign, readonly) uint64_t downloadedBytes;

@property (nullable, nonatomic, strong) id result;
@property (nullable, nonatomic, strong) NSError *error;

@property (nullable, nonatomic, copy, readwrite) NSString *responseString;

- (void)_taskDidFinish NS_REQUIRES_SUPER;
- (void)_taskDidCancel NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
