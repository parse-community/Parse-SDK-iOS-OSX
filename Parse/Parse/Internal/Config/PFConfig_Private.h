/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <PFConfig.h>

extern NSString *const PFConfigParametersRESTKey;

@interface PFConfig (Private)

@property (atomic, copy, readonly) NSDictionary *parametersDictionary;

- (instancetype)initWithFetchedConfig:(NSDictionary *)config;

@end
