/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFQueryConstants.h"

NSString *const PFQueryKeyNotEqualTo = @"$ne";
NSString *const PFQueryKeyLessThan = @"$lt";
NSString *const PFQueryKeyLessThanEqualTo = @"$lte";
NSString *const PFQueryKeyGreaterThan = @"$gt";
NSString *const PFQueryKeyGreaterThanOrEqualTo = @"$gte";
NSString *const PFQueryKeyContainedIn = @"$in";
NSString *const PFQueryKeyNotContainedIn = @"$nin";
NSString *const PFQueryKeyContainsAll = @"$all";
NSString *const PFQueryKeyNearSphere = @"$nearSphere";
NSString *const PFQueryKeyWithin = @"$within";
NSString *const PFQueryKeyGeoWithin = @"$geoWithin";
NSString *const PFQueryKeyGeoIntersects = @"$geoIntersects";
NSString *const PFQueryKeyRegex = @"$regex";
NSString *const PFQueryKeyExists = @"$exists";
NSString *const PFQueryKeyInQuery = @"$inQuery";
NSString *const PFQueryKeyNotInQuery = @"$notInQuery";
NSString *const PFQueryKeySelect = @"$select";
NSString *const PFQueryKeyDontSelect = @"$dontSelect";
NSString *const PFQueryKeyRelatedTo = @"$relatedTo";
NSString *const PFQueryKeyOr = @"$or";
NSString *const PFQueryKeyQuery = @"query";
NSString *const PFQueryKeyKey = @"key";
NSString *const PFQueryKeyObject = @"object";

NSString *const PFQueryOptionKeyMaxDistance = @"$maxDistance";
NSString *const PFQueryOptionKeyBox = @"$box";
NSString *const PFQueryOptionKeyPolygon = @"$polygon";
NSString *const PFQueryOptionKeyPoint = @"$point";
NSString *const PFQueryOptionKeyRegexOptions = @"$options";
