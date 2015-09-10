/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFBaseState.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFFileState : PFBaseState <PFBaseStateSubclass, NSCopying, NSMutableCopying>

@property (nonatomic, copy, readonly) NSString *name;
@property (nullable, nonatomic, copy, readonly) NSString *urlString;
@property (nullable, nonatomic, copy, readonly) NSString *secureURLString;

@property (nullable, nonatomic, copy, readonly) NSString *mimeType;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)initWithState:(PFFileState *)state;
- (instancetype)initWithName:(nullable NSString *)name
                   urlString:(nullable NSString *)urlString
                    mimeType:(nullable NSString *)mimeType;

@end

NS_ASSUME_NONNULL_END
