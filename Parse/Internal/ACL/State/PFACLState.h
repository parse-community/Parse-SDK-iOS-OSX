/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFBaseState.h"

NS_ASSUME_NONNULL_BEGIN

@class PFMutableACLState;

typedef void (^PFACLStateMutationBlock)(PFMutableACLState *);

@interface PFACLState : PFBaseState<PFBaseStateSubclass, NSCopying, NSMutableCopying>

@property (nonatomic, copy, readonly) NSDictionary *permissions;
@property (nonatomic, assign, readonly, getter=isShared) BOOL shared;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithState:(PFACLState *)otherState NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithState:(PFACLState *)otherState mutatingBlock:(PFACLStateMutationBlock)mutatingBlock;

+ (instancetype)stateWithState:(PFACLState *)otherState;
+ (instancetype)stateWithState:(PFACLState *)otherState mutatingBlock:(PFACLStateMutationBlock)mutatingBlock;

///--------------------------------------
#pragma mark - Mutating
///--------------------------------------

- (PFACLState *)copyByMutatingWithBlock:(PFACLStateMutationBlock)mutatingBlock;

@end

NS_ASSUME_NONNULL_END
