/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import StoreKit;

@interface PFTestSKPaymentTransaction : SKPaymentTransaction

@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) SKPaymentTransaction *originalTransaction;
@property (nonatomic, strong) SKPayment *payment;
@property (nonatomic, strong) NSDate *transactionDate;
@property (nonatomic, copy) NSString *transactionIdentifier;
@property (nonatomic, strong) NSData *transactionReceipt;
@property (nonatomic, assign) SKPaymentTransactionState transactionState;

+ (instancetype)transactionForPayment:(SKPayment *)payment
                            withError:(NSError *)error
                              inState:(SKPaymentTransactionState)state;

@end
