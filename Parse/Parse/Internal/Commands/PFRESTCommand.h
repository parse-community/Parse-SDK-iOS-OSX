/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFNetworkCommand.h"

NS_ASSUME_NONNULL_BEGIN

@interface PFRESTCommand : NSObject <PFNetworkCommand>

@property (nonatomic, copy, readonly) NSString *httpPath;
@property (nonatomic, copy, readonly) NSString *httpMethod;

@property (nullable, nonatomic, copy, readonly) NSDictionary *parameters;
@property (nullable, nonatomic, copy) NSDictionary *additionalRequestHeaders;

@property (nonatomic, copy, readonly) NSString *cacheKey;

@property (nullable, nonatomic, copy) NSString *localId;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)commandWithHTTPPath:(NSString *)path
                         httpMethod:(NSString *)httpMethod
                         parameters:(nullable NSDictionary *)parameters
                       sessionToken:(nullable NSString *)sessionToken
                              error:(NSError **)error;

+ (instancetype)commandWithHTTPPath:(NSString *)path
                         httpMethod:(NSString *)httpMethod
                         parameters:(nullable NSDictionary *)parameters
                   operationSetUUID:(nullable NSString *)operationSetIdentifier
                       sessionToken:(nullable NSString *)sessionToken
                              error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
