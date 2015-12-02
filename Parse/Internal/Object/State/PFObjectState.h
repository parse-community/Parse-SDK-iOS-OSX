/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class PFEncoder;
@class PFMutableObjectState;

typedef void(^PFObjectStateMutationBlock)(PFMutableObjectState *state);

@interface PFObjectState : NSObject <NSCopying, NSMutableCopying>

@property (nonatomic, copy, readonly) NSString *parseClassName;
@property (nonatomic, copy, readonly) NSString *objectId;

@property (nonatomic, strong, readonly) NSDate *createdAt;
@property (nonatomic, strong, readonly) NSDate *updatedAt;

@property (nonatomic, copy, readonly) NSDictionary *serverData;

@property (nonatomic, assign, readonly, getter=isComplete) BOOL complete;
@property (nonatomic, assign, readonly, getter=isDeleted) BOOL deleted;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithState:(PFObjectState *)state NS_REQUIRES_SUPER;
- (instancetype)initWithState:(PFObjectState *)state mutatingBlock:(PFObjectStateMutationBlock)block;
- (instancetype)initWithParseClassName:(NSString *)parseClassName;
- (instancetype)initWithParseClassName:(NSString *)parseClassName
                              objectId:(NSString *)objectId
                            isComplete:(BOOL)complete;

+ (instancetype)stateWithState:(PFObjectState *)state NS_REQUIRES_SUPER;
+ (instancetype)stateWithParseClassName:(NSString *)parseClassName;
+ (instancetype)stateWithParseClassName:(NSString *)parseClassName
                               objectId:(NSString *)objectId
                             isComplete:(BOOL)complete;

///--------------------------------------
/// @name Coding
///--------------------------------------

/**
 Encodes all fields in `serverData`, `objectId`, `createdAt` and `updatedAt` into objects suitable for JSON/Persistence.

 @note `parseClassName` isn't automatically added to the dictionary.

 @param objectEncoder Encoder to use to encode custom objects.

 @return `NSDictionary` instance representing object state.
 */
- (NSDictionary *)dictionaryRepresentationWithObjectEncoder:(PFEncoder *)objectEncoder NS_REQUIRES_SUPER;

///--------------------------------------
/// @name Mutating
///--------------------------------------

- (PFObjectState *)copyByMutatingWithBlock:(PFObjectStateMutationBlock)block;

@end
