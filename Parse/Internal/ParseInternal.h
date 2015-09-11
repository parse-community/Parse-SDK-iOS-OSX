/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

# import <Parse/Parse.h>

#import "PFAssert.h"
#import "PFCommandCache.h"
#import "PFEventuallyQueue.h"
#import "PFFieldOperation.h"
#import "PFGeoPointPrivate.h"
#import "PFInternalUtils.h"
#import "PFKeyValueCache.h"
#import "PFObjectPrivate.h"
#import "PFUserPrivate.h"
#import "ParseModule.h"

@interface Parse (ParseModules)

+ (void)enableParseModule:(id<ParseModule>)module;
+ (void)disableParseModule:(id<ParseModule>)module;
+ (BOOL)isModuleEnabled:(id<ParseModule>)module;

@end
