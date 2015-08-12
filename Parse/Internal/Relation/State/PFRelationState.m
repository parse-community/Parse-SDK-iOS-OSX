/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRelationState.h"
#import "PFRelationState_Private.h"

#import "PFMutableRelationState.h"

@implementation PFRelationState

///--------------------------------------
#pragma mark - PFBaseStateSubclass
///--------------------------------------

+ (NSDictionary *)propertyAttributes {
    return @{
        @"parent": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeWeak],
        @"parentClassName": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"parentObjectId": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"targetClass": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"knownObjects": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"key": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
    };
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _knownObjects = [[NSSet alloc] init];

    return self;
}

- (instancetype)initWithState:(PFRelationState *)otherState {
    return [super initWithState:otherState];
}

+ (instancetype)stateWithState:(PFRelationState *)otherState {
    return [super stateWithState:otherState];
}

///--------------------------------------
#pragma mark - Copying
///--------------------------------------

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[PFRelationState allocWithZone:zone] initWithState:self];
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    return [[PFMutableRelationState allocWithZone:zone] initWithState:self];
}

@end
