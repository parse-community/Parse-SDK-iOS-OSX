/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFEncoder.h"

#import "PFACLPrivate.h"
#import "PFAssert.h"
#import "PFBase64Encoder.h"
#import "PFDateFormatter.h"
#import "PFFieldOperation.h"
#import "PFFileObject_Private.h"
#import "PFGeoPointPrivate.h"
#import "PFPolygonPrivate.h"
#import "PFObjectPrivate.h"
#import "PFOfflineStore.h"
#import "PFRelationPrivate.h"
#import "PFMacros.h"

@implementation PFEncoder

+ (instancetype)objectEncoder {
    static PFEncoder *encoder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        encoder = [[PFEncoder alloc] init];
    });
    return encoder;
}

- (id)encodeObject:(id)object error:(NSError * __autoreleasing *) error {
    if ([object isKindOfClass:[PFObject class]]) {
        return [self encodeParseObject:object error:error];
    } else if ([object isKindOfClass:[NSData class]]) {
        return @{
                 @"__type" : @"Bytes",
                 @"base64" : [PFBase64Encoder base64StringFromData:object]
                 };

    } else if ([object isKindOfClass:[NSDate class]]) {
        return @{
                 @"__type" : @"Date",
                 @"iso" : [[PFDateFormatter sharedFormatter] preciseStringFromDate:object]
                 };

    } else if ([object isKindOfClass:[PFFileObject class]]) {
        if (((PFFileObject *)object).dirty) {
            // TODO: (nlutsenko) Figure out what to do with things like an unsaved file
            // in a mutable container, where we don't normally want to allow serializing
            // such a thing inside an object.
            //
            // Returning this empty object is strictly wrong, but we have to have *something*
            // to put into an object's mutable container cache, and this is just about the
            // best we can do right now.
            return @{ @"__type" : @"File" };
        }
        return @{
                 @"__type" : @"File",
                 @"url" : ((PFFileObject *)object).state.urlString,
                 @"name" : ((PFFileObject *)object).name
                 };

    } else if ([object isKindOfClass:[PFFieldOperation class]]) {
        // Always encode PFFieldOperation with PFPointerOrLocalId
        return [object encodeWithObjectEncoder:[PFPointerOrLocalIdObjectEncoder objectEncoder] error:error];
    } else if ([object isKindOfClass:[PFACL class]]) {
        // TODO (hallucinogen): pass object encoder here
        return [object encodeIntoDictionary:error];

    } else if ([object isKindOfClass:[PFGeoPoint class]]) {
        // TODO (hallucinogen): pass object encoder here
        return [object encodeIntoDictionary:error];

    } else if ([object isKindOfClass:[PFPolygon class]]) {
        // TODO (hallucinogen): pass object encoder here
        return [object encodeIntoDictionary:error];

    } else if ([object isKindOfClass:[PFRelation class]]) {
        // TODO (hallucinogen): pass object encoder here
        return [object encodeIntoDictionary:error];

    } else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:[object count]];
        for (id elem in object) {
            id encodedElem = [self encodeObject:elem error:error];
            PFPreconditionBailOnError(encodedElem, error, nil);
            [newArray addObject:encodedElem];
        }
        return newArray;

    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:[object count]];
        __block BOOL encodingFailed = NO;
        __block NSError *encodingError = nil;
        [object enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            id result = [self encodeObject:obj error:&encodingError];
            if (!result && encodingError) {
                encodingFailed = YES;
                *stop = YES;
            } else {
                dict[key] = result;
            }
        }];
        if (encodingFailed) {
            PFSetError(error, encodingError);
            return nil;
        }
        return dict;
    }

    return object;
}

- (id)encodeParseObject:(PFObject *)object error:(NSError **)error {
    // Do nothing here
    return nil;
}

@end

///--------------------------------------
#pragma mark - PFNoObjectEncoder
///--------------------------------------

@implementation PFNoObjectEncoder

