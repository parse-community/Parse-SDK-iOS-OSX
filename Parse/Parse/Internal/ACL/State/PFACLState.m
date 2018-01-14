/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFACLState_Private.h"

#import "PFMutableACLState.h"

@implementation PFACLState

///--------------------------------------
#pragma mark - PFBaseStateSubclass
///--------------------------------------

+ (NSDictionary *)propertyAttributes {
    return @{
        PFACLStatePropertyName(permissions): [PFPropertyAttributes attributes],
        PFACLStatePropertyName(shared): [PFPropertyAttributes attributes],
    };
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return self;

    _permissions = @{};
    _shared = NO;

    return self;
}

- (instancetype)initWithState:(PFACLState *)otherState {
    return [super initWithState:otherState];
}

- (instancetype)initWithState:(PFACLState *)otherState mutatingBlock:(PFACLStateMutationBlock)mutatingBlock {
    self = [self initWithState:otherState];
    if (!self) return self;

    // Make permissions mutable for the duration of the block.
    _permissions = [_permissions mutableCopy];

    mutatingBlock((PFMutableACLState *)self);

    _permissions = [_permissions copy];

    return self;
}

+ (instancetype)stateWithState:(PFACLState *)otherState {
    return [super stateWithState:otherState];
}

+ (instancetype)stateWithState:(PFACLState *)otherState mutatingBlock:(PFACLStateMutationBlock)mutatingBlock {
    return [[self alloc] initWithState:otherState mutatingBlock:mutatingBlock];
}

///--------------------------------------
#pragma mark - Copying
///--------------------------------------

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[PFACLState allocWithZone:zone] initWithState:self];
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    return [[PFMutableACLState allocWithZone:zone] initWithState:self];
}

///--------------------------------------
#pragma mark - Mutating
///--------------------------------------

- (PFACLState *)copyByMutatingWithBlock:(PFACLStateMutationBlock)mutationsBlock {
    return [[PFACLState alloc] initWithState:self mutatingBlock:mutationsBlock];
}

@end
