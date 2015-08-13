/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class PFObject;
@protocol PFSubclassing;

@interface PFObjectSubclassingController : NSObject

///--------------------------------------
#pragma mark - Registration
///--------------------------------------

- (void)scanForUnregisteredSubclasses:(BOOL)shouldSubscribe;

- (Class<PFSubclassing>)subclassForParseClassName:(NSString *)parseClassName;
- (void)registerSubclass:(Class<PFSubclassing>)kls;
- (void)unregisterSubclass:(Class<PFSubclassing>)kls;

///--------------------------------------
#pragma mark - Forwarding
///--------------------------------------

- (NSMethodSignature *)forwardingMethodSignatureForSelector:(SEL)cmd ofClass:(Class)kls;
- (BOOL)forwardObjectInvocation:(NSInvocation *)invocation withObject:(PFObject<PFSubclassing> *)object;

@end
