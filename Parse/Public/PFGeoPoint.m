/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFGeoPoint.h"
#import "PFGeoPointPrivate.h"

#import <math.h>

#import "PFAssert.h"
#import "PFCoreManager.h"
#import "PFHash.h"
#import "PFLocationManager.h"
#import "Parse_Private.h"

const double EARTH_RADIUS_MILES = 3958.8;
const double EARTH_RADIUS_KILOMETERS = 6371.0;

@implementation PFGeoPoint

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)geoPoint {
    return [[self alloc] init];
}

+ (instancetype)geoPointWithLocation:(CLLocation *)location {
    return [self geoPointWithLatitude:location.coordinate.latitude
                            longitude:location.coordinate.longitude];
}

+ (instancetype)geoPointWithLatitude:(double)latitude longitude:(double)longitude {
    PFGeoPoint *gpt = [self geoPoint];
    gpt.latitude = latitude;
    gpt.longitude = longitude;
    return gpt;
}

+ (void)geoPointForCurrentLocationInBackground:(PFGeoPointResultBlock)resultBlock {
    if (!resultBlock) {
        return;
    }

    void (^locationHandler)(CLLocation *, NSError *) = ^(CLLocation *location, NSError *error) {
        PFGeoPoint *newGeoPoint = [PFGeoPoint geoPointWithLocation:location];
        resultBlock(newGeoPoint, error);
    };
    [[Parse _currentManager].coreManager.locationManager addBlockForCurrentLocation:locationHandler];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setLatitude:(double)latitude {
    PFParameterAssert(latitude >= -90.0 && latitude <= 90.0,
                      @"`latitude` is out of range [-90.0, 90.0]: %f", latitude);
    _latitude = latitude;
}

- (void)setLongitude:(double)longitude {
    PFParameterAssert(longitude >= -180.0 && longitude <= 180.0,
                      @"`longitude` is out of range [-180.0, 180.0]: %f", longitude);
    _longitude = longitude;
}

- (double)distanceInRadiansTo:(PFGeoPoint *)point {
    double d2r = M_PI / 180.0; // radian conversion factor
    double lat1rad = self.latitude * d2r;
    double long1rad = self.longitude * d2r;
    double lat2rad = point.latitude * d2r;
    double long2rad = point.longitude * d2r;
    double deltaLat = lat1rad - lat2rad;
    double deltaLong = long1rad - long2rad;
    double sinDeltaLatDiv2 = sin(deltaLat / 2.);
    double sinDeltaLongDiv2 = sin(deltaLong / 2.);
    // Square of half the straight line chord distance between both points. [0.0, 1.0]
    double a = sinDeltaLatDiv2 * sinDeltaLatDiv2 + cos(lat1rad) * cos(lat2rad) * sinDeltaLongDiv2 * sinDeltaLongDiv2;
    a = fmin(1.0, a);
    return 2. * asin(sqrt(a));
}

- (double)distanceInMilesTo:(PFGeoPoint *)point {
    return [self distanceInRadiansTo:point] * EARTH_RADIUS_MILES;
}

- (double)distanceInKilometersTo:(PFGeoPoint *)point {
    return [self distanceInRadiansTo:point] * EARTH_RADIUS_KILOMETERS;
}

///--------------------------------------
#pragma mark - Encoding
///--------------------------------------

static NSString *const PFGeoPointCodingTypeKey = @"__type";
static NSString *const PFGeoPointCodingLatitudeKey = @"latitude";
static NSString *const PFGeoPointCodingLongitudeKey = @"longitude";

- (NSDictionary *)encodeIntoDictionary:(NSError **)error {
    return @{
             PFGeoPointCodingTypeKey : @"GeoPoint",
             PFGeoPointCodingLatitudeKey : @(self.latitude),
             PFGeoPointCodingLongitudeKey : @(self.longitude)
             };
}

+ (instancetype)geoPointWithDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithEncodedDictionary:dictionary];
}

- (instancetype)initWithEncodedDictionary:(NSDictionary *)dictionary {
    self = [self init];
    if (!self) return nil;

    id latObj = dictionary[PFGeoPointCodingLatitudeKey];
    PFParameterAssert([latObj isKindOfClass:[NSNumber class]], @"Invalid latitude type passed: %@", latObj);

    id longObj = dictionary[PFGeoPointCodingLongitudeKey];
    PFParameterAssert([longObj isKindOfClass:[NSNumber class]], @"Invalid longitude type passed: %@", longObj);

    _latitude = [latObj doubleValue];
    _longitude = [longObj doubleValue];

    return self;
}

///--------------------------------------
#pragma mark - NSObject
///--------------------------------------

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[PFGeoPoint class]]) {
        return NO;
    }

    PFGeoPoint *geoPoint = object;

    return (self.latitude == geoPoint.latitude &&
            self.longitude == geoPoint.longitude);
}

- (NSUInteger)hash {
    return PFDoublePairHash(self.latitude, self.longitude);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, latitude: %f, longitude: %f>",
            [self class],
            self,
            self.latitude,
            self.longitude];
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (instancetype)copyWithZone:(NSZone *)zone {
    PFGeoPoint *geoPoint = [[self class] geoPointWithLatitude:self.latitude longitude:self.longitude];
    return geoPoint;
}

///--------------------------------------
#pragma mark - NSCoding
///--------------------------------------

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[PFGeoPointCodingTypeKey] = [coder decodeObjectForKey:PFGeoPointCodingTypeKey];
    dictionary[PFGeoPointCodingLatitudeKey] = [coder decodeObjectForKey:PFGeoPointCodingLatitudeKey];
    dictionary[PFGeoPointCodingLongitudeKey] = [coder decodeObjectForKey:PFGeoPointCodingLongitudeKey];
    return [self initWithEncodedDictionary:dictionary];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    NSDictionary *dictionary = [self encodeIntoDictionary:nil];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [coder encodeObject:obj forKey:key];
    }];
}

@end
