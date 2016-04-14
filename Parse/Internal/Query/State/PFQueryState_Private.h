/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFQueryState.h"

#import "PFMacros.h"

/**
 Returns NSString representation of a property on PFQueryState.

 @param NAME The name of the property.

 @return NSString representaiton of a given property.
 */
#define PFQueryStatePropertyName(NAME) @keypath(PFQueryState, NAME)

@interface PFQueryState () {
@protected
    NSString *_parseClassName;

    NSDictionary<NSString *, id> *_conditions;

    NSArray<NSString *> *_sortKeys;

    NSSet<NSString *> *_includedKeys;
    NSSet<NSString *> *_selectedKeys;
    NSDictionary<NSString *, NSString *> *_extraOptions;

    NSInteger _limit;
    NSInteger _skip;

    PFCachePolicy _cachePolicy;
    NSTimeInterval _maxCacheAge;

    BOOL _trace;

    BOOL _shouldIgnoreACLs;
    BOOL _shouldIncludeDeletingEventually;
    BOOL _queriesLocalDatastore;
    NSString *_localDatastorePinName;
}

@property (nonatomic, copy, readwrite) NSString *parseClassName;

@property (nonatomic, assign, readwrite) NSInteger limit;
@property (nonatomic, assign, readwrite) NSInteger skip;

///--------------------------------------
#pragma mark - Remote + Caching Options
///--------------------------------------

@property (nonatomic, assign, readwrite) PFCachePolicy cachePolicy;
@property (nonatomic, assign, readwrite) NSTimeInterval maxCacheAge;

@property (nonatomic, assign, readwrite) BOOL trace;

///--------------------------------------
#pragma mark - Local Datastore Options
///--------------------------------------

@property (nonatomic, assign, readwrite) BOOL shouldIgnoreACLs;
@property (nonatomic, assign, readwrite) BOOL shouldIncludeDeletingEventually;
@property (nonatomic, assign, readwrite) BOOL queriesLocalDatastore;
@property (nonatomic, copy, readwrite) NSString *localDatastorePinName;

@end
