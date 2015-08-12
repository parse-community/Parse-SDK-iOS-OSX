/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFQueryState.h"
#import "PFQueryState_Private.h"

#import "PFMutableQueryState.h"
#import "PFPropertyInfo.h"

@implementation PFQueryState

///--------------------------------------
#pragma mark - PFBaseStateSubclass
///--------------------------------------

+ (NSDictionary *)propertyAttributes {
    return @{
        @"parseClassName": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"conditions": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"sortKeys": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"includedKeys": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"selectedKeys": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"extraOptions": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],

        @"limit": [PFPropertyAttributes attributes],
        @"skip": [PFPropertyAttributes attributes],
        @"cachePolicy": [PFPropertyAttributes attributes],
        @"maxCacheAge": [PFPropertyAttributes attributes],

        @"trace": [PFPropertyAttributes attributes],
        @"shouldIgnoreACLs": [PFPropertyAttributes attributes],
        @"shouldIncludeDeletingEventually": [PFPropertyAttributes attributes],
        @"queriesLocalDatastore": [PFPropertyAttributes attributes],

        @"localDatastorePinName": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy]
    };
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _cachePolicy = kPFCachePolicyIgnoreCache;
    _maxCacheAge = INFINITY;
    _limit = -1;

    return self;
}

- (instancetype)initWithState:(PFQueryState *)state {
    return [super initWithState:state];
}

+ (instancetype)stateWithState:(PFQueryState *)state {
    return [super stateWithState:state];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (NSString *)sortOrderString {
    return [self.sortKeys componentsJoinedByString:@","];
}

///--------------------------------------
#pragma mark - Mutable Copying
///--------------------------------------

- (id)copyWithZone:(NSZone *)zone {
    return [[PFQueryState allocWithZone:zone] initWithState:self];
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    return [[PFMutableQueryState allocWithZone:zone] initWithState:self];
}

@end
