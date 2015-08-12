/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPaymentTransactionObserver.h"

@interface PFPaymentTransactionObserver ()

@property (nonatomic, strong) NSMutableDictionary *blocks;
@property (nonatomic, strong) NSMutableDictionary *runOnceBlocks;
@property (nonatomic, strong) NSObject *lockObj;
@property (nonatomic, strong) NSObject *runOnceLockObj;

@end
