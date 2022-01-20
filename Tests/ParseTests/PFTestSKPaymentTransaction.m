/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestSKPaymentTransaction.h"

@implementation PFTestSKPaymentTransaction

@synthesize
error = _error,
originalTransaction = _originalTransaction,
payment = _payment,
transactionDate = _transactionDate,
transactionIdentifier = _transactionIdentifier,
transactionReceipt = _transactionReceipt,
transactionState = _transactionState;

+ (instancetype)transactionForPayment:(SKPayment *)payment
                            withError:(NSError *)error
                              inState:(SKPaymentTransactionState)state {
    PFTestSKPaymentTransaction *transaction = [[self alloc] init];
    transaction.payment = payment;
    transaction.error = error;
    transaction.transactionState = state;
    return transaction;
}

@end
