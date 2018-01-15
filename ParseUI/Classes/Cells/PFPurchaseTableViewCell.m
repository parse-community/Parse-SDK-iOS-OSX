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

#import "PFPurchaseTableViewCell.h"

#import "PFLocalization.h"
#import "PFRect.h"

@interface PFPurchaseTableViewCell ()

@property (nonatomic, strong) UILabel *priceLabel;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation PFPurchaseTableViewCell

#pragma mark -
#pragma mark Init

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];

        self.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.imageView.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
        self.imageView.layer.shadowRadius = 1.0f;
        self.imageView.layer.shadowOpacity = 1.0f;

        self.textLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.backgroundColor = [UIColor clearColor];
        self.detailTextLabel.numberOfLines = 2;
        self.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];

        self.priceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.priceLabel.backgroundColor = [UIColor colorWithWhite:242.0f/255.0f alpha:1.0f];
        self.priceLabel.textColor = [UIColor grayColor];
        self.priceLabel.shadowColor = [UIColor whiteColor];
        self.priceLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
        self.priceLabel.font = [UIFont boldSystemFontOfSize:12.0f];
        self.priceLabel.layer.borderColor = [UIColor grayColor].CGColor;
        self.priceLabel.layer.borderWidth = 1.0f;
        self.priceLabel.layer.cornerRadius = 3.0f;
        self.priceLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.priceLabel.numberOfLines = 0;
        [self.contentView addSubview:self.priceLabel];

        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        self.state = PFPurchaseTableViewCellStateNormal;
    }
    return self;
}
#pragma mark -
#pragma mark UIView

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGRect bounds = self.contentView.bounds;

    CGFloat iconWidth = floorf(0.8f * CGRectGetHeight(bounds));
    CGFloat iconMarginY = floorf((CGRectGetHeight(bounds) - iconWidth)/2.0f);
    CGFloat iconMarginX = iconMarginY;
    CGFloat x = iconMarginX;
    CGFloat y = iconMarginY;
    self.imageView.frame = CGRectMake(x, y, iconWidth, iconWidth);
    x += self.imageView.frame.size.width + iconMarginX;

    self.priceLabel.frame = CGRectZero; // this is necessary for sizeToFit to work correctly
    [self.priceLabel sizeToFit];
    CGFloat priceLabelRightInset = 10.0f;
    CGFloat priceLabelX = CGRectGetWidth(bounds) - CGRectGetWidth(self.priceLabel.frame) - priceLabelRightInset;
    CGFloat priceLabelY = floorf((CGRectGetHeight(self.textLabel.frame) - CGRectGetHeight(self.priceLabel.frame))/2.0f) + iconMarginY;

    self.priceLabel.frame = PFRectMakeWithOriginSize(CGPointMake(priceLabelX, priceLabelY), self.priceLabel.frame.size);

    CGFloat titleWidth = self.contentView.frame.size.width - self.imageView.frame.size.width - iconMarginX - 100.0f;
    CGFloat titleHeight = self.textLabel.frame.size.height;
    self.textLabel.frame = CGRectMake(x, y, titleWidth, titleHeight);

    CGFloat textMarginBottom = 5.0f;
    y += self.textLabel.frame.size.height + textMarginBottom;

    CGFloat detailTextLabelWidth = CGRectGetWidth(bounds) - x - 50.0f;
    self.detailTextLabel.frame = CGRectMake(x, y, detailTextLabelWidth, CGRectGetWidth(self.detailTextLabel.frame));
    self.progressView.frame = CGRectMake(x, CGRectGetHeight(bounds) - CGRectGetHeight(self.progressView.frame) - iconMarginY - 2.0f,
                                         detailTextLabelWidth, CGRectGetHeight(self.progressView.frame));
}

#pragma mark -
#pragma mark PFPurchaseTableViewCell

- (void)setState:(PFPurchaseTableViewCellState)state {
    if (self.state == state) {
        return;
    }

    _state = state;

    switch (state) {
        case PFPurchaseTableViewCellStateNormal:
        {
            self.detailTextLabel.numberOfLines = 2;
        }
            break;
        case PFPurchaseTableViewCellStateDownloading:
        {
            self.detailTextLabel.numberOfLines = 1;
            self.priceLabel.backgroundColor = [UIColor colorWithRed:132.0f/255.0f green:175.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
            NSString *downloadingText = PFLocalizedString(@"DOWNLOADING", @"DOWNLOADING");
            self.priceLabel.text = [NSString stringWithFormat:@"  %@  ", downloadingText];
            self.priceLabel.textColor = [UIColor whiteColor];
            self.priceLabel.shadowColor = [UIColor blackColor];
            self.priceLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
            [self.contentView addSubview:self.progressView];
        }
            break;
        case PFPurchaseTableViewCellStateDownloaded:
        {
            self.detailTextLabel.numberOfLines = 2;
            NSString *installedText = PFLocalizedString(@"INSTALLED", @"INSTALLED");
            self.priceLabel.text = [NSString stringWithFormat:@"  %@  ", installedText];
            self.priceLabel.textColor = [UIColor whiteColor];
            self.priceLabel.shadowColor = [UIColor blackColor];
            self.priceLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);
            self.priceLabel.backgroundColor = [UIColor colorWithRed:160.0f/255.0f green:200.0f/255.0f blue:120.0f/255.0f alpha:1.0f];
            [self.progressView removeFromSuperview];
        }
            break;
        default:
            break;
    }
    [self setNeedsLayout];
}

@end
