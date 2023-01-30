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

extern NSUInteger const PFRESTObjectBatchCommandSubcommandsLimit;

NS_ASSUME_NONNULL_BEGIN

@interface PFRESTObjectBatchCommand : PFRESTCommand

+ (instancetype)batchCommandWithCommands:(NSArray<PFRESTCommand *> *)commands
                            sessionToken:(nullable NSString *)sessionToken
                               serverURL:(NSURL *)serverURL
                                   error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
