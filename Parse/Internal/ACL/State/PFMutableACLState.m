/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMutableACLState.h"

#import "PFACLState_Private.h"

@implementation PFMutableACLState

@dynamic permissions;
@dynamic shared;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _permissions = [NSMutableDictionary dictionary];

    return self;
}

@end
