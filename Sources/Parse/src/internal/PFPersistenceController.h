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

@class BFTask<__covariant BFGenericType>;

NS_ASSUME_NONNULL_BEGIN

///--------------------------------------
#pragma mark - Controller
///--------------------------------------

typedef BFTask<NSNumber *> *_Nonnull (^PFPersistenceGroupValidationHandler)(id<PFPersistenceGroup> group);

@interface PFPersistenceController : NSObject

@property (nonatomic, copy, readonly) NSString *applicationIdentifier;
@property (nullable, nonatomic, copy, readonly) NSString *applicationGroupIdentifier;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithApplicationIdentifier:(NSString *)applicationIdentifier
                   applicationGroupIdentifier:(nullable NSString *)applicationGroupIdentifier
                       groupValidationHandler:(PFPersistenceGroupValidationHandler)handler NS_DESIGNATED_INITIALIZER;

///--------------------------------------
#pragma mark - Data Persistence
///--------------------------------------

- (BFTask<id<PFPersistenceGroup>> *)getPersistenceGroupAsync;

@end

NS_ASSUME_NONNULL_END
