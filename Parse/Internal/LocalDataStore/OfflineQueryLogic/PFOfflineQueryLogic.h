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

#import "PFMacros.h"

@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFObject;
@class PFOfflineStore;
@class PFQueryState;
@class PFSQLiteDatabase;
@class PFUser;

typedef BFTask PF_GENERIC(NSNumber *)* (^PFConstraintMatcherBlock)(PFObject *object, PFSQLiteDatabase *database);

typedef NS_OPTIONS(uint8_t, PFOfflineQueryOption) {
    PFOfflineQueryOptionOrder = 1 << 0,
    PFOfflineQueryOptionLimit = 1 << 1,
    PFOfflineQueryOptionSkip = 1 << 2,
};

@interface PFOfflineQueryLogic : NSObject

/*!
 Initialize an `PFOfflineQueryLogic` instance with `PFOfflineStore` instance.
 `PFOfflineStore` is needed for subQuery, inQuery and fetch.
 */
- (instancetype)initWithOfflineStore:(PFOfflineStore *)offlineStore;

/*!
 @returns YES iff the object is visible based on its read ACL and the given user objectId.
 */
+ (BOOL)userHasReadAccess:(PFUser *)user ofObject:(PFObject *)object;

/*!
 @returns YES iff the object is visible based on its read ACL and the given user objectId.
 */
+ (BOOL)userHasWriteAccess:(PFUser *)user ofObject:(PFObject *)object;

/*!
 Returns a PFConstraintMatcherBlock that returns true iff the object matches the given
 query's constraints. This takes in a PFSQLiteDatabase connection because SQLite is finicky
 about nesting connections, so we want to reuse them whenever possible.
 */
- (PFConstraintMatcherBlock)createMatcherForQueryState:(PFQueryState *)queryState user:(PFUser *)user;

/*!
 Sort given array with given `PFQuery` constraint.

 @returns sorted result.
 */
- (NSArray *)resultsByApplyingOptions:(PFOfflineQueryOption)options
                         ofQueryState:(PFQueryState *)queryState
                            toResults:(NSArray *)results;

/*!
 Make sure all of the objects included by the given query get fetched.
 */
- (BFTask *)fetchIncludesAsyncForResults:(NSArray *)results
                            ofQueryState:(PFQueryState *)queryState
                              inDatabase:(PFSQLiteDatabase *)database;

/*!
 Make sure all of the objects included by the given query get fetched.
 */
- (BFTask *)fetchIncludesForObjectAsync:(PFObject *)object
                             queryState:(PFQueryState *)queryState
                               database:(PFSQLiteDatabase *)database;

@end
