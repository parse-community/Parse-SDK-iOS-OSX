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

#import "PFActionButton.h"

#import "PFImage.h"
#import "PFRect.h"

static const UIEdgeInsets PFActionButtonContentEdgeInsets = { .top = 0.0f, .left = 12.0f, .bottom = 0.0f, .right = 0.0f };

@interface PFActionButton ()
{
    UIActivityIndicatorView *_activityIndicatorView;
}

@property (nonatomic, strong) PFActionButtonConfiguration *configuration;

- (instancetype)initWithCoder:(nonnull NSCoder *)decoder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;

@end

@implementation PFActionButton

#pragma mark -
#pragma mark Init

- (instancetype)initWithFrame:(CGRect)frame {
    return [super initWithFrame:frame];
}

- (instancetype)initWithCoder:(nonnull NSCoder *)decoder {
    return [super initWithCoder:decoder];
}

- (instancetype)initWithConfiguration:(PFActionButtonConfiguration *)configuration
                          buttonStyle:(PFActionButtonStyle)buttonStyle {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    _buttonStyle = buttonStyle;
    _configuration = configuration;

    self.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [UIFont systemFontOfSize:16.0f];

    self.contentEdgeInsets = UIEdgeInsetsZero;
    self.imageEdgeInsets = UIEdgeInsetsZero;

    UIImage *backgroundImage = [PFImage imageWithColor:configuration.backgroundImageColor cornerRadius:4.0f];
    [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];

    [self setImage:configuration.image forState:UIControlStateNormal];

    [self setTitle:[configuration titleForButtonStyle:buttonStyle]
          forState:UIControlStateNormal];

    return self;
}

#pragma mark -
#pragma mark Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    _activityIndicatorView.center = self.imageView.center;
    self.imageView.alpha = (self.loading ? 0.0f : 1.0f);
}

- (CGSize)sizeThatFits:(CGSize)boundingSize {
    CGSize size = CGSizeZero;
    size.width = MAX([super sizeThatFits:boundingSize].width, boundingSize.width);
    size.height = MIN(44.0f, boundingSize.height);
    return size;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    CGRect imageRect = PFRectMakeWithSize([self imageForState:UIControlStateNormal].size);
    imageRect.origin.x = PFActionButtonContentEdgeInsets.left;
    imageRect.origin.y = CGRectGetMidY(contentRect) - CGRectGetMidY(imageRect);
    return imageRect;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    contentRect.origin.x = CGRectGetMaxX([self imageRectForContentRect:contentRect]);
    contentRect.size.width = CGRectGetWidth(self.bounds) - CGRectGetMaxX([self imageRectForContentRect:contentRect]);

    CGSize size = [super titleRectForContentRect:contentRect].size;
    CGRect rect = PFRectMakeWithSizeCenteredInRect(size, contentRect);
    return rect;
}

#pragma mark -
#pragma mark Configuration

+ (UIColor *)backgroundImageColor {
    return [UIColor clearColor];
}

+ (NSString *)titleForButtonStyle:(PFActionButtonStyle)buttonStyle {
    return nil;
}

#pragma mark -
#pragma mark Accessors

- (void)setLoading:(BOOL)loading {
    if (self.loading != loading) {
        if (loading) {
            if (!_activityIndicatorView) {
                _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            }

            [_activityIndicatorView startAnimating];
            [self addSubview:_activityIndicatorView];
            [self setNeedsLayout];
        } else {
            [_activityIndicatorView stopAnimating];
            [_activityIndicatorView removeFromSuperview];
        }

        self.imageView.alpha = (loading ? 0.0f : 1.0f);
    }
}

- (BOOL)isLoading {
    return [_activityIndicatorView isAnimating];
}

- (void)setButtonStyle:(PFActionButtonStyle)buttonStyle {
    if (self.buttonStyle != buttonStyle) {
        _buttonStyle = buttonStyle;

        [self setTitle:[self.configuration titleForButtonStyle:self.buttonStyle] forState:UIControlStateNormal];
    }
}

@end

@interface PFActionButtonConfiguration () {
    NSMutableDictionary *_titlesDictionary;
}

@property (nonatomic, strong, readwrite) UIColor *backgroundImageColor;
@property (nonatomic, strong, readwrite) UIImage *image;

@end

@implementation PFActionButtonConfiguration

#pragma mark -
#pragma mark Init

- (instancetype)init {
    return [self initWithBackgroundImageColor:nil image:nil];
}

- (instancetype)initWithBackgroundImageColor:(UIColor *)backgroundImageColor
                                       image:(UIImage *)image {
    self = [super init];
    if (!self) return nil;

    _backgroundImageColor = backgroundImageColor;
    _image = image;

    return self;
}

#pragma mark -
#pragma mark Title

- (void)setTitle:(NSString *)title forButtonStyle:(PFActionButtonStyle)style {
    if (!_titlesDictionary) {
        _titlesDictionary = [NSMutableDictionary dictionaryWithCapacity:style];
    }
    _titlesDictionary[@(style)] = title;
}

- (NSString *)titleForButtonStyle:(PFActionButtonStyle)style {
    return _titlesDictionary[@(style)];
}

@end
