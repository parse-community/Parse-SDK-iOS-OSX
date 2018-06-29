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
#else
#import <ParseUI/ParseUIConstants.h>
#endif


NS_ASSUME_NONNULL_BEGIN

@class PFImageView;
@class PFObject;

/**
 The `PFCollectionViewCell` class represents a collection view cell which can
 download and display remote images stored on Parse as well as has a default simple text label.
 */
@interface PFCollectionViewCell : UICollectionViewCell

/**
 A simple lazy-loaded label for the collection view cell.
 */
@property (nonatomic, strong, readonly) UILabel *textLabel;

/**
 The lazy-loaded imageView of the collection view cell.

 @see PFImageView
 */
@property (nonatomic, strong, readonly) PFImageView *imageView;

/**
 This method should update all the relevant information inside a subclass of `PFCollectionViewCell`.

 This method is automatically called by `PFQueryCollectionViewController` whenever the cell
 should display new information. By default this method does nothing.

 @param object An instance of `PFObject` to update from.
 */
- (void)updateFromObject:(nullable PFObject *)object;

@end

NS_ASSUME_NONNULL_END
