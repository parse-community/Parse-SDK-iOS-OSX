/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFDataProvider.h"

/**
 A disk-based map of local ids to global Parse objectIds. Every entry in this
 map has a retain count, and the entry will be removed from the map if the
 retain count reaches 0. Every time a localId is written out to disk, its retain
 count should be incremented. When the reference on disk is deleted, it should
 be decremented. Some entries in this map may not have an object id yet.
 This class is thread-safe.
 */
@interface PFObjectLocalIdStore : NSObject

@property (nonatomic, weak, readonly) id<PFFileManagerProvider> dataSource;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithDataSource:(id<PFFileManagerProvider>)dataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)storeWithDataSource:(id<PFFileManagerProvider>)dataSource;

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (NSString *)createLocalId;
- (void)retainLocalIdOnDisk:(NSString *)localId;
- (void)releaseLocalIdOnDisk:(NSString *)localId;

- (void)setObjectId:(NSString *)objectId forLocalId:(NSString *)localId;
- (NSString *)objectIdForLocalId:(NSString *)localId;

// For testing only.
- (BOOL)clear;
- (void)clearInMemoryCache;

@end
