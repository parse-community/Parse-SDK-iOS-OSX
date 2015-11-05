/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestSwizzledMethod.h"

@import ObjectiveC.runtime;

@interface PFTestSwizzledMethod ()

@property (nonatomic, assign) Method originalMethod;
@property (nonatomic, assign) Method overrideMethod;

@end

@implementation PFTestSwizzledMethod

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithOriginalSelector:(SEL)originalSelector
                                 inClass:(Class)originalClass
                     replacementSelector:(SEL)replacementSelector
                                 inClass:(Class)replacementClass
                           isClassMethod:(BOOL)isClassMethod{
    self = [super init];
    if (!self) return nil;

    _originalMethod = class_getInstanceMethod(originalClass, originalSelector);
    if (_originalMethod == NULL || isClassMethod) {
        _originalMethod = class_getClassMethod(originalClass, originalSelector);
    }

    _overrideMethod = class_getInstanceMethod(replacementClass, replacementSelector);
    if (_overrideMethod == NULL || isClassMethod) {
        _overrideMethod = class_getClassMethod(replacementClass, replacementSelector);
    }

    return self;
}

- (instancetype)initWithOriginalSelector:(SEL)originalSelector
                                 inClass:(Class)originalClass
                     replacementSelector:(SEL)replacementSelector
                                 inClass:(Class)replcementClass {
    return [self initWithOriginalSelector:originalSelector
                                  inClass:originalClass
                      replacementSelector:replacementSelector
                                  inClass:replcementClass
                            isClassMethod:NO];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setSwizzled:(BOOL)swizzled {
    if (self.swizzled != swizzled) {
        _swizzled = swizzled;

        method_exchangeImplementations(self.originalMethod, self.overrideMethod);
    }
}

@end
