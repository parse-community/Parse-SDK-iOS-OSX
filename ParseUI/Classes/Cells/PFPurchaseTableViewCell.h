/*
 *  Copyright (c) 2014, Parse, LLC. All rights reserved.
 *
 *  You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
 *  copy, modify, and distribute this software in source code or binary form for use
 *  in connection with the web services and APIs provided by Parse.
 *
 *  As with any software that integrates with the Parse platform, your use of
 *  this software is subject to the Parse Terms of Service
 *  [https://www.parse.com/about/terms]. This copyright notice shall be
 *  included in all copies or substantial portions of the software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 *  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 *  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 *  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

#import <UIKit/UIKit.h>

#ifdef COCOAPODS
#import "ParseUIConstants.h"
#import "PFTableViewCell.h"
#else
#import <ParseUI/ParseUIConstants.h>
#import <ParseUI/PFTableViewCell.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 An enum that represents states of the `PFPurchaseTableViewCell`.
 @see `PFPurchaseTableViewCell`
 */
typedef NS_ENUM(uint8_t, PFPurchaseTableViewCellState) {
    /** Normal state of the cell. */
    PFPurchaseTableViewCellStateNormal = 0,
    /** Downloading state of the cell. */
    PFPurchaseTableViewCellStateDownloading,
    /** State of the cell, when the product was downloaded. */
    PFPurchaseTableViewCellStateDownloaded
};

/**
 `PFPurchaseTableViewCell` is a subclass `PFTableViewCell` that is used to show
 products in a `PFProductTableViewController`.

 @see `PFProductTableViewController`
 */
@interface PFPurchaseTableViewCell : PFTableViewCell

/**
 State of the cell.
 @see `PFPurchaseTableViewCellState`
 */
@property (nonatomic, assign) PFPurchaseTableViewCellState state;

/**
 Label where price of the product is displayed.
 */
@property (nullable, nonatomic, strong, readonly) UILabel *priceLabel;

/**
 Progress view that is shown, when the product is downloading.
 */
@property (nullable, nonatomic, strong, readonly) UIProgressView *progressView;

@end

NS_ASSUME_NONNULL_END
