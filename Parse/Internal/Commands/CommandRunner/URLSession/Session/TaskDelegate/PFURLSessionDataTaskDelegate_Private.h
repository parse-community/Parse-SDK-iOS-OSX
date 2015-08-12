/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFURLSessionDataTaskDelegate.h"

@interface PFURLSessionDataTaskDelegate ()

@property (nonatomic, strong, readonly) dispatch_queue_t dataQueue;

@property (nonatomic, strong, readonly) NSHTTPURLResponse *response;

/*!
 @abstract Defaults to to-memory output stream if not overwritten.
 */
@property (nonatomic, strong, readonly) NSOutputStream *dataOutputStream;
@property (nonatomic, assign, readonly) uint64_t downloadedBytes;

@property (nonatomic, strong) id result;
@property (nonatomic, strong) NSError *error;

- (void)_taskDidFinish NS_REQUIRES_SUPER;
- (void)_taskDidCancel NS_REQUIRES_SUPER;

@end
