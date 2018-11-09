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
#import <Parse/PFFileObject.h>

#import "PFFileState.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFFileObject (Private)

@property (nonatomic, strong, readonly) PFFileState *state;

+ (instancetype)fileObjectWithName:(nullable NSString *)name url:(nullable NSString *)url;

- (nullable NSString *)_cachedFilePath;

@end

NS_ASSUME_NONNULL_END
