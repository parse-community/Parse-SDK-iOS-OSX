/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTCommand.h"

#import <Parse/PFConstants.h>

PF_TV_UNAVAILABLE_WARNING
PF_WATCH_UNAVAILABLE_WARNING

@class PFPushState;

NS_ASSUME_NONNULL_BEGIN

PF_TV_UNAVAILABLE PF_WATCH_UNAVAILABLE @interface PFRESTPushCommand : PFRESTCommand

+ (instancetype)sendPushCommandWithPushState:(PFPushState *)state
                                sessionToken:(nullable NSString *)sessionToken;

@end

NS_ASSUME_NONNULL_END
