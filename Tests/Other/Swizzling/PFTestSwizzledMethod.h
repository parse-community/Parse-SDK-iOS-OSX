/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Foundation;

@interface PFTestSwizzledMethod : NSObject

@property (nonatomic, assign, getter=isSwizzled) BOOL swizzled;

- (instancetype)initWithOriginalSelector:(SEL)originalSelector
                                 inClass:(Class)originalClass
                     replacementSelector:(SEL)replacementSelector
                                 inClass:(Class)replcementClass;

- (instancetype)initWithOriginalSelector:(SEL)originalSelector
                                 inClass:(Class)originalClass
                     replacementSelector:(SEL)replacementSelector
                                 inClass:(Class)replcementClass
                           isClassMethod:(BOOL)isClassMethod;

@end
