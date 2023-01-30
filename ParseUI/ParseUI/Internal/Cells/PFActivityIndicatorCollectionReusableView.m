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

#import "PFActivityIndicatorCollectionReusableView.h"

#import "PFRect.h"

@interface PFActivityIndicatorCollectionReusableView () {
    UIActivityIndicatorView *_activityIndicator;
    UIButton *_actionButton;
}

@end

@implementation PFActivityIndicatorCollectionReusableView

#pragma mark -
#pragma mark Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _actionButton.backgroundColor = self.backgroundColor;
    [self addSubview:_actionButton];

    _textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _textLabel.numberOfLines = 0;
    _textLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_textLabel];

    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator.hidesWhenStopped = YES;
    [self addSubview:_activityIndicator];

    return self;
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    [self removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
}

#pragma mark -
#pragma mark UIView

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    _actionButton.backgroundColor = backgroundColor;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGRect bounds = self.bounds;

    _actionButton.frame = bounds;

    _textLabel.frame = PFRectMakeWithSizeCenteredInRect([_textLabel sizeThatFits:bounds.size], bounds);
    _activityIndicator.frame = PFRectMakeWithSizeCenteredInRect([_activityIndicator sizeThatFits:bounds.size], bounds);
}

#pragma mark -
#pragma mark Accessors

- (void)setAnimating:(BOOL)animating {
    if (self.animating != animating) {

        if (animating) {
            [_activityIndicator startAnimating];
            _textLabel.alpha = 0.0f;
        } else {
            [_activityIndicator stopAnimating];
            _textLabel.alpha = 1.0f;
        }
    }
}

- (BOOL)isAnimating {
    return [_activityIndicator isAnimating];
}

#pragma mark -
#pragma mark Actions

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    [_actionButton addTarget:target action:action forControlEvents:controlEvents];
}

- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    [_actionButton removeTarget:target action:action forControlEvents:controlEvents];
}

@end
