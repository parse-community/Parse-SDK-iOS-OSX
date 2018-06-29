/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMulticastDelegate.h"

@interface PFMulticastDelegate () {
    NSMutableArray *_callbacks;
}

@end

@implementation PFMulticastDelegate

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _callbacks = [[NSMutableArray alloc] init];

    return self;
}

- (void)subscribe:(void(^)(id result, NSError *error))block {
    [_callbacks addObject:block];
}

- (void)unsubscribe:(void(^)(id result, NSError *error))block {
    [_callbacks removeObject:block];
}

- (void)invoke:(id)result error:(NSError *)error {
    NSArray *callbackCopy = [_callbacks copy];
    for (void (^block)(id result, NSError *error) in callbackCopy) {
        block(result, error);
    }
}
- (void)clear {
    [_callbacks removeAllObjects];
}

@end
