/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PFDecoder : NSObject

/*!
 Globally available shared instance of PFDecoder.
 */
+ (PFDecoder *)objectDecoder;

/*!
 Takes a complex object that was deserialized and converts encoded
 dictionaries into the proper Parse types. This is the inverse of
 encodeObject:allowUnsaved:allowObjects:seenObjects:.
 */
- (nullable id)decodeObject:(nullable id)object;

@end

/*!
 Extends the normal JSON to PFObject decoding to also deal with placeholders for new objects
 that have been saved offline.
 */
@interface PFOfflineDecoder : PFDecoder

+ (instancetype)decoderWithOfflineObjects:(nullable NSDictionary *)offlineObjects;

@end

/*!
 A subclass of PFDecoder which can keep PFObject that has been fetched instead of creating a new instance.
 */
@interface PFKnownParseObjectDecoder : PFDecoder

+ (instancetype)decoderWithFetchedObjects:(nullable NSDictionary *)fetchedObjects;

@end

NS_ASSUME_NONNULL_END
