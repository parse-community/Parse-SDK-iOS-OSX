/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestSKPaymentQueue.h"

#import "PFTestSKPaymentTransaction.h"

@interface PFTestSKPaymentQueue ()
{
    NSMutableSet *_observers;
}

@end

@implementation PFTestSKPaymentQueue

+ (instancetype)defaultQueue {
    static PFTestSKPaymentQueue *queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[self alloc] init];
    });
    return queue;
}

static BOOL _canMakePayments = YES;
+ (BOOL)canMakePayments {
    return _canMakePayments;
}

+ (void)setCanMakePayments:(BOOL)canMakePayments {
    _canMakePayments = canMakePayments;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    _observers = [NSMutableSet set];

    return self;
}

- (void)addPayment:(SKPayment *)payment {
    dispatch_async(dispatch_get_main_queue(), ^{
        PFTestSKPaymentTransaction *transaction = [PFTestSKPaymentTransaction transactionForPayment:payment
                                                                                          withError:nil
                                                                                            inState:SKPaymentTransactionStatePurchased];
        dispatch_async(dispatch_get_main_queue(), ^{
            for (NSValue *value in _observers) {
                id observer = [value nonretainedObjectValue];
                if (observer) {
                    [observer paymentQueue:self updatedTransactions:@[ transaction ]];
                }
            }
        });
    });
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
}

- (void)addTransactionObserver:(id<SKPaymentTransactionObserver>)observer {
    [_observers addObject:[NSValue valueWithNonretainedObject:observer]];
}

- (void)removeTransactionObserver:(id<SKPaymentTransactionObserver>)observer {
    [_observers removeObject:[NSValue valueWithNonretainedObject:observer]];
    [_observers filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSValue *evaluatedObject, NSDictionary *bindings) {
        return ([evaluatedObject nonretainedObjectValue] != nil);
    }]];
}

@end
