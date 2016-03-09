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

@interface PFQueryState : PFBaseState <PFBaseStateSubclass, NSCopying, NSMutableCopying>

@property (nonatomic, copy, readonly) NSString *parseClassName;

@property (nonatomic, copy, readonly) NSDictionary *conditions;

@property (nonatomic, copy, readonly) NSArray *sortKeys;
@property (nonatomic, copy, readonly) NSString *sortOrderString;

@property (nonatomic, copy, readonly) NSSet *includedKeys;
@property (nonatomic, copy, readonly) NSSet *selectedKeys;
@property (nonatomic, copy, readonly) NSDictionary *extraOptions;

@property (nonatomic, assign, readonly) NSInteger limit;
@property (nonatomic, assign, readonly) NSInteger skip;

///--------------------------------------
#pragma mark - Remote + Caching Options
///--------------------------------------

@property (nonatomic, assign, readonly) PFCachePolicy cachePolicy;
@property (nonatomic, assign, readonly) NSTimeInterval maxCacheAge;

@property (nonatomic, assign, readonly) BOOL trace;

///--------------------------------------
#pragma mark - Local Datastore Options
///--------------------------------------

/**
 If ignoreACLs is enabled, we don't check ACLs when querying from LDS. We also don't grab
 `PFUser currentUser` since it's unnecessary when ignoring ACLs.
 */
@property (nonatomic, assign, readonly) BOOL shouldIgnoreACLs;
/**
 This is currently unused, but is here to allow future querying across objects that are in the
 process of being deleted eventually.
 */
@property (nonatomic, assign, readonly) BOOL shouldIncludeDeletingEventually;
@property (nonatomic, assign, readonly) BOOL queriesLocalDatastore;
@property (nonatomic, copy, readonly) NSString *localDatastorePinName;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithState:(PFQueryState *)state;
+ (instancetype)stateWithState:(PFQueryState *)state;

@end
