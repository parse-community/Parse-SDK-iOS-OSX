/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFTestSKProduct.h"

@interface PFTestSKProduct ()

@property (nonatomic, copy) NSString *productIdentifier;
@property (nonatomic, strong) NSDecimalNumber *price;
@property (nonatomic, copy) NSString *localizedTitle;
@property (nonatomic, copy) NSString *localizedDescription;

@end

@implementation PFTestSKProduct

@synthesize productIdentifier = _productIdentifier;
@synthesize price = _price;
@synthesize localizedTitle = _localizedTitle;
@synthesize localizedDescription = _localizedDescription;

+ (instancetype)productWithProductIdentifier:(NSString *)productIdentifier
                                       price:(NSDecimalNumber *)price
                                       title:(NSString *)title
                                 description:(NSString *)description {
    PFTestSKProduct *product = [[self alloc] init];
    product.productIdentifier = [productIdentifier copy];
    product.price = price;
    product.localizedTitle = title;
    product.localizedDescription = description;
    return product;
}

@end
