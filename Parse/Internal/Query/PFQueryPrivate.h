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

extern NSString *const PFQueryKeyNotEqualTo;
extern NSString *const PFQueryKeyLessThan;
extern NSString *const PFQueryKeyLessThanEqualTo;
extern NSString *const PFQueryKeyGreaterThan;
extern NSString *const PFQueryKeyGreaterThanOrEqualTo;
extern NSString *const PFQueryKeyContainedIn;
extern NSString *const PFQueryKeyNotContainedIn;
extern NSString *const PFQueryKeyContainsAll;
extern NSString *const PFQueryKeyNearSphere;
extern NSString *const PFQueryKeyWithin;
extern NSString *const PFQueryKeyRegex;
extern NSString *const PFQueryKeyExists;
extern NSString *const PFQueryKeyInQuery;
extern NSString *const PFQueryKeyNotInQuery;
extern NSString *const PFQueryKeySelect;
extern NSString *const PFQueryKeyDontSelect;
extern NSString *const PFQueryKeyRelatedTo;
extern NSString *const PFQueryKeyOr;
extern NSString *const PFQueryKeyQuery;
extern NSString *const PFQueryKeyKey;
extern NSString *const PFQueryKeyObject;

extern NSString *const PFQueryOptionKeyMaxDistance;
extern NSString *const PFQueryOptionKeyBox;
extern NSString *const PFQueryOptionKeyRegexOptions;

@class BFTask<__covariant BFGenericType>;
@class PFObject;

@interface PFQuery (Private)

@property (nonatomic, strong, readonly) PFQueryState *state;

- (instancetype)whereRelatedToObject:(PFObject *)parent fromKey:(NSString *)key;
- (void)redirectClassNameForKey:(NSString *)key;

@end
