/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFQueryState.h"

@interface PFMutableQueryState : PFQueryState <NSCopying>

@property (nonatomic, copy, readwrite) NSString *parseClassName;

@property (nonatomic, assign, readwrite) NSInteger limit;
@property (nonatomic, assign, readwrite) NSInteger skip;

///--------------------------------------
/// @name Remote + Caching Options
///--------------------------------------

@property (nonatomic, assign, readwrite) PFCachePolicy cachePolicy;
@property (nonatomic, assign, readwrite) NSTimeInterval maxCacheAge;

@property (nonatomic, assign, readwrite) BOOL trace;

///--------------------------------------
/// @name Local Datastore Options
///--------------------------------------

@property (nonatomic, assign, readwrite) BOOL shouldIgnoreACLs;
@property (nonatomic, assign, readwrite) BOOL shouldIncludeDeletingEventually;
@property (nonatomic, assign, readwrite) BOOL queriesLocalDatastore;
@property (nonatomic, copy, readwrite) NSString *localDatastorePinName;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)initWithParseClassName:(NSString *)className;
+ (instancetype)stateWithParseClassName:(NSString *)className;

///--------------------------------------
/// @name Conditions
///--------------------------------------

- (void)setConditionType:(NSString *)type withObject:(id)object forKey:(NSString *)key;

- (void)setEqualityConditionWithObject:(id)object forKey:(NSString *)key;
- (void)setRelationConditionWithObject:(id)object forKey:(NSString *)key;

- (void)removeAllConditions;

///--------------------------------------
/// @name Sort
///--------------------------------------

- (void)sortByKey:(NSString *)key ascending:(BOOL)ascending;
- (void)addSortKey:(NSString *)key ascending:(BOOL)ascending;
- (void)addSortKeysFromSortDescriptors:(NSArray *)sortDescriptors;

///--------------------------------------
/// @name Includes
///--------------------------------------

- (void)includeKey:(NSString *)key;

///--------------------------------------
/// @name Selected Keys
///--------------------------------------

- (void)selectKeys:(NSArray *)keys;

///--------------------------------------
/// @name Redirect
///--------------------------------------

- (void)redirectClassNameForKey:(NSString *)key;

@end
