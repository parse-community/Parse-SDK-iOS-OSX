/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFBaseState.h"

@class PFObject;

@interface PFRelationState : PFBaseState <PFBaseStateSubclass, NSCopying, NSMutableCopying>

@property (nonatomic, weak, readonly) PFObject *parent;
@property (nonatomic, copy, readonly) NSString *parentClassName;
@property (nonatomic, copy, readonly) NSString *parentObjectId;
@property (nonatomic, copy, readonly) NSString *targetClass;
@property (nonatomic, copy, readonly) NSSet *knownObjects;
@property (nonatomic, copy, readonly) NSString *key;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithState:(PFRelationState *)otherState;
+ (instancetype)stateWithState:(PFRelationState *)otherState;

@end
