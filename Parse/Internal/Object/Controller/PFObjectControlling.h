/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import <Parse/PFConstants.h>

#import "PFMacros.h"

@class BFTask PF_GENERIC(__covariant BFGenericType);
@class PFObject;

NS_ASSUME_NONNULL_BEGIN

@protocol PFObjectControlling <NSObject>

///--------------------------------------
/// @name Fetch
///--------------------------------------

/*!
 Fetches an object asynchronously.

 @param object       Object to fetch.
 @param sessionToken Session token to use.

 @returns `BFTask` with result set to `PFObject`.
 */
- (BFTask *)fetchObjectAsync:(PFObject *)object withSessionToken:(nullable NSString *)sessionToken;

- (BFTask *)processFetchResultAsync:(NSDictionary *)result forObject:(PFObject *)object;

///--------------------------------------
/// @name Delete
///--------------------------------------

/*!
 Deletes an object asynchronously.

 @param object       Object to fetch.
 @param sessionToken Session token to use.

 @returns `BFTask` with result set to `nil`.
 */
- (BFTask *)deleteObjectAsync:(PFObject *)object withSessionToken:(nullable NSString *)sessionToken;

//TODO: (nlutsenko) This needs removal, figure out how to kill it.
- (BFTask *)processDeleteResultAsync:(nullable NSDictionary *)result forObject:(PFObject *)object;

@end

NS_ASSUME_NONNULL_END
