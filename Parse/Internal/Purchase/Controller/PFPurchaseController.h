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
@class PFFileManager;
@class PFPaymentTransactionObserver;
@class PFProductsRequestResult;

@protocol PFCommandRunning;
@class SKPaymentQueue;
@class SKPaymentTransaction;

@interface PFPurchaseController : NSObject

@property (nonatomic, strong, readonly) id<PFCommandRunning> commandRunner;
@property (nonatomic, strong, readonly) PFFileManager *fileManager;
@property (nonatomic, strong, readonly) NSBundle *bundle;

@property (nonatomic, strong) SKPaymentQueue *paymentQueue;
@property (nonatomic, strong, readonly) PFPaymentTransactionObserver *transactionObserver;

@property (nonatomic, assign) Class productsRequestClass;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCommandRunner:(id<PFCommandRunning>)commandRunner
                          fileManager:(PFFileManager *)fileManager
                               bundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithCommandRunner:(id<PFCommandRunning>)commandRunner
                                fileManager:(PFFileManager *)fileManager
                                     bundle:(NSBundle *)bundle;

///--------------------------------------
/// @name Products
///--------------------------------------

- (BFTask *)findProductsAsyncWithIdentifiers:(NSSet *)productIdentifiers;
- (BFTask *)buyProductAsyncWithIdentifier:(NSString *)productIdentifier;
- (BFTask *)downloadAssetAsyncForTransaction:(SKPaymentTransaction *)transaction
                           withProgressBlock:(PFProgressBlock)progressBlock
                                sessionToken:(NSString *)sessionToken;

- (NSString *)assetContentPathForProductWithIdentifier:(NSString *)identifier fileName:(NSString *)fileName;
- (BOOL)canPurchase;

@end
