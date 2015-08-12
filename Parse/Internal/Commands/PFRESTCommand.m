/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFRESTCommand.h"
#import "PFRESTCommand_Private.h"

#import "PFCoreManager.h"
#import "PFFieldOperation.h"
#import "PFHTTPRequest.h"
#import "PFHash.h"
#import "PFInternalUtils.h"
#import "PFObjectLocalIdStore.h"
#import "PFObjectPrivate.h"
#import "Parse_Private.h"

static NSString *const PFRESTCommandHTTPPathEncodingKey = @"httpPath";
static NSString *const PFRESTCommandHTTPMethodEncodingKey = @"httpMethod";
static NSString *const PFRESTCommandParametersEncodingKey = @"parameters";
static NSString *const PFRESTCommandSessionTokenEncodingKey = @"sessionToken";
static NSString *const PFRESTCommandLocalIdEncodingKey = @"localId";

// Increment this when you change the format of cache values.
static const int PFRESTCommandCacheKeyVersion = 1;

@implementation PFRESTCommand

@synthesize sessionToken = _sessionToken;
@synthesize operationSetUUID = _operationSetUUID;
@synthesize localId = _localId;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)commandWithHTTPPath:(NSString *)path
                         httpMethod:(NSString *)httpMethod
                         parameters:(NSDictionary *)parameters
                       sessionToken:(NSString *)sessionToken {
    return [self commandWithHTTPPath:path
                          httpMethod:httpMethod
                          parameters:parameters
                    operationSetUUID:nil
                        sessionToken:sessionToken];
}

+ (instancetype)commandWithHTTPPath:(NSString *)path
                         httpMethod:(NSString *)httpMethod
                         parameters:(NSDictionary *)parameters
                   operationSetUUID:(NSString *)operationSetIdentifier
                       sessionToken:(NSString *)sessionToken {
    PFRESTCommand *command = [[self alloc] init];
    command.httpPath = path;
    command.httpMethod = httpMethod;
    command.parameters = parameters;
    command.operationSetUUID = operationSetIdentifier;
    command.sessionToken = sessionToken;
    return command;
}

///--------------------------------------
#pragma mark - CacheKey
///--------------------------------------

- (NSString *)cacheKey {
    if (_cacheKey) {
        return _cacheKey;
    }

    NSMutableDictionary *cacheParameters = [NSMutableDictionary dictionaryWithCapacity:2];
    if (self.parameters) {
        cacheParameters[PFRESTCommandParametersEncodingKey] = self.parameters;
    }
    if (self.sessionToken) {
        cacheParameters[PFRESTCommandSessionTokenEncodingKey] = self.sessionToken;
    }

    NSString *parametersCacheKey = [PFInternalUtils cacheKeyForObject:cacheParameters];

    _cacheKey = [NSString stringWithFormat:@"PFRESTCommand.%i.%@.%@.%ld.%@",
                 PFRESTCommandCacheKeyVersion, self.httpMethod, PFMD5HashFromString(self.httpPath),
                 // We use MD5 instead of native hash because it collides too much.
                 (long)PARSE_API_VERSION, PFMD5HashFromString(parametersCacheKey)];
    return _cacheKey;
}

///--------------------------------------
#pragma mark - PFNetworkCommand
///--------------------------------------

#pragma mark Encoding/Decoding

+ (instancetype)commandFromDictionaryRepresentation:(NSDictionary *)dictionary {
    if (![self isValidDictionaryRepresentation:dictionary]) {
        return nil;
    }

    PFRESTCommand *command = [self commandWithHTTPPath:dictionary[PFRESTCommandHTTPPathEncodingKey]
                                            httpMethod:dictionary[PFRESTCommandHTTPMethodEncodingKey]
                                            parameters:dictionary[PFRESTCommandParametersEncodingKey]
                                          sessionToken:dictionary[PFRESTCommandSessionTokenEncodingKey]];
    command.localId = dictionary[PFRESTCommandLocalIdEncodingKey];
    return command;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (self.httpPath) {
        dictionary[PFRESTCommandHTTPPathEncodingKey] = self.httpPath;
    }
    if (self.httpMethod) {
        dictionary[PFRESTCommandHTTPMethodEncodingKey] = self.httpMethod;
    }
    if (self.parameters) {
        NSDictionary *parameters = [[PFPointerOrLocalIdObjectEncoder objectEncoder] encodeObject:self.parameters];
        dictionary[PFRESTCommandParametersEncodingKey] = parameters;
    }
    if (self.sessionToken) {
        dictionary[PFRESTCommandSessionTokenEncodingKey] = self.sessionToken;
    }
    if (self.localId) {
        dictionary[PFRESTCommandLocalIdEncodingKey] = self.localId;
    }
    return [dictionary copy];
}

