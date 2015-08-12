/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@protocol PFNetworkCommand <NSObject>

///--------------------------------------
/// @name Properties
///--------------------------------------

@property (nonatomic, copy, readonly) NSString *sessionToken;
@property (nonatomic, copy, readonly) NSString *operationSetUUID;

// If this command creates an object that is referenced by some other command,
// then this localId will be updated with the new objectId that is returned.
@property (nonatomic, copy) NSString *localId;

///--------------------------------------
/// @name Encoding/Decoding
///--------------------------------------

+ (instancetype)commandFromDictionaryRepresentation:(NSDictionary *)dictionary;
- (NSDictionary *)dictionaryRepresentation;

+ (BOOL)isValidDictionaryRepresentation:(NSDictionary *)dictionary;

///--------------------------------------
/// @name Local Identifiers
///--------------------------------------

/*!
 Replaces all local ids in this command with the correct objectId for that object.
 This should be called before sending the command over the network, so that there
 are no local ids sent to the Parse Cloud. If any local id refers to an object that
 has not yet been saved, and thus has no objectId, then this method raises an
 exception.
 */
- (void)resolveLocalIds;

@end
