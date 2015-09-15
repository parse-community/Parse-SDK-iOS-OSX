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
#import "PFObjectControlling.h"


@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFObject;

NS_ASSUME_NONNULL_BEGIN

@interface PFObjectController : NSObject <PFObjectControlling>

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider> dataSource;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider>)dataSource NS_DESIGNATED_INITIALIZER;
+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider>)dataSource;

@end

NS_ASSUME_NONNULL_END
