/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFQuery.h>

#import "PFQueryState.h"

@class BFTask<__covariant BFGenericType>;
@class PFObject;

@interface PFQuery (Private)

@property (nonatomic, strong, readonly) PFQueryState *state;

- (instancetype)whereRelatedToObject:(PFObject *)parent fromKey:(NSString *)key;
- (void)redirectClassNameForKey:(NSString *)key;

@end
