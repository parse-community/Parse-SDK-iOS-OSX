/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import ParseCore;

NS_ASSUME_NONNULL_BEGIN

@interface Room : PFObject <PFSubclassing>

@property (nullable, nonatomic, strong) NSString *name;

@end

NS_ASSUME_NONNULL_END
