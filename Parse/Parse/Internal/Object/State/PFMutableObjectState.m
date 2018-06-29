/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFMutableObjectState.h"

#import "PFDateFormatter.h"
#import "PFObjectState_Private.h"

@implementation PFMutableObjectState

@dynamic parseClassName;
@dynamic objectId;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic serverData;
@dynamic complete;
@dynamic deleted;

///--------------------------------------
#pragma mark - PFMutableObjectState
///--------------------------------------

#pragma mark Accessors

- (void)setServerDataObject:(id)object forKey:(NSString *)key {
    [super setServerDataObject:object forKey:key];
}

- (void)removeServerDataObjectForKey:(NSString *)key {
    [super removeServerDataObjectForKey:key];
}

- (void)removeServerDataObjectsForKeys:(NSArray *)keys {
    [super removeServerDataObjectsForKeys:keys];
}

- (void)setCreatedAtFromString:(NSString *)string {
    [super setCreatedAtFromString:string];
}

- (void)setUpdatedAtFromString:(NSString *)string {
    [super setUpdatedAtFromString:string];
}

#pragma mark Apply

- (void)applyState:(PFObjectState *)state {
    [super applyState:state];
}

- (void)applyOperationSet:(PFOperationSet *)operationSet {
    [super applyOperationSet:operationSet];
}

@end
