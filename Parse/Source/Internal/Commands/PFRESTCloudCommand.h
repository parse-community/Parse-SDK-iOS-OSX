/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFRESTCloudCommand : PFRESTCommand

+ (instancetype)commandForFunction:(NSString *)function
                    withParameters:(nullable NSDictionary *)parameters
                      sessionToken:(nullable NSString *)sessionToken
                             error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
