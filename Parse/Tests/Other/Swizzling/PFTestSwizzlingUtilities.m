/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestSwizzlingUtilities.h"

@implementation PFTestSwizzlingUtilities

+ (PFTestSwizzledMethod *)swizzleMethod:(SEL)originalSelector
                                inClass:(Class)originalClass
                             withMethod:(SEL)overrideSelector
                                inClass:(Class)overrideClass {
    PFTestSwizzledMethod *method = [[PFTestSwizzledMethod alloc] initWithOriginalSelector:originalSelector
                                                                                  inClass:originalClass
                                                                      replacementSelector:overrideSelector
                                                                                  inClass:overrideClass];
    method.swizzled = YES;
    return method;
}

+ (PFTestSwizzledMethod *)swizzleMethod:(SEL)originalSelector
                             withMethod:(SEL)overrideSelector
                                inClass:(Class)aClass {
    return [self swizzleMethod:originalSelector
                       inClass:aClass
                    withMethod:overrideSelector
                       inClass:aClass];
}

+ (PFTestSwizzledMethod *)swizzleClassMethod:(SEL)originalSelector
                                     inClass:(Class)aClass
                                  withMethod:(SEL)overrideSelector
                                     inClass:(Class)overrideClass {
  PFTestSwizzledMethod *method = [[PFTestSwizzledMethod alloc] initWithOriginalSelector:originalSelector
                                                                                inClass:aClass
                                                                    replacementSelector:overrideSelector
                                                                                inClass:overrideClass
                                                                          isClassMethod:YES];
  method.swizzled = YES;
  return method;
}

@end
