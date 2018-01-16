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

#import "PFPrimaryButton.h"

#import "PFImage.h"
#import "PFRect.h"

@interface PFPrimaryButton ()
{
    UIActivityIndicatorView *_activityIndicatorView;
}

- (instancetype)initWithCoder:(nonnull NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

@end

@implementation PFPrimaryButton

#pragma mark -
#pragma mark Init

- (instancetype)initWithFrame:(CGRect)frame {
    return [super initWithFrame:frame];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)decoder {
    return [super initWithCoder:decoder];
}

- (instancetype)initWithBackgroundImageColor:(UIColor *)color {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    [self setBackgroundImage:[PFImage imageWithColor:color] forState:UIControlStateNormal];

    self.titleLabel.font = [UIFont systemFontOfSize:20.0f];
    self.contentVerticalAlignment = UIControlContentHorizontalAlignmentCenter;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;

    return self;
}

#pragma mark -
#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat activityIndicatorRightInset = 12.0f;

    CGRect activityIndicatorFrame = PFRectMakeWithSizeCenteredInRect(_activityIndicatorView.bounds.size, self.bounds);
    activityIndicatorFrame.origin.x = (CGRectGetMinX(self.titleLabel.frame)
                                       - CGRectGetWidth(activityIndicatorFrame)
                                       - activityIndicatorRightInset);
    _activityIndicatorView.frame = activityIndicatorFrame;
}

- (CGSize)sizeThatFits:(CGSize)boundingSize {
    CGSize size = CGSizeZero;
    size.width = boundingSize.width;
    size.height = MIN(56.0f, boundingSize.height);
    return size;
}

#pragma mark -
#pragma mark Accessors

- (void)setLoading:(BOOL)loading {
    if (self.loading != loading) {
        if (loading) {
            if (!_activityIndicatorView) {
                _activityIndicatorView = [[UIActivityIndicatorView alloc]
                                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            }

            [_activityIndicatorView startAnimating];
            [self addSubview:_activityIndicatorView];
            [self setNeedsLayout];
        } else {
            [_activityIndicatorView stopAnimating];
            [_activityIndicatorView removeFromSuperview];
        }
    }
}

- (BOOL)isLoading {
    return [_activityIndicatorView isAnimating];
}

@end
