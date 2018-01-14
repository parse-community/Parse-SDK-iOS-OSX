/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFDecoder.h"

#import "PFBase64Encoder.h"
#import "PFDateFormatter.h"
#import "PFFieldOperation.h"
#import "PFFieldOperationDecoder.h"
#import "PFFile_Private.h"
#import "PFGeoPointPrivate.h"
#import "PFPolygonPrivate.h"
#import "PFInternalUtils.h"
#import "PFMacros.h"
#import "PFObjectPrivate.h"
#import "PFRelationPrivate.h"

///--------------------------------------
#pragma mark - PFDecoder
///--------------------------------------

@implementation PFDecoder

#pragma mark Init

+ (PFDecoder *)objectDecoder {
    static PFDecoder *decoder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        decoder = [[PFDecoder alloc] init];
    });
    return decoder;
}

#pragma mark Decode

- (id)decodeDictionary:(NSDictionary *)dictionary {
    NSString *op = dictionary[@"__op"];
    if (op) {
        return [[PFFieldOperationDecoder defaultDecoder] decode:dictionary withDecoder:self];
    }

    NSString *type = dictionary[@"__type"];
    if (type) {
        if ([type isEqualToString:@"Date"]) {
            return [[PFDateFormatter sharedFormatter] dateFromString:dictionary[@"iso"]];

        } else if ([type isEqualToString:@"Bytes"]) {
            return [PFBase64Encoder dataFromBase64String:dictionary[@"base64"]];

        } else if ([type isEqualToString:@"GeoPoint"]) {
            return [PFGeoPoint geoPointWithDictionary:dictionary];

        } else if ([type isEqualToString:@"Polygon"]) {
            return [PFPolygon polygonWithDictionary:dictionary];

        } else if ([type isEqualToString:@"Relation"]) {
            return [PFRelation relationFromDictionary:dictionary withDecoder:self];

        } else if ([type isEqualToString:@"File"]) {
            return [PFFile fileWithName:dictionary[@"name"]
                                    url:dictionary[@"url"]];

        } else if ([type isEqualToString:@"Pointer"]) {
            NSString *objectId = dictionary[@"objectId"];
            NSString *localId = dictionary[@"localId"];
            NSString *className = dictionary[@"className"];
            if (localId) {
                // This is a PFObject deserialized off the local disk, which has a localId
                // that will need to be resolved before the object can be sent over the network.
                // Its localId should be known to PFObjectLocalIdStore.
                return [self _decodePointerForClassName:className localId:localId];
            } else {
                return [self _decodePointerForClassName:className objectId:objectId];
            }

        } else if ([type isEqualToString:@"Object"]) {
            NSString *className = dictionary[@"className"];

            NSMutableDictionary *data = [dictionary mutableCopy];
            [data removeObjectForKey:@"__type"];
            [data removeObjectForKey:@"className"];
            NSDictionary *result = [self decodeDictionary:data];

            return [PFObject _objectFromDictionary:result
                                  defaultClassName:className
                                      completeData:YES
                                           decoder:self];

        } else {
            // We don't know how to decode this, so just leave it as a dictionary.
            return dictionary;
        }
    }

    NSMutableDictionary *newDictionary = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        newDictionary[key] = [self decodeObject:obj];
    }];
    return newDictionary;
}

- (id)_decodePointerForClassName:(NSString *)className objectId:(NSString *)objectId {
    return [PFObject objectWithoutDataWithClassName:className objectId:objectId];
}

- (id)_decodePointerForClassName:(NSString *)className localId:(NSString *)localId {
    return [PFObject objectWithoutDataWithClassName:className localId:localId];
}

- (id)decodeArray:(NSArray *)array {
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];
    for (id value in array) {
        [newArray addObject:[self decodeObject:value]];
    }
    return newArray;
}

- (id)decodeObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [self decodeDictionary:object];
    } else if ([object isKindOfClass:[NSArray class]]) {
        return [self decodeArray:object];
    }
    return object;
}

@end

///--------------------------------------
#pragma mark - PFOfflineDecoder
///--------------------------------------

@interface PFOfflineDecoder ()

/**
 A map of UUID to Task that will be finished once the given PFObject is loaded.
 The Tasks should all be finished before decode is called.
 */
@property (nonatomic, copy) NSDictionary *offlineObjects;

@end

@implementation PFOfflineDecoder

+ (instancetype)decoderWithOfflineObjects:(NSDictionary *)offlineObjects {
    PFOfflineDecoder *decoder = [[self alloc] init];
    decoder.offlineObjects = offlineObjects;
    return decoder;
}

#pragma mark PFDecoder

- (id)decodeObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]] &&
        [((NSDictionary *)object)[@"__type"] isEqualToString:@"OfflineObject"]) {
        NSString *uuid = ((NSDictionary *)object)[@"uuid"];
        return ((BFTask *)self.offlineObjects[uuid]).result;
    }

    // Embedded objects can't show up here, because we never stored them that way offline.
    return [super decodeObject:object];
}

@end

///--------------------------------------
#pragma mark - PFKnownParseObjectDecoder
///--------------------------------------

@interface PFKnownParseObjectDecoder ()

@property (nonatomic, copy) NSDictionary *fetchedObjects;

@end

@implementation PFKnownParseObjectDecoder

+ (instancetype)decoderWithFetchedObjects:(NSDictionary *)fetchedObjects {
    PFKnownParseObjectDecoder *decoder = [[self alloc] init];
    decoder.fetchedObjects = fetchedObjects;
    return decoder;
}

- (id)_decodePointerForClassName:(NSString *)className objectId:(NSString *)objectId {
    if (_fetchedObjects != nil && _fetchedObjects[objectId]) {
        return _fetchedObjects[objectId];
    }
    return [super _decodePointerForClassName:className objectId:objectId];
}

@end
