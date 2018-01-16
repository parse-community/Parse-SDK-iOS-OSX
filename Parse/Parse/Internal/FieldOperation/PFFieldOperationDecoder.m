/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFFieldOperationDecoder.h"

#import "PFAssert.h"
#import "PFDecoder.h"
#import "PFFieldOperation.h"

@interface PFFieldOperationDecoder () {
    NSMutableDictionary *_operationDecoders;
}

@end

typedef PFFieldOperation * (^PFFieldOperationDecodingBlock_)(NSDictionary *encoded, PFDecoder *decoder);

@implementation PFFieldOperationDecoder

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    _operationDecoders = [NSMutableDictionary dictionary];
    [self _registerDefaultOperationDecoders];

    return self;
}

+ (instancetype)defaultDecoder {
    static PFFieldOperationDecoder *decoder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        decoder = [[self alloc] init];
    });
    return decoder;
}

///--------------------------------------
#pragma mark - Setup
///--------------------------------------

- (void)_registerDecoderForOperationWithName:(NSString *)name block:(PFFieldOperationDecodingBlock_)block {
    _operationDecoders[name] = [block copy];
}

- (void)_registerDefaultOperationDecoders {
    @weakify(self);
    [self _registerDecoderForOperationWithName:@"Batch" block:^(NSDictionary *encoded, PFDecoder *decoder) {
        @strongify(self);
        PFFieldOperation *op = nil;
        NSArray *ops = encoded[@"ops"];
        for (id maybeEncodedNextOp in ops) {
            PFFieldOperation *nextOp = nil;
            if ([maybeEncodedNextOp isKindOfClass:[PFFieldOperation class]]) {
                nextOp = maybeEncodedNextOp;
            } else {
                nextOp = [self decode:maybeEncodedNextOp withDecoder:decoder];
            }
            op = [nextOp mergeWithPrevious:op];
        }
        return op;
    }];

    [self _registerDecoderForOperationWithName:@"Delete" block:^(NSDictionary *encoded, PFDecoder *decoder) {
        // Deleting has no state, so it can be a singleton.
        static PFDeleteOperation *deleteOperation = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            deleteOperation = [[PFDeleteOperation alloc] init];
        });
        return deleteOperation;
    }];

    [self _registerDecoderForOperationWithName:@"Increment" block:^(NSDictionary *encoded, PFDecoder *decoder) {
        return [PFIncrementOperation incrementWithAmount:encoded[@"amount"]];
    }];

    [self _registerDecoderForOperationWithName:@"Add" block:^(NSDictionary *encoded, PFDecoder *decoder) {
        NSArray *objects = [decoder decodeObject:encoded[@"objects"]];
        return [PFAddOperation addWithObjects:objects];
    }];

    [self _registerDecoderForOperationWithName:@"AddUnique" block:^(NSDictionary *encoded, PFDecoder *decoder) {
        NSArray *objects = [decoder decodeObject:encoded[@"objects"]];
        return [PFAddUniqueOperation addUniqueWithObjects:objects];
    }];

    [self _registerDecoderForOperationWithName:@"Remove" block:^(NSDictionary *encoded, PFDecoder *decoder) {
        NSArray *objects = [decoder decodeObject:encoded[@"objects"]];
        return [PFRemoveOperation removeWithObjects:objects];
    }];

    [self _registerDecoderForOperationWithName:@"AddRelation" block:^(NSDictionary *encoded, PFDecoder *decoder) {
        NSArray *objects = [decoder decodeObject:encoded[@"objects"]];
        return [PFRelationOperation addRelationToObjects:objects];
    }];

    [self _registerDecoderForOperationWithName:@"RemoveRelation" block:^(NSDictionary *encoded, PFDecoder *decoder) {
        NSArray *objects = [decoder decodeObject:encoded[@"objects"]];
        return [PFRelationOperation removeRelationToObjects:objects];
    }];
}

///--------------------------------------
#pragma mark - Decoding
///--------------------------------------

- (PFFieldOperation *)decode:(NSDictionary *)encoded withDecoder:(PFDecoder *)decoder {
    NSString *operationName = encoded[@"__op"];
    PFFieldOperationDecodingBlock_ block = _operationDecoders[operationName];
    PFConsistencyAssert(block, @"Unable to decode operation of type %@.", operationName);
    return block(encoded, decoder);
}

@end
