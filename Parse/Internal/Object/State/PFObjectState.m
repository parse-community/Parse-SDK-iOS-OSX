/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAssert.h"
#import "PFObjectState.h"
#import "PFObjectState_Private.h"

#import "PFDateFormatter.h"
#import "PFEncoder.h"
#import "PFMutableObjectState.h"
#import "PFObjectConstants.h"
#import "PFObjectUtilities.h"
#import "PFFieldOperation.h"

@implementation PFObjectState

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _serverData = [NSMutableDictionary dictionary];

    return self;
}

- (instancetype)initWithState:(PFObjectState *)state {
    self = [self init];
    if (!self) return nil;

    _parseClassName = [state.parseClassName copy];
    _objectId = [state.objectId copy];

    _updatedAt = state.updatedAt;
    _createdAt = state.createdAt;

    _serverData = [state.serverData mutableCopy] ?: [NSMutableDictionary dictionary];

    _complete = state.complete;
    _deleted = state.deleted;

    return self;
}

- (instancetype)initWithParseClassName:(NSString *)parseClassName {
    return [self initWithParseClassName:parseClassName objectId:nil isComplete:NO];
}

- (instancetype)initWithParseClassName:(NSString *)parseClassName
                              objectId:(NSString *)objectId
                            isComplete:(BOOL)complete {
    self = [self init];
    if (!self) return nil;

    _parseClassName = [parseClassName copy];
    _objectId = [objectId copy];
    _complete = complete;

    return self;
}

- (instancetype)initWithState:(PFObjectState *)state mutatingBlock:(PFObjectStateMutationBlock)block {
    self = [self initWithState:state];
    if (!self) return nil;

    block((PFMutableObjectState *)self);

    return self;
}

+ (instancetype)stateWithState:(PFObjectState *)state {
    return [[self alloc] initWithState:state];
}

+ (instancetype)stateWithParseClassName:(NSString *)parseClassName {
    return [[self alloc] initWithParseClassName:parseClassName];
}

+ (instancetype)stateWithParseClassName:(NSString *)parseClassName
                               objectId:(NSString *)objectId
                             isComplete:(BOOL)complete {
    return [[self alloc] initWithParseClassName:parseClassName
                                       objectId:objectId
                                     isComplete:complete];
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------s

- (void)setServerData:(NSDictionary *)serverData {
    if (self.serverData != serverData) {
        _serverData = [serverData mutableCopy];
    }
}

///--------------------------------------
#pragma mark - Coding
///--------------------------------------

- (NSDictionary *)dictionaryRepresentationWithObjectEncoder:(PFEncoder *)objectEncoder error:(NSError * __autoreleasing *)error {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if (self.objectId) {
        result[PFObjectObjectIdRESTKey] = self.objectId;
    }
    if (self.createdAt) {
        result[PFObjectCreatedAtRESTKey] = [[PFDateFormatter sharedFormatter] preciseStringFromDate:self.createdAt];
    }
    if (self.updatedAt) {
        result[PFObjectUpdatedAtRESTKey] = [[PFDateFormatter sharedFormatter] preciseStringFromDate:self.updatedAt];
    }
    __block NSError *encodingError;
    __block BOOL failed = NO;
    [self.serverData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        id encoded = [objectEncoder encodeObject:obj error:&encodingError];
        if (!encoded && encodingError) {
            *stop = YES;
            failed = YES;
            return;
        }
        result[key] = encoded;
    }];
    if (failed && encodingError) {
        PFSetError(error, encodingError);
        return nil;
    }
    return [result copy];
}

///--------------------------------------
#pragma mark - PFObjectState (Mutable)
///--------------------------------------

#pragma mark Accessors

- (void)setServerDataObject:(id)object forKey:(NSString *)key {
    if (!object || [object isKindOfClass:[PFDeleteOperation class]]) {
        [self removeServerDataObjectForKey:key];
    } else {
        _serverData[key] = object;
    }
}

- (void)removeServerDataObjectForKey:(NSString *)key {
    [_serverData removeObjectForKey:key];
}

- (void)removeServerDataObjectsForKeys:(NSArray *)keys {
    [_serverData removeObjectsForKeys:keys];
}

- (void)setCreatedAtFromString:(NSString *)string {
    self.createdAt = [[PFDateFormatter sharedFormatter] dateFromString:string];
}

- (void)setUpdatedAtFromString:(NSString *)string {
    self.updatedAt = [[PFDateFormatter sharedFormatter] dateFromString:string];
}

#pragma mark Apply

- (void)applyState:(PFObjectState *)state {
    if (state.objectId) {
        self.objectId = state.objectId;
    }
    if (state.createdAt) {
        self.createdAt = state.createdAt;
    }
    if (state.updatedAt) {
        self.updatedAt = state.updatedAt;
    }
    [_serverData addEntriesFromDictionary:state.serverData];

    self.complete |= state.complete;
}

- (void)applyOperationSet:(PFOperationSet *)operationSet {
    [PFObjectUtilities applyOperationSet:operationSet toDictionary:_serverData];
}

///--------------------------------------
#pragma mark - Mutating
///--------------------------------------

- (PFObjectState *)copyByMutatingWithBlock:(PFObjectStateMutationBlock)block {
    return [[PFObjectState alloc] initWithState:self mutatingBlock:block];
}

///--------------------------------------
#pragma mark - NSCopying
///--------------------------------------

- (id)copyWithZone:(NSZone *)zone {
    return [[PFObjectState allocWithZone:zone] initWithState:self];
}

///--------------------------------------
#pragma mark - NSMutableCopying
///--------------------------------------

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [[PFMutableObjectState allocWithZone:zone] initWithState:self];
}

@end
