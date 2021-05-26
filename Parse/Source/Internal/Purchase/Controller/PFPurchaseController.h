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

#import "PFDataProvider.h"

PF_OSX_UNAVAILABLE_WARNING
PF_WATCH_UNAVAILABLE_WARNING

@class BFTask<__covariant BFGenericType>;
@class PFFileManager;
@class PFPaymentTransactionObserver;
@class PFProductsRequestResult;

@protocol PFCommandRunning;
@class SKPaymentQueue;
@class SKPaymentTransaction;

PF_OSX_UNAVAILABLE PF_WATCH_UNAVAILABLE @interface PFPurchaseController : NSObject

@property (nonatomic, weak, readonly) id<PFCommandRunnerProvider, PFFileManagerProvider> dataSource;
@property (nonatomic, strong, readonly) NSBundle *bundle;

@property (nonatomic, strong) SKPaymentQueue *paymentQueue;
@property (nonatomic, strong, readonly) PFPaymentTransactionObserver *transactionObserver;

@property (nonatomic, assign) Class productsRequestClass;

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource
                            bundle:(NSBundle *)bundle NS_DESIGNATED_INITIALIZER;

+ (instancetype)controllerWithDataSource:(id<PFCommandRunnerProvider, PFFileManagerProvider>)dataSource
                                  bundle:(NSBundle *)bundle;

///--------------------------------------
#pragma mark - Products
///--------------------------------------

- (BFTask *)findProductsAsyncWithIdentifiers:(NSSet *)productIdentifiers;
- (BFTask *)buyProductAsyncWithIdentifier:(NSString *)productIdentifier;
- (BFTask *)downloadAssetAsyncForTransaction:(SKPaymentTransaction *)transaction
                           withProgressBlock:(PFProgressBlock)progressBlock
                                sessionToken:(NSString *)sessionToken;

- (NSString *)assetContentPathForProductWithIdentifier:(NSString *)identifier fileName:(NSString *)fileName;
- (BOOL)canPurchase;

@end
