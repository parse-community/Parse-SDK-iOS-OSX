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

#import "PFTableViewCell.h"

#import "PFRect.h"

@interface PFTableViewCell ()

@property (nonatomic, assign) UITableViewCellStyle style;
@property (nonatomic, strong) PFImageView *customImageView;

@end

@implementation PFTableViewCell

#pragma mark -
#pragma mark NSObject

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _style = style;

        _customImageView = [[PFImageView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_customImageView];
    }
    return self;
}

#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
    [super layoutSubviews];

    // We cannot depend on the parent class to lay out things perfectly because
    // UITableViewCell layoutSubviews use its internal imageView member rather than via
    // its self.imageView property, so we need to lay out things manually

    // Don't relayout anything if there is no file/image
    if (!self.imageView.file && !self.imageView.image) {
        return;
    }

    // Value2 ignores imageView entirely
    if (self.style == UITableViewCellStyleValue2) {
        return;
    }

    const CGRect bounds = self.contentView.bounds;

    CGFloat imageHeight = MIN(CGRectGetWidth(bounds), CGRectGetHeight(bounds));
    CGFloat imageWidth = floorf(13.0f * imageHeight / 9.0f); // Default is 13/9 aspect ratio
    _customImageView.frame = PFRectMakeWithSize(CGSizeMake(imageWidth, imageHeight));

    CGFloat imageViewRightInset = 10.0f;
    CGFloat textOrigin = CGRectGetMaxX(_customImageView.frame) + imageViewRightInset;

    CGRect textLabelFrame = self.textLabel.frame;
    CGRect detailTextLabelFrame = self.detailTextLabel.frame;

    switch (self.style) {
        case UITableViewCellStyleDefault:
        case UITableViewCellStyleSubtitle:
        {
            CGFloat originalTextLabelInset = CGRectGetMinX(textLabelFrame);
            CGFloat originalDetailTextLabelInset = CGRectGetMinX(detailTextLabelFrame);

            CGFloat maxTextLabelWidth = CGRectGetMaxX(bounds) - textOrigin - originalTextLabelInset;
            CGFloat maxDetailTextLabelWidth = CGRectGetMaxX(bounds) - textOrigin - originalDetailTextLabelInset;

            textLabelFrame.origin.x = textOrigin;
            textLabelFrame.size.width = MIN(maxTextLabelWidth, CGRectGetWidth(textLabelFrame));

            detailTextLabelFrame.origin.x = textOrigin;
            detailTextLabelFrame.size.width = MIN(maxDetailTextLabelWidth, CGRectGetWidth(detailTextLabelFrame));
        }
            break;
        case UITableViewCellStyleValue1:
        {
            CGFloat maxTextLabelWidth = CGRectGetMinX(detailTextLabelFrame) - textOrigin;

            textLabelFrame.origin.x = textOrigin;
            textLabelFrame.size.width = MIN(maxTextLabelWidth, CGRectGetWidth(textLabelFrame));
        }
            break;
        default:
            break;
    }
    self.textLabel.frame = textLabelFrame;
    self.detailTextLabel.frame = detailTextLabelFrame;
}

#pragma mark -
#pragma mark PFImageTableViewCell

- (PFImageView *)imageView {
    return _customImageView;
}

@end
