/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFProduct.h"

typedef enum {
    PFProductDownloadStateStart,
    PFProductDownloadStateDownloading,
    PFProductDownloadStateDownloaded
} PFProductDownloadState;

@interface PFProduct () {
    NSDecimalNumber *price;
    NSLocale *priceLocale;
    NSInteger progress;
    NSString *contentPath;
}

/// The properties below are transient properties, not stored on Parse's server.
/*!
 The price of the product, discovered via iTunes Connect.
 */
@property (nonatomic, strong) NSDecimalNumber *price;

/*!
 The price locale of the product.
 */
@property (nonatomic, strong) NSLocale *priceLocale;

/*!
 The progress of the download, if one is in progress. It's an integer between 0 and 100.
 */
@property (nonatomic, assign) NSInteger progress;

/*!
 The content path of the download.
 */
@property (nonatomic, strong) NSString *contentPath;

@end