+ (instancetype)objectEncoder {
    static PFNoObjectEncoder *encoder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        encoder = [[PFNoObjectEncoder alloc] init];
    });
    return encoder;
}

- (id)encodeParseObject:(PFObject *)object error:(NSError **)error {
    PFConsistencyAssertionFailure(@"PFObjects are not allowed here.");
    return nil;
}

@end

///--------------------------------------
#pragma mark - PFPointerOrLocalIdObjectEncoder
///--------------------------------------

@implementation PFPointerOrLocalIdObjectEncoder

+ (instancetype)objectEncoder {
    static PFPointerOrLocalIdObjectEncoder *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PFPointerOrLocalIdObjectEncoder alloc] init];
    });
    return instance;
}

- (id)encodeParseObject:(PFObject *)object error:(NSError **)error {
    if (object.objectId) {
        return @{
                 @"__type" : @"Pointer",
                 @"objectId" : object.objectId,
                 @"className" : object.parseClassName
                 };
    }
    return @{
             @"__type" : @"Pointer",
             @"localId" : [object getOrCreateLocalId],
             @"className" : object.parseClassName
             };
}

@end

///--------------------------------------
#pragma mark - PFPointerObjectEncoder
///--------------------------------------

@implementation PFPointerObjectEncoder

+ (instancetype)objectEncoder {
    static PFPointerObjectEncoder *encoder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        encoder = [[self alloc] init];
    });
    return encoder;
}

- (id)encodeParseObject:(PFObject *)object error:(NSError * __autoreleasing *)error {
    PFPreconditionBailAndSetError(object.objectId, error, nil, @"Tried to save an object with a new, unsaved child.");
    return [super encodeParseObject:object error:error];
}

@end

///--------------------------------------
#pragma mark - PFOfflineObjectEncoder
///--------------------------------------

@interface PFOfflineObjectEncoder ()

@property (nonatomic, weak) PFOfflineStore *store;
@property (nonatomic, weak) PFSQLiteDatabase *database;
@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) NSObject *tasksLock; // TODO: (nlutsenko) Avoid using @synchronized

@end

@implementation PFOfflineObjectEncoder

+ (instancetype)objectEncoder {
    PFNotDesignatedInitializer();
    return nil;
}

- (instancetype)initWithOfflineStore:(PFOfflineStore *)store database:(PFSQLiteDatabase *)database {
    self = [self init];
    if (!self) return nil;

    _tasks = [NSMutableArray array];
    _tasksLock = [[NSObject alloc] init];

    _store = store;
    _database = database;

    return self;
}

+ (instancetype)objectEncoderWithOfflineStore:(PFOfflineStore *)store database:(PFSQLiteDatabase *)database {
    return [[self alloc] initWithOfflineStore:store database:database];
}

- (id)encodeParseObject:(PFObject *)object error:(NSError **)error {
    if (object.objectId) {
        return @{ @"__type" : @"Pointer",
                  @"objectId" : object.objectId,
                  @"className" : object.parseClassName };
    }

    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithObject:@"OfflineObject" forKey:@"__type"];
    @synchronized(self.tasksLock) {
        BFTask *uuidTask = [self.store getOrCreateUUIDAsyncForObject:object database:self.database];
        [uuidTask continueWithSuccessBlock:^id(BFTask *task) {
            result[@"uuid"] = task.result;
            return nil;
        }];
        [self.tasks addObject:uuidTask];
    }
    return result;
}

- (BFTask *)encodeFinished {
    return [[BFTask taskForCompletionOfAllTasks:self.tasks] continueWithBlock:^id(BFTask *ignore) {
        @synchronized (self.tasksLock) {
            // TODO (hallucinogen) It might be better to return an aggregate error here
            for (BFTask *task in self.tasks) {
                if (task.cancelled || task.error != nil) {
                    return task;
                }
            }
            [self.tasks removeAllObjects];
        }
        return nil;
    }];
}

@end
