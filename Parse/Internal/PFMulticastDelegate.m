/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMulticastDelegate.h"

@implementation PFMulticastDelegate

- (instancetype)init {
    if (self = [super init]) {
        callbacks = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)subscribe:(void(^)(id result, NSError *error))block {
    [callbacks addObject:block];
}

- (void)unsubscribe:(void(^)(id result, NSError *error))block {
    [callbacks removeObject:block];
}

- (void)invoke:(id)result error:(NSError *)error {
    NSArray *callbackCopy = [callbacks copy];
    for (void (^block)(id result, NSError *error) in callbackCopy) {
        block(result, error);
    }
}
- (void)clear {
    [callbacks removeAllObjects];
}

@end
