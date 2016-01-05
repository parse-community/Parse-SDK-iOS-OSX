/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestCase.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFUnitTestCase : PFTestCase

@property (nonatomic, copy, readonly) NSString *applicationId;
@property (nonatomic, copy, readonly) NSString *clientKey;

///--------------------------------------
#pragma mark - XCTestCase
///--------------------------------------

- (void)setUp NS_REQUIRES_SUPER;
- (void)tearDown NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
