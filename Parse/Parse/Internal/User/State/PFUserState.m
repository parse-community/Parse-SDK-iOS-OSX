/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAssert.h"
#import "PFUserState.h"
#import "PFUserState_Private.h"

#import "PFMutableUserState.h"
#import "PFObjectState_Private.h"
#import "PFUserConstants.h"

@implementation PFUserState

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithState:(PFUserState *)state {
    self = [super initWithState:state];
    if (!self) return nil;

    _sessionToken = [state.sessionToken copy];
    _authData = [state.authData copy];
    _isNew = state.isNew;

    return self;
}

- (instancetype)initWithState:(PFUserState *)state mutatingBlock:(PFUserStateMutationBlock)block {
    self = [self initWithState:state];
    if (!self) return nil;

    block((PFMutableUserState *)self);

    return self;
}

+ (instancetype)stateWithState:(PFUserState *)state {
    return [super stateWithState:state];
}

///--------------------------------------
#pragma mark - Serialization
///--------------------------------------

- (nullable NSDictionary *)dictionaryRepresentationWithObjectEncoder:(PFEncoder *)objectEncoder error:(NSError **)error {
    NSDictionary *representation = [super dictionaryRepresentationWithObjectEncoder:objectEncoder error:error];
    PFPreconditionBailOnError(representation, error, nil);
    NSMutableDictionary *dictionary = [representation mutableCopy];
    [dictionary removeObjectForKey:PFUserPasswordRESTKey];
    return dictionary;
}

///--------------------------------------
#pragma mark - Mutating
///--------------------------------------

- (PFUserState *)copyByMutatingWithBlock:(PFUserStateMutationBlock)block {
    return [[PFUserState alloc] initWithState:self mutatingBlock:block];
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (id)copyWithZone:(NSZone *)zone {
    return [[PFUserState allocWithZone:zone] initWithState:self];
}

///--------------------------------------
#pragma mark - NSMutableCopying
///--------------------------------------

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [[PFMutableUserState allocWithZone:zone] initWithState:self];
}

@end