+ (BOOL)isValidDictionaryRepresentation:(NSDictionary *)dictionary {
    return dictionary[PFRESTCommandHTTPPathEncodingKey] != nil;
}

#pragma mark Local Identifiers

/*!
 If this was the second save on a new object while offline, then its objectId
 wasn't yet set when the command was created, so it would have been considered a
 "create". But if the first save succeeded, then there is an objectId now, and it
 will be mapped to the localId for this command's result. If so, change the
 "create" operation to an "update", and add the objectId to the command.
 */
- (void)maybeChangeServerOperation {
    if (self.localId) {
        NSString *objectId = [[Parse _currentManager].coreManager.objectLocalIdStore objectIdForLocalId:self.localId];
        if (objectId) {
            self.localId = nil;

            NSArray *components = [self.httpPath pathComponents];
            if ([components count] == 2) {
                self.httpPath = [NSString pathWithComponents:[components arrayByAddingObject:objectId]];
            }

            if ([self.httpPath hasPrefix:@"classes"] &&
                [self.httpMethod isEqualToString:PFHTTPRequestMethodPOST]) {
                self.httpMethod = PFHTTPRequestMethodPUT;
            }
        }

        if ([self.httpMethod isEqualToString:PFHTTPRequestMethodDELETE] && !objectId) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"Attempt to delete non-existent object."];
        }
    }
}

+ (BOOL)forEachLocalIdIn:(id)object doBlock:(BOOL(^)(PFObject *pointer))block {
    __block BOOL modified = NO;

    // If this is a Pointer with a local id, try to resolve it.
    if ([object isKindOfClass:[PFObject class]] && !((PFObject *)object).objectId) {
        return block(object);
    }

    if ([object isKindOfClass:[NSDictionary class]]) {
        [object enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            if ([[self class] forEachLocalIdIn:obj doBlock:block]) {
                modified = YES;
            }
        }];
    } else if ([object isKindOfClass:[NSArray class]]) {
        for (id value in object) {
            if ([[self class] forEachLocalIdIn:value doBlock:block]) {
                modified = YES;
            }
        }
    } else if ([object isKindOfClass:[PFAddOperation class]]) {
        for (id value in ((PFAddOperation *)object).objects) {
            if ([[self class] forEachLocalIdIn:value doBlock:block]) {
                modified = YES;
            }
        }
    } else if ([object isKindOfClass:[PFAddUniqueOperation class]]) {
        for (id value in ((PFAddUniqueOperation *)object).objects) {
            if ([[self class] forEachLocalIdIn:value doBlock:block]) {
                modified = YES;
            }
        }
    } else if ([object isKindOfClass:[PFRemoveOperation class]]) {
        for (id value in ((PFRemoveOperation *)object).objects) {
            if ([[self class] forEachLocalIdIn:value doBlock:block]) {
                modified = YES;
            }
        }
    }

    return modified;
}

- (void)forEachLocalId:(BOOL(^)(PFObject *pointer))block {
    NSDictionary *data = [[PFDecoder objectDecoder] decodeObject:self.parameters];
    if (!data) {
        return;
    }

    if ([[self class] forEachLocalIdIn:data doBlock:block]) {
        self.parameters = [[PFPointerOrLocalIdObjectEncoder objectEncoder] encodeObject:data];
    }
}

- (void)resolveLocalIds {
    [self forEachLocalId:^(PFObject *pointer) {
        [pointer resolveLocalId];
        return YES;
    }];
    [self maybeChangeServerOperation];
}

@end
