/**
 * Copyright (c) 2016-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import Parse;

NS_ASSUME_NONNULL_BEGIN

@interface Message : PFObject <PFSubclassing>

@property (nullable, nonatomic, strong) PFUser *author;
@property (nullable, nonatomic, strong) NSString *authorName;
@property (nullable, nonatomic, strong) NSString *message;
@property (nullable, nonatomic, strong) PFObject *room;
@property (nullable, nonatomic, strong) NSString *roomName;

@end

NS_ASSUME_NONNULL_END
