/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

#import "PFBaseState.h"

@class PFQueryState;

NS_ASSUME_NONNULL_BEGIN

PF_WATCH_UNAVAILABLE @interface PFPushState : PFBaseState <NSCopying, NSMutableCopying>

@property (nullable, nonatomic, copy, readonly) NSSet *channels;
@property (nullable, nonatomic, copy, readonly) PFQueryState *queryState;

@property (nullable, nonatomic, strong, readonly) NSDate *expirationDate;
@property (nullable, nonatomic, copy, readonly) NSNumber *expirationTimeInterval;

@property (nullable, nonatomic, copy, readonly) NSDictionary *payload;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)initWithState:(nullable PFPushState *)state;
+ (instancetype)stateWithState:(nullable PFPushState *)state;

@end

NS_ASSUME_NONNULL_END
