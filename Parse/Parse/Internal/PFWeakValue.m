/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFWeakValue.h"

@interface PFWeakValue ()

@property (nonatomic, weak, readwrite) id weakObject;

@end

@implementation PFWeakValue

+ (instancetype)valueWithWeakObject:(id)object {
    PFWeakValue *value = [[self alloc] init];
    value.weakObject = object;
    return value;
}

@end
