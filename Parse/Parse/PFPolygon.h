/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "PFGeoPoint.h"

NS_ASSUME_NONNULL_BEGIN

@class PFPolygon;

/**
 `PFPolygon` may be used to embed a latitude / longitude points as the value for a key in a `PFObject`.
 It could be used to perform queries in a geospatial manner using `PFQuery.-whereKey:polygonContains:`.
 */
@interface PFPolygon : NSObject <NSCopying, NSCoding>

///--------------------------------------
#pragma mark - Creating a Polygon
///--------------------------------------

/**
 Creates a new `PFPolygon` object for the given `CLLocation`, set to the location's coordinates.

 @param coordinates Array of `CLLocation`, `PFGeoPoint` or `(lat,lng)`
 @return Returns a new PFPolygon at specified location.
 */
+ (instancetype)polygonWithCoordinates:(NSArray *)coordinates;

/**
 Test if this polygon contains a point
 
 @param point `PFGeoPoint` to test
 @return Returns a boolean.
 */
- (BOOL)containsPoint:(PFGeoPoint *)point;

///--------------------------------------
#pragma mark - Controlling Position
///--------------------------------------

/**
 Array of `PFGeoPoints` or CLLocations
 */
@property (nonatomic, strong) NSArray* coordinates;

@end

NS_ASSUME_NONNULL_END
