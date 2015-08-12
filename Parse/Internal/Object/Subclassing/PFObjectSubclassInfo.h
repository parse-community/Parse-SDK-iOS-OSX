/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class PFPropertyInfo;

@interface PFObjectSubclassInfo : NSObject

@property (atomic, strong) Class subclass;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSubclass:(Class)kls NS_DESIGNATED_INITIALIZER;
+ (instancetype)subclassInfoWithSubclass:(Class)kls;

- (PFPropertyInfo *)propertyInfoForSelector:(SEL)cmd isSetter:(BOOL *)isSetter;
- (NSMethodSignature *)forwardingMethodSignatureForSelector:(SEL)cmd;

@end
