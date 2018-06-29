/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPolygon.h"
#import "PFPolygonPrivate.h"

#import <math.h>

#import "PFAssert.h"
#import "PFCoreManager.h"
#import "PFHash.h"
#import "PFLocationManager.h"
#import "Parse_Private.h"

@implementation PFPolygon

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)polygonWithCoordinates:(NSArray *)coordinates {
    PFPolygon *polygon = [[self alloc] init];
    polygon.coordinates = coordinates;
    return polygon;
}


///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setCoordinates:(NSArray *)coordinates {
    PFParameterAssert([coordinates isKindOfClass:[NSArray class]],
                      @"`coordinates` must be a NSArray: %@", coordinates);
   
    PFParameterAssert(coordinates.count > 3,
                      @"`Polygon` must have at least 3 GeoPoints or Points %@", coordinates);
    
    NSMutableArray* points = [[NSMutableArray alloc] init];
    PFGeoPoint *geoPoint = [PFGeoPoint geoPoint];
    
    for (int i = 0; i < coordinates.count; i += 1) {
        id coord = coordinates[i];
        if ([coord isKindOfClass:[PFGeoPoint class]]) {
            geoPoint = coord;
        } else if ([coord isKindOfClass:[NSArray class]] && ((NSArray*)coord).count == 2) {
            NSArray* arr = (NSArray*)coord;
            double latitude = [arr[0] doubleValue];
            double longitude = [arr[1] doubleValue];
            geoPoint = [PFGeoPoint geoPointWithLatitude:latitude longitude:longitude];
        } else if ([coord isKindOfClass:[CLLocation class]]) {
            geoPoint = [PFGeoPoint geoPointWithLocation:coord];
        } else {
            PFParameterAssertionFailure(@"Coordinates must be an Array of GeoPoints or Points: %@", coord);
        }
        [points addObject:@[@(geoPoint.latitude), @(geoPoint.longitude)]];
    }
                    
    _coordinates = points;
}

- (BOOL)containsPoint:(PFGeoPoint *)point {
    double minX = [_coordinates[0][0] doubleValue];
    double maxX = [_coordinates[0][0] doubleValue];
    double minY = [_coordinates[0][1] doubleValue];
    double maxY = [_coordinates[0][1] doubleValue];
    for ( int i = 1; i < _coordinates.count; i += 1) {
        NSArray *p = _coordinates[i];
        minX = fmin( [p[0] doubleValue], minX );
        maxX = fmax( [p[0] doubleValue], maxX );
        minY = fmin( [p[1] doubleValue], minY );
        maxY = fmax( [p[1] doubleValue], maxY );
    }
    
    if (point.latitude < minX || point.latitude > maxX || point.longitude < minY || point.longitude > maxY) {
        return false;
    }
    
    bool inside = false;
    for ( int i = 0, j = (int)_coordinates.count - 1 ; i < _coordinates.count; j = i++) {
        double startX = [_coordinates[i][0] doubleValue];
        double startY = [_coordinates[i][1] doubleValue];
        double endX = [_coordinates[j][0] doubleValue];
        double endY = [_coordinates[j][1] doubleValue];
        if ( ( startY > point.longitude ) != ( endY > point.longitude ) &&
            point.latitude < ( endX - startX ) * ( point.longitude - startY ) / ( endY - startY ) + startX ) {
            inside = !inside;
        }
    }
    
    return inside;
}

///--------------------------------------
#pragma mark - Encoding
///--------------------------------------

static NSString *const PFPolygonCodingTypeKey = @"__type";
static NSString *const PFPolygonCodingCoordinatesKey = @"coordinates";

- (NSDictionary *)encodeIntoDictionary:(NSError **)error {
    return @{
             PFPolygonCodingTypeKey : @"Polygon",
             PFPolygonCodingCoordinatesKey : self.coordinates
             };
}

+ (instancetype)polygonWithDictionary:(NSDictionary *)dictionary {
    return [[self alloc] initWithEncodedDictionary:dictionary];
}

- (instancetype)initWithEncodedDictionary:(NSDictionary *)dictionary {
    self = [self init];
    if (!self) return nil;

    id coordObj = dictionary[PFPolygonCodingCoordinatesKey];
    PFParameterAssert([coordObj isKindOfClass:[NSArray class]], @"Invalid coordinates type passed: %@", coordObj);

    _coordinates = coordObj;

    return self;
}

///--------------------------------------
#pragma mark - NSObject
///--------------------------------------

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[PFPolygon class]]) {
        return NO;
    }

    PFPolygon *polygon = object;

    return ([_coordinates isEqualToArray:polygon.coordinates]);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, coordinates: %@>",
            [self class],
            self,
            _coordinates];
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (instancetype)copyWithZone:(NSZone *)zone {
    PFPolygon *polygon = [[self class] polygonWithCoordinates:self.coordinates];
    return polygon;
}

///--------------------------------------
#pragma mark - NSCoding
///--------------------------------------

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[PFPolygonCodingTypeKey] = [coder decodeObjectForKey:PFPolygonCodingTypeKey];
    dictionary[PFPolygonCodingCoordinatesKey] = [coder decodeObjectForKey:PFPolygonCodingCoordinatesKey];
    return [self initWithEncodedDictionary:dictionary];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    NSDictionary *dictionary = [self encodeIntoDictionary:nil];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [coder encodeObject:obj forKey:key];
    }];
}

@end
