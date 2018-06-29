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

#import "PFAssert.h"
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
static const int PFRESTCommandCacheKeyParseAPIVersion = 2;

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
                       sessionToken:(NSString *)sessionToken
                              error:(NSError **) error {
    return [self commandWithHTTPPath:path
                          httpMethod:httpMethod
                          parameters:parameters
                    operationSetUUID:nil
                        sessionToken:sessionToken
                               error:error];
}

+ (instancetype)commandWithHTTPPath:(NSString *)path
                         httpMethod:(NSString *)httpMethod
                         parameters:(NSDictionary *)parameters
                   operationSetUUID:(NSString *)operationSetIdentifier
                       sessionToken:(NSString *)sessionToken
                              error:(NSError **)error {
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
                 (long)PFRESTCommandCacheKeyParseAPIVersion, PFMD5HashFromString(parametersCacheKey)];
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
                                          sessionToken:dictionary[PFRESTCommandSessionTokenEncodingKey]
                                                 error:nil];
    command.localId = dictionary[PFRESTCommandLocalIdEncodingKey];
    return command;
}

- (NSDictionary *)dictionaryRepresentation:(NSError **)error {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (self.httpPath) {
        dictionary[PFRESTCommandHTTPPathEncodingKey] = self.httpPath;
    }
    if (self.httpMethod) {
        dictionary[PFRESTCommandHTTPMethodEncodingKey] = self.httpMethod;
    }
    if (self.parameters) {
        NSDictionary *parameters = [[PFPointerOrLocalIdObjectEncoder objectEncoder] encodeObject:self.parameters error:error];
        if (!parameters) {
            return nil;
        }
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

/**
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

            NSArray *components = self.httpPath.pathComponents;
            if (components.count == 2) {
                self.httpPath = [NSString pathWithComponents:[components arrayByAddingObject:objectId]];
            }

            if ([self.httpPath hasPrefix:@"classes"] &&
                [self.httpMethod isEqualToString:PFHTTPRequestMethodPOST]) {
                self.httpMethod = PFHTTPRequestMethodPUT;
            }
        }

        PFConsistencyAssert(![self.httpMethod isEqualToString:PFHTTPRequestMethodDELETE] || objectId,
                            @"Attempt to delete non-existent object.");
    }
}

+ (BOOL)forEachLocalIdIn:(id)object
                 doBlock:(BOOL(^)(PFObject *pointer, BOOL *modified, NSError **error))block
                modified:(BOOL *)modified error:(NSError **)error {

    // If this is a Pointer with a local id, try to resolve it.
    if ([object isKindOfClass:[PFObject class]] && !((PFObject *)object).objectId) {
        __block BOOL blockModified = NO;
        BOOL success = block(object, &blockModified, error);
        if (blockModified) {
            *modified = YES;
        }
        return success;
    }

    if ([object isKindOfClass:[NSDictionary class]]) {
        __block NSError *localError;
        __block BOOL hasFailed = NO;
        [object enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            if (![[self class] forEachLocalIdIn:obj doBlock:block modified:modified error:&localError]) {
                *stop = YES;
                hasFailed = YES;
            }
        }];
        if (hasFailed && error) {
            *error = localError;
            return NO;
        }
    } else if ([object isKindOfClass:[NSArray class]]) {
        for (id value in object) {
            if (![[self class] forEachLocalIdIn:value doBlock:block modified:modified error:error]) {
                return NO;
            }
        }
    } else if ([object isKindOfClass:[PFAddOperation class]]) {
        for (id value in ((PFAddOperation *)object).objects) {
            if (![[self class] forEachLocalIdIn:value doBlock:block modified:modified  error:error]) {
                return NO;
            }
        }
    } else if ([object isKindOfClass:[PFAddUniqueOperation class]]) {
        for (id value in ((PFAddUniqueOperation *)object).objects) {
            if (![[self class] forEachLocalIdIn:value doBlock:block modified:modified error:error]) {
                return NO;
            }
        }
    } else if ([object isKindOfClass:[PFRemoveOperation class]]) {
        for (id value in ((PFRemoveOperation *)object).objects) {
            if (![[self class] forEachLocalIdIn:value doBlock:block modified:modified error:error]) {
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)forEachLocalId:(BOOL(^)(PFObject *pointer, BOOL *modified, NSError **error))block error:(NSError **)error {
    NSDictionary *data = [[PFDecoder objectDecoder] decodeObject:self.parameters];
    if (!data) {
        return YES;
    }
    BOOL modified = NO;
    if ([[self class] forEachLocalIdIn:data doBlock:block modified:&modified error:error]) {
        self.parameters = [[PFPointerOrLocalIdObjectEncoder objectEncoder] encodeObject:data error:error];
        if (self.parameters && !(error && *error)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)resolveLocalIds:(NSError * __autoreleasing *)error {
    BOOL paramEncodingSucceeded = [self forEachLocalId:^(PFObject *pointer, BOOL *modified, NSError **blockError) {
        NSError *localError;
        BOOL success = [pointer resolveLocalId:&localError];
        *modified = YES;
        if (!success && localError) {
            *blockError = localError;
        }
        return success;
    } error: error];
    if (!paramEncodingSucceeded && *error) {
        return NO;
    }
    [self maybeChangeServerOperation];
    return YES;
}

@end
