/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTCommand.h"

#import "PFConstants.h"

PF_WATCH_UNAVAILABLE_WARNING

@class PFPushState;

NS_ASSUME_NONNULL_BEGIN

PF_WATCH_UNAVAILABLE @interface PFRESTPushCommand : PFRESTCommand

+ (nullable instancetype)sendPushCommandWithPushState:(PFPushState *)state
                                        sessionToken:(nullable NSString *)sessionToken
                                               error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
