/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "PFConstants.h"

@class BFTask<__covariant BFGenericType>;
@class PFObject;
@class PFOfflineStore;
@class PFSQLiteDatabase;

///--------------------------------------
#pragma mark - Encoders
///--------------------------------------

@interface PFEncoder : NSObject

+ (instancetype)objectEncoder;

- (id)encodeObject:(id)object error:(NSError **)error;
- (id)encodeParseObject:(PFObject *)object error:(NSError **)error;

@end

/**
 Encoding strategy that rejects PFObject.
 */
@interface PFNoObjectEncoder : PFEncoder

@end

/**
 Encoding strategy that encodes PFObject to PFPointer with objectId or with localId.
 */
@interface PFPointerOrLocalIdObjectEncoder : PFEncoder

@end

/**
 Encoding strategy that encodes PFObject to PFPointer with objectId and rejects
 unsaved PFObject.
 */
@interface PFPointerObjectEncoder : PFPointerOrLocalIdObjectEncoder

@end

/**
 Encoding strategy that can encode objects that are available offline. After using this encoder,
 you must call encodeFinished and wait for its result to be finished before the results of the
 encoding will be valid.
 */
@interface PFOfflineObjectEncoder : PFEncoder

+ (instancetype)objectEncoderWithOfflineStore:(PFOfflineStore *)store database:(PFSQLiteDatabase *)database;

- (BFTask *)encodeFinished;

@end
