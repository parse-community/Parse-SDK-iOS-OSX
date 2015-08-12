/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFileState.h"
#import "PFFileState_Private.h"

#import "PFMutableFileState.h"
#import "PFPropertyInfo.h"

@implementation PFFileState

///--------------------------------------
#pragma mark - PFBaseStateSubclass
///--------------------------------------

+ (NSDictionary *)propertyAttributes {
    return @{
        @"name" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"urlString" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
        @"mimeType" : [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
    };
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithState:(PFFileState *)state {
    return [super initWithState:state];
}

- (instancetype)initWithName:(NSString *)name urlString:(NSString *)urlString mimeType:(NSString *)mimeType {
    self = [super init];
    if (!self) return nil;

    _name = (name ? [name copy] : @"file");
    _urlString = [urlString copy];
    _mimeType = [mimeType copy];

    return self;
}

///--------------------------------------
#pragma mark - Mutable Copying
///--------------------------------------

- (id)copyWithZone:(NSZone *)zone {
    return [[PFFileState allocWithZone:zone] initWithState:self];
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    return [[PFMutableFileState allocWithZone:zone] initWithState:self];
}

@end
