/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPushState.h"
#import "PFPushState_Private.h"

#import "PFMutablePushState.h"
#import "PFQueryState.h"
#import "PFAssert.h"

@implementation PFPushState

///--------------------------------------
#pragma mark - PFBaseStateSubclass
///--------------------------------------

+ (NSDictionary *)propertyAttributes {
    return @{ @"channels": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
              @"queryState": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy],
              @"expirationDate": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeStrong],
              @"expirationTimeInterval": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeStrong],
              @"pushDate": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeStrong],
              @"payload": [PFPropertyAttributes attributesWithAssociationType:PFPropertyInfoAssociationTypeCopy] };
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithState:(PFPushState *)state {
    return [super initWithState:state];
}

+ (instancetype)stateWithState:(PFPushState *)state {
    return [super stateWithState:state];
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (void)setPushDate:(NSDate *)pushDate {
    if (self.pushDate != pushDate) {
        NSTimeInterval interval = pushDate.timeIntervalSinceNow;
        PFParameterAssert(interval > 0, @"Can't set the scheduled push time in the past.");
        PFParameterAssert(interval <= 60 * 60 * 24 * 14, @"Can't set the schedule push time more than two weeks from now.");
        _pushDate = pushDate;
    }
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (id)copyWithZone:(NSZone *)zone {
    return [[PFPushState allocWithZone:zone] initWithState:self];
}

///--------------------------------------
#pragma mark - NSMutableCopying
///--------------------------------------

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [[PFMutablePushState allocWithZone:zone] initWithState:self];
}

@end
