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

NS_ASSUME_NONNULL_BEGIN

@class BFTask<__covariant BFGenericType>;
@class PFObject;

typedef NS_ENUM(NSUInteger, PFCurrentObjectStorageType) {
    PFCurrentObjectStorageTypeFile = 1,
    PFCurrentObjectStorageTypeOfflineStore,
};

@protocol PFCurrentObjectControlling <NSObject>

@property (nonatomic, assign, readonly) PFCurrentObjectStorageType storageType;

///--------------------------------------
#pragma mark - Current
///--------------------------------------

- (BFTask *)getCurrentObjectAsync;
- (BFTask *)saveCurrentObjectAsync:(PFObject *)object;

@end

NS_ASSUME_NONNULL_END
