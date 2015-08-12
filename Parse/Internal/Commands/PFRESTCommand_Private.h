/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTCommand.h"

@interface PFRESTCommand ()

@property (nonatomic, copy, readwrite) NSString *sessionToken;

@property (nonatomic, copy, readwrite) NSString *httpPath;
@property (nonatomic, copy, readwrite) NSString *httpMethod;

@property (nonatomic, copy, readwrite) NSDictionary *parameters;

@property (nonatomic, copy, readwrite) NSString *cacheKey;

@property (nonatomic, copy, readwrite) NSString *operationSetUUID;

@end
