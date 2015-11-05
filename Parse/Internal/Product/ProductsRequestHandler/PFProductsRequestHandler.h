/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import <Parse/PFConstants.h>

PF_WATCH_UNAVAILABLE_WARNING

@class BFTask PF_GENERIC(__covariant BFGenericType);

PF_WATCH_UNAVAILABLE @interface PFProductsRequestResult : NSObject

@property (nonatomic, copy, readonly) NSSet *validProducts;
@property (nonatomic, copy, readonly) NSSet *invalidProductIdentifiers;

- (instancetype)initWithProductsResponse:(SKProductsResponse *)response;

@end

/*!
 * This class is responsible for handling the first part of an IAP handshake.
 * It sends a request to iTunes Connect with a set of product identifiers, and iTunes returns
 * with a list of valid and invalid products. The class then proceeds to call the completion block passed in.
 */
@interface PFProductsRequestHandler : NSObject

- (instancetype)initWithProductsRequest:(SKProductsRequest *)request;

- (BFTask *)findProductsAsync;

@end
