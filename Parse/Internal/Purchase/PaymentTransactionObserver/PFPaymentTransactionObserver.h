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

/*!
 * The PFPaymentTransactionObserver listens to the payment queue, processes a payment by running business logic,
 * and completes the transaction. It's a complex interaction and best explained as follows:
 * 1) an observer object is created and added to the payment queue, typically before IAP happens (but not necessarily),
 * 2) PFPurchase creates a payment and adds it to the payment queue,
 * 3) when the observer sees this payment, it runs the business logic associated with this payment,
 * 4) when the business logic finishes, the observer completes the transaction. If the business logic does not finish, the transaction is not completed, which means the user does not get charged,
 * 5) after the transaction finishes, custom UI logic is run.
 */
PF_WATCH_UNAVAILABLE @interface PFPaymentTransactionObserver : NSObject <SKPaymentTransactionObserver>

- (void)handle:(NSString *)productIdentifier block:(void (^)(SKPaymentTransaction *))block;
- (void)handle:(NSString *)productIdentifier runOnceBlock:(void (^)(NSError *))block;

@end
