/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFPaymentTransactionObserver_Private.h"

#import "PFAssert.h"

@implementation PFPaymentTransactionObserver

@synthesize blocks;
@synthesize runOnceBlocks;
@synthesize lockObj;
@synthesize runOnceLockObj;

///--------------------------------------
#pragma mark - NSObject
///--------------------------------------

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    blocks = [[NSMutableDictionary alloc] init];
    runOnceBlocks = [[NSMutableDictionary alloc] init];
    lockObj = [[NSObject alloc] init];
    runOnceLockObj = [[NSObject alloc] init];

    return self;
}

///--------------------------------------
#pragma mark - SKPaymentTransactionObserver
///--------------------------------------

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateFailed:
            case SKPaymentTransactionStateRestored:
                [self completeTransaction:transaction fromPaymentQueue:queue];
                break;
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStateDeferred:
                break;
        }
    }
}

///--------------------------------------
#pragma mark - PFPaymentTransactionObserver
///--------------------------------------

- (void)completeTransaction:(SKPaymentTransaction *)transaction fromPaymentQueue:(SKPaymentQueue *)queue {
    NSString *productIdentifier = transaction.payment.productIdentifier;

    @synchronized(lockObj) {
        void(^completion)(SKPaymentTransaction *) = self.blocks[productIdentifier];
        if (!transaction.error && completion) {
            completion(transaction);
        }
    }

    @synchronized(runOnceLockObj) {
        void(^runOnceBlock)(NSError *) = (void(^)(NSError *))self.runOnceBlocks[productIdentifier];
        if (runOnceBlock) {
            runOnceBlock(transaction.error);
            [self.runOnceBlocks removeObjectForKey:productIdentifier];
        }
    }

    // Calling finish:transaction here prevents the user from registering another observer to handle this transaction.
    [queue finishTransaction:transaction];
}

///--------------------------------------
#pragma mark - Public
///--------------------------------------

- (void)handle:(NSString *)productIdentifier block:(void(^)(SKPaymentTransaction *))block {
    @synchronized(lockObj) {
        self.blocks[productIdentifier] = block;
    }
}

- (void)handle:(NSString *)productIdentifier runOnceBlock:(void(^)(NSError *))block {
    @synchronized(runOnceLockObj) {
        PFConsistencyAssert(self.runOnceBlocks[productIdentifier] == nil,
                            @"You cannot purchase a product that is in the process of being purchased.");

        if (!block) {
            // Create a no-op action so that we can store it in the dictionary,
            // this is useful because we use the existence of this block to test if
            // the same product is being purchased at the time.
            block = ^(NSError *error) {
            };
        }
        self.runOnceBlocks[productIdentifier] = block;
    }
}

@end
