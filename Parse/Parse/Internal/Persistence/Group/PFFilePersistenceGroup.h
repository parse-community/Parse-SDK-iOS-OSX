/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFPersistenceGroup.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, PFFilePersistenceGroupOptions) {
    PFFilePersistenceGroupOptionUseFileLocks = 1 << 0,
};

@interface PFFilePersistenceGroup : NSObject <PFPersistenceGroup>

@property (nonatomic, copy, readonly) NSString *storageDirectoryPath;
@property (nonatomic, assign, readonly) PFFilePersistenceGroupOptions options;

- (instancetype)initWithStorageDirectoryPath:(NSString *)path
                                     options:(PFFilePersistenceGroupOptions)options;

@end

NS_ASSUME_NONNULL_END
