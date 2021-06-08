/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#if SWIFT_PACKAGE
@import Bolts;
#else
#import <Bolts/BFTask.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PFAsyncTaskQueue : NSObject

+ (instancetype)taskQueue;

- (BFTask *)enqueue:(BFContinuationBlock)block;

@end

NS_ASSUME_NONNULL_END
