/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPurchase.h"

#import "BFTask+Private.h"
#import "PFAssert.h"
#import "PFConstants.h"
#import "PFPaymentTransactionObserver.h"
#import "PFProduct.h"
#import "PFPurchaseController.h"
#import "PFUserPrivate.h"
#import "Parse_Private.h"

@implementation PFPurchase

///--------------------------------------
#pragma mark - Public
///--------------------------------------

+ (void)addObserverForProduct:(NSString *)productIdentifier block:(PFPurchaseProductObservationBlock)block {
    // We require the following method to run on the main thread because we want to add the observer
    // *after* all products handlers have been added. Developers might be calling this method multiple
    // times; and if the observer is added after the first call, the observer might not know how to
    // handle some purchases.

    PFConsistencyAssert([NSThread isMainThread], @"%@ must be called on the main thread.", NSStringFromSelector(_cmd));
    PFParameterAssert(productIdentifier, @"You must pass in a valid product identifier.");
    PFParameterAssert(block, @"You must pass in a valid block for the product.");

    [[Parse _currentManager].purchaseController.transactionObserver handle:productIdentifier block:block];
}

+ (void)buyProduct:(NSString *)productIdentifier block:(PFPurchaseBuyProductResultBlock)completion {
    [[[self _purchaseController] buyProductAsyncWithIdentifier:productIdentifier] continueWithBlock:^id(BFTask *task) {
        if (completion) {
            completion(task.error);
        }
        return nil;
    }];
}

+ (void)restore {
    [[self _purchaseController].paymentQueue restoreCompletedTransactions];
}

+ (void)downloadAssetForTransaction:(SKPaymentTransaction *)transaction
                         completion:(PFPurchaseDownloadAssetResultBlock)completion {
    [self downloadAssetForTransaction:transaction completion:completion progress:nil];
}

+ (void)downloadAssetForTransaction:(SKPaymentTransaction *)transaction
                         completion:(PFPurchaseDownloadAssetResultBlock)completion
                           progress:(PFProgressBlock)progress {
    @weakify(self);
    [[[PFUser _getCurrentUserSessionTokenAsync] continueWithBlock:^id(BFTask *task) {
        @strongify(self);
        NSString *sessionToken = task.result;
        return [[self _purchaseController] downloadAssetAsyncForTransaction:transaction
                                                          withProgressBlock:progress
                                                               sessionToken:sessionToken];
    }] continueWithMainThreadResultBlock:completion executeIfCancelled:YES];
}

+ (NSString *)assetContentPathForProduct:(PFProduct *)product {
    NSString *path = [[self _purchaseController] assetContentPathForProductWithIdentifier:product.productIdentifier
                                                                                 fileName:product.downloadName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }

    return nil;
}

///--------------------------------------
#pragma mark - Purchase Controller
///--------------------------------------

+ (PFPurchaseController *)_purchaseController {
    return [Parse _currentManager].purchaseController;
}

@end
