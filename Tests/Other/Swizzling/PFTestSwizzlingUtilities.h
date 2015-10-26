/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Foundation;

#import <Parse/PFConstants.h>

#import "PFTestSwizzledMethod.h"

@interface PFTestSwizzlingUtilities : NSObject

+ (PFTestSwizzledMethod *)swizzleMethod:(SEL)originalSelector
                             withMethod:(SEL)overrideSelector
                                inClass:(Class)aClass;
+ (PFTestSwizzledMethod *)swizzleMethod:(SEL)originalSelector
                                inClass:(Class)originalClass
                             withMethod:(SEL)overrideSelector
                                inClass:(Class)overrideClass;
+ (PFTestSwizzledMethod *)swizzleClassMethod:(SEL)originalSelector
                                     inClass:(Class)aClass
                                  withMethod:(SEL)overrideSelector
                                     inClass:(Class)overrideClass;

@end
