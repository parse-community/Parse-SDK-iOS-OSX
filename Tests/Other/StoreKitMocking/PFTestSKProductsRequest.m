/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestSKProductsRequest.h"

#import "PFTestSKProductsResponse.h"

@interface PFTestSKProductsRequest ()

@property (nonatomic, copy) NSSet *productIdentifiers;

@end

@implementation PFTestSKProductsRequest

static NSSet *_validProducts;

///--------------------------------------
#pragma mark - Class
///--------------------------------------

+ (void)setValidProducts:(NSSet *)products {
    _validProducts = products;
}

///--------------------------------------
#pragma mark - SKProductsRequest
///--------------------------------------

- (instancetype)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    self = [super init];
    if (!self) return nil;

    _productIdentifiers = [productIdentifiers copy];

    return self;
}

- (void)start {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(SKProduct *evaluatedObject,
                                                                             NSDictionary *bindings) {
            return [_productIdentifiers containsObject:evaluatedObject.productIdentifier];
        }];
        NSSet *validProducts = [_validProducts filteredSetUsingPredicate:filterPredicate];

        NSMutableSet *invalidProductIdentifiers = [_productIdentifiers mutableCopy];
        [invalidProductIdentifiers minusSet:[_validProducts valueForKey:@"productIdentifier"]];

        PFTestSKProductsResponse *response = [[PFTestSKProductsResponse alloc] initWithProducts:[validProducts allObjects]
                                                                      invalidProductIdentifiers:[invalidProductIdentifiers allObjects]];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate productsRequest:self didReceiveResponse:response];
            [self.delegate requestDidFinish:self];
        });
    });
}

- (void)cancel {
}

@end
