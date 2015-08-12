/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

/*!
 Represents an event that can be subscribed to by multiple observers.
 */
@interface PFMulticastDelegate : NSObject {
@private
    NSMutableArray *callbacks;
}

/*!
 Subscribes a block for callback.

 Important: if you ever plan to be able to unsubscribe the block, you must copy the block
 before passing it to subscribe, and use the same instance for unsubscribe.
 */
- (void)subscribe:(void(^)(id result, NSError *error))block;
- (void)unsubscribe:(void(^)(id result, NSError *error))block;
- (void)invoke:(id)result error:(NSError *)error;
- (void)clear;

@end
