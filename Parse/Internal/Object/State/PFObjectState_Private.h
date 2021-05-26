/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObjectState.h"

@class PFOperationSet;

@interface PFObjectState () {
@protected
    NSString *_parseClassName;
    NSString *_objectId;
    NSDate *_createdAt;
    NSDate *_updatedAt;
    NSMutableDictionary *_serverData;

    BOOL _complete;
    BOOL _deleted;
}

@property (nonatomic, copy, readwrite) NSString *parseClassName;
@property (nonatomic, copy, readwrite) NSString *objectId;
@property (nonatomic, strong, readwrite) NSDate *createdAt;
@property (nonatomic, strong, readwrite) NSDate *updatedAt;
@property (nonatomic, copy, readwrite) NSMutableDictionary *serverData;

@property (nonatomic, assign, readwrite, getter=isComplete) BOOL complete;
@property (nonatomic, assign, readwrite, getter=isDeleted) BOOL deleted;

@end

@interface PFObjectState (Mutable)

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setServerDataObject:(id)object forKey:(NSString *)key;
- (void)removeServerDataObjectForKey:(NSString *)key;
- (void)removeServerDataObjectsForKeys:(NSArray *)keys;

- (void)setCreatedAtFromString:(NSString *)string;
- (void)setUpdatedAtFromString:(NSString *)string;

///--------------------------------------
#pragma mark - Apply
///--------------------------------------

- (void)applyState:(PFObjectState *)state NS_REQUIRES_SUPER;
- (void)applyOperationSet:(PFOperationSet *)operationSet NS_REQUIRES_SUPER;

@end
