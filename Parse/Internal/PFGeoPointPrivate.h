/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

# import <Parse/PFGeoPoint.h>

extern const double EARTH_RADIUS_MILES;
extern const double EARTH_RADIUS_KILOMETERS;

@class PFGeoPoint;

@interface PFGeoPoint (Private)

// Internal commands

/*
 Gets the encoded format for an GeoPoint.
 */
- (NSDictionary *)encodeIntoDictionary;

/**
 Creates an GeoPoint from its encoded format.
 */
+ (instancetype)geoPointWithDictionary:(NSDictionary *)dictionary;

@end
