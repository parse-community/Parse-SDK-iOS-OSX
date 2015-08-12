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

@class PFObjectState;

@interface PFRESTObjectCommand : PFRESTCommand

+ (instancetype)fetchObjectCommandForObjectState:(PFObjectState *)state
                                withSessionToken:(nullable NSString *)sessionToken;

+ (instancetype)createObjectCommandForObjectState:(PFObjectState *)state
                                          changes:(nullable NSDictionary *)changes
                                 operationSetUUID:(nullable NSString *)operationSetIdentifier
                                     sessionToken:(nullable NSString *)sessionToken;

+ (instancetype)updateObjectCommandForObjectState:(PFObjectState *)state
                                          changes:(nullable NSDictionary *)changes
                                 operationSetUUID:(nullable NSString *)operationSetIdentifier
                                     sessionToken:(nullable NSString *)sessionToken;

+ (instancetype)deleteObjectCommandForObjectState:(PFObjectState *)state
                                 withSessionToken:(nullable NSString *)sessionToken;

@end

NS_ASSUME_NONNULL_END
