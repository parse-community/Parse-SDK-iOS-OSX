/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <objc/runtime.h>

#import "PFPropertyInfo.h"

@interface PFPropertyInfo ()

@property (atomic, assign, readonly) Class sourceClass;
@property (atomic, assign, readonly, getter=isObject) BOOL object;

@property (atomic, copy, readonly) NSString *typeEncoding;
@property (atomic, assign, readonly) Ivar ivar;

@property (atomic, assign, readonly) SEL getterSelector;
@property (atomic, assign, readonly) SEL setterSelector;

@end
