/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMutableRelationState.h"

#import "PFObject.h"
#import "PFRelationState_Private.h"

@implementation PFMutableRelationState

@dynamic parent;
@dynamic parentObjectId;
@dynamic parentClassName;
@dynamic targetClass;
@dynamic knownObjects;
@dynamic key;

///--------------------------------------
#pragma mark - PFBaseStateSubclass
///--------------------------------------

+ (NSDictionary *)propertyAttributes {
    NSMutableDictionary *parentAttributes = [[super propertyAttributes] mutableCopy];

    parentAttributes[@"knownObjects"] = [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeMutableCopy];

    return parentAttributes;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _knownObjects = [[NSMutableSet alloc] init];

    return self;
}

///--------------------------------------
#pragma mark - Properties
///--------------------------------------

- (void)setParent:(PFObject *)parent {
    if (_parent != parent || ![self.parentClassName isEqualToString:parent.parseClassName] ||
        ![self.parentObjectId isEqualToString:parent.objectId]) {
        _parent = parent;
        _parentClassName = [[parent parseClassName] copy];
        _parentObjectId = [[parent objectId] copy];
    }
}

@end
