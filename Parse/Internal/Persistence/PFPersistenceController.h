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

#import "PFPersistenceGroup.h"

@class BFTask PF_GENERIC(id);

NS_ASSUME_NONNULL_BEGIN

///--------------------------------------
/// @name Controller
///--------------------------------------

typedef BFTask PF_GENERIC(NSNumber *)* __nonnull (^PFPersistenceGroupValidationHandler)(id<PFPersistenceGroup> group);

@interface PFPersistenceController : NSObject

@property (nonatomic, copy, readonly) NSString *applicationIdentifier;
@property (nullable, nonatomic, copy, readonly) NSString *applicationGroupIdentifier;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithApplicationIdentifier:(NSString *)applicationIdentifier
                   applicationGroupIdentifier:(nullable NSString *)applicationGroupIdentifier
                       groupValidationHandler:(PFPersistenceGroupValidationHandler)handler NS_DESIGNATED_INITIALIZER;

///--------------------------------------
/// @name Data Persistence
///--------------------------------------

- (BFTask PF_GENERIC(id<PFPersistenceGroup>)*)getPersistenceGroupAsync;

@end

NS_ASSUME_NONNULL_END
