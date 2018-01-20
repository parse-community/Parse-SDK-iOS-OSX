/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectFileCoder.h"

#import "PFJSONSerialization.h"
#import "PFObjectFileCodingLogic.h"
#import "PFObjectPrivate.h"
#import "PFObjectState.h"

@implementation PFObjectFileCoder

///--------------------------------------
#pragma mark - Encode
///--------------------------------------

+ (NSData *)dataFromObject:(PFObject *)object usingEncoder:(PFEncoder *)encoder {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"classname"] = object._state.parseClassName;
    // TODO (flovilmart): is it safe to swallow error here?
    result[@"data"] = [object._state dictionaryRepresentationWithObjectEncoder:encoder error:nil];
    return [PFJSONSerialization dataFromJSONObject:result];
}

///--------------------------------------
#pragma mark - Decode
///--------------------------------------

+ (PFObject *)objectFromData:(NSData *)data usingDecoder:(PFDecoder *)decoder {
    NSDictionary *dictionary = [PFJSONSerialization JSONObjectFromData:data];
    NSString *className = dictionary[@"classname"] ?: dictionary[@"className"];
    NSString *objectId = dictionary[@"data"][@"objectId"] ?: dictionary[@"id"];

    PFObject *object = [PFObject objectWithoutDataWithClassName:className objectId:objectId];
    [[[object class] objectFileCodingLogic] updateObject:object fromDictionary:dictionary usingDecoder:decoder];
    return object;
}

@end
