/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFOAuth1FlowDialog.h"

#import <Parse/PFNetworkActivityIndicatorManager.h>

@implementation PFOAuth1FlowDialog

@synthesize dataSource = _dataSource;
@synthesize completion = _completion;

@synthesize queryParameters = _queryParameters;
@synthesize redirectURLPrefix = _redirectURLPrefix;

static NSString *const PFOAuth1FlowDialogDefaultTitle = @"Connect to Service";

static const CGFloat PFOAuth1FlowDialogBorderGreyColorComponents[4] = {0.3f, 0.3f, 0.3f, 0.8f};
static const CGFloat PFOAuth1FlowDialogBorderBlackColorComponents[4] = {0.3f, 0.3f, 0.3f, 1.0f};

static const NSTimeInterval PFOAuth1FlowDialogAnimationDuration = 0.3;

static const UIEdgeInsets PFOAuth1FlowDialogContentInsets = {
    .top = 10.0f,
    .left = 10.0f,
    .bottom = 10.0f,
    .right = 10.0f,
};

static const UIEdgeInsets PFOAuth1FlowDialogTitleInsets = {.top = 4.0f, .left = 8.0f, .bottom = 4.0f, .right = 8.0f};

static const CGFloat PFOAuth1FlowDialogScreenInset = 10.0f;

static BOOL PFOAuth1FlowDialogScreenHasAutomaticRotation() {
    static BOOL automaticRotation;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        automaticRotation = [[UIScreen mainScreen] respondsToSelector:NSSelectorFromString(@"coordinateSpace")];
    });
    return automaticRotation;
}

static BOOL PFOAuth1FlowDialogIsDevicePad() {
    static BOOL isPad;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    });
    return isPad;
}

static CGFloat PFTFloatRound(CGFloat value, NSRoundingMode mode) {
    switch (mode) {
        case NSRoundPlain:
        case NSRoundBankers:
#if CGFLOAT_IS_DOUBLE
            value = round(value);
#else
            value = roundf(value);
#endif
        case NSRoundDown:
#if CGFLOAT_IS_DOUBLE
            value = floor(value);
#else
            value = floorf(value);
#endif
        case NSRoundUp:
#if CGFLOAT_IS_DOUBLE
            value = ceil(value);
#else
            value = ceilf(value);
#endif
        default: break;
    }
    return value;
}

#pragma mark -
#pragma mark Class

+ (void)_fillRect:(CGRect)rect withColorComponents:(const CGFloat *)colorComponents radius:(CGFloat)radius {
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (colorComponents) {
        CGContextSaveGState(context);
        CGContextSetFillColor(context, colorComponents);
        if (radius != 0.0f) {
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
            CGContextAddPath(context, [bezierPath CGPath]);
            CGContextFillPath(context);
        } else {
            CGContextFillRect(context, rect);
        }
        CGContextRestoreGState(context);
    }
}

+ (void)_strokeRect:(CGRect)rect withColorComponents:(const CGFloat *)strokeColor {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    {
        CGContextSetStrokeColor(context, strokeColor);
        CGContextSetLineWidth(context, 1.0f);
        CGContextStrokeRect(context, rect);
    }
    CGContextRestoreGState(context);
}

+ (NSURL *)_urlFromBaseURL:(NSURL *)baseURL queryParameters:(NSDictionary *)params {
    if ([params count] > 0) {
        NSMutableArray *parameterPairs = [NSMutableArray array];
        [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            CFStringRef escapedString = CFURLCreateStringByAddingPercentEscapes(
                                                                                NULL, /* allocator */
                                                                                (CFStringRef)obj,
                                                                                NULL, /* charactersToLeaveUnescaped */
                                                                                (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                kCFStringEncodingUTF8);
            [parameterPairs addObject:[NSString stringWithFormat:@"%@=%@", key, CFBridgingRelease(escapedString)]];
        }];

        NSString *query = [parameterPairs componentsJoinedByString:@"&"];
        NSString *url = [NSString stringWithFormat:@"%@?%@", [baseURL absoluteString], query];

        return [NSURL URLWithString:url];
    }

    return baseURL;
}

+ (UIImage *)_closeButtonImage {
    CGRect imageRect = CGRectZero;
    imageRect.size = CGSizeMake(30.0f, 30.0f);

    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect outerRingRect = CGRectInset(imageRect, 2.0f, 2.0f);

    [[UIColor whiteColor] set];
    CGContextFillEllipseInRect(context, outerRingRect);

    CGRect innerRingRect = CGRectInset(outerRingRect, 2.0f, 2.0f);

    [[UIColor blackColor] set];
    CGContextFillEllipseInRect(context, innerRingRect);

    CGRect crossRect = CGRectInset(innerRingRect, 6.0f, 6.0f);

    CGContextBeginPath(context);

    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(context, 3.0f);

    CGContextMoveToPoint(context, CGRectGetMinX(crossRect), CGRectGetMinY(crossRect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(crossRect), CGRectGetMaxY(crossRect));

    CGContextMoveToPoint(context, CGRectGetMaxX(crossRect), CGRectGetMinY(crossRect));
    CGContextAddLineToPoint(context, CGRectGetMinX(crossRect), CGRectGetMaxY(crossRect));

    CGContextStrokePath(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

#pragma mark -
#pragma mark Init

- (instancetype)init {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizesSubviews = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.contentMode = UIViewContentModeRedraw;

        _orientation = UIInterfaceOrientationPortrait;

        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.showsTouchWhenHighlighted = YES;
        _closeButton.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin);
        [_closeButton setImage:[[self class] _closeButtonImage] forState:UIControlStateNormal];
        [_closeButton addTarget:self
                         action:@selector(_cancelButtonAction)
               forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_closeButton];

        CGFloat titleLabelFontSize = (PFOAuth1FlowDialogIsDevicePad() ? 18.0f : 14.0f);
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.text = PFOAuth1FlowDialogDefaultTitle;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:titleLabelFontSize];
        [self addSubview:_titleLabel];

        _webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.delegate = self;
        [self addSubview:_webView];

        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                              UIActivityIndicatorViewStyleWhiteLarge];
        _activityIndicator.color = [UIColor grayColor];
        _activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin |
                                               UIViewAutoresizingFlexibleBottomMargin |
                                               UIViewAutoresizingFlexibleLeftMargin |
                                               UIViewAutoresizingFlexibleRightMargin);
        [self addSubview:_activityIndicator];

        _modalBackgroundView = [[UIView alloc] init];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url queryParameters:(NSDictionary *)parameters {
    self = [self init];
    if (self) {
        _baseURL = url;
        _queryParameters = [parameters mutableCopy];
    }
    return self;
}

+ (instancetype)dialogWithURL:(NSURL *)url queryParameters:(NSDictionary *)queryParameters {
    return [[self alloc] initWithURL:url queryParameters:queryParameters];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    _webView.delegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark UIView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    [[self class] _fillRect:self.bounds withColorComponents:PFOAuth1FlowDialogBorderGreyColorComponents radius:10.0f];
    [[self class] _strokeRect:_webView.frame withColorComponents:PFOAuth1FlowDialogBorderBlackColorComponents];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGRect bounds = self.bounds;
    const CGRect contentRect = UIEdgeInsetsInsetRect(bounds, PFOAuth1FlowDialogContentInsets);

    CGRect titleLabelBoundingRect = UIEdgeInsetsInsetRect(contentRect, PFOAuth1FlowDialogTitleInsets);
    CGSize titleLabelSize = [_titleLabel sizeThatFits:titleLabelBoundingRect.size];
    titleLabelBoundingRect.size.width = (CGRectGetMaxX(contentRect) -
                                         PFOAuth1FlowDialogTitleInsets.right -
                                         titleLabelSize.height);
    titleLabelSize = [_titleLabel sizeThatFits:titleLabelBoundingRect.size];

    CGRect titleLabelFrame = titleLabelBoundingRect;
    titleLabelFrame.size.height = titleLabelSize.height;
    titleLabelFrame.size.width = CGRectGetWidth(titleLabelBoundingRect);
    _titleLabel.frame = titleLabelFrame;

    CGRect closeButtonFrame = contentRect;
    closeButtonFrame.size.height = (CGRectGetHeight(titleLabelFrame) +
                                    PFOAuth1FlowDialogTitleInsets.top +
                                    PFOAuth1FlowDialogTitleInsets.bottom);
    closeButtonFrame.size.width = CGRectGetHeight(closeButtonFrame);
    closeButtonFrame.origin.x = CGRectGetMaxX(contentRect) - CGRectGetWidth(closeButtonFrame);
    _closeButton.frame = closeButtonFrame;

    CGRect webViewFrame = contentRect;
    if (!_showingKeyboard || PFOAuth1FlowDialogIsDevicePad() || UIInterfaceOrientationIsPortrait(_orientation)) {
        webViewFrame.origin.y = CGRectGetMaxY(titleLabelFrame) + PFOAuth1FlowDialogTitleInsets.bottom;
        webViewFrame.size.height = CGRectGetMaxY(contentRect) - CGRectGetMinY(webViewFrame);
    }
    _webView.frame = webViewFrame;

    [_activityIndicator sizeToFit];
    _activityIndicator.center = _webView.center;
}

#pragma mark -
#pragma mark Accessors

- (NSString *)title {
    return _titleLabel.text;
}

- (void)setTitle:(NSString *)title {
    _titleLabel.text = title;

    [self setNeedsLayout];
}

#pragma mark -
#pragma mark Present / Dismiss

- (void)showAnimated:(BOOL)animated {
    [self load];
    [self _sizeToFitOrientation];

    [_activityIndicator startAnimating];

    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    _modalBackgroundView.frame = window.bounds;
    [_modalBackgroundView addSubview:self];
    [window addSubview:_modalBackgroundView];

    CGAffineTransform transform = [self _transformForOrientation:_orientation];
    if (animated) {
        self.transform = CGAffineTransformScale(transform, 0.001f, 0.001f);

        NSTimeInterval animationStepDuration = PFOAuth1FlowDialogAnimationDuration / 2.0f;

        [UIView animateWithDuration:animationStepDuration
                         animations:^{
                             self.transform = CGAffineTransformScale(transform, 1.1f, 1.1f);
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:animationStepDuration
                                              animations:^{
                                                  self.transform = CGAffineTransformScale(transform, 0.9f, 0.9f);
                                              }
                                              completion:^(BOOL finished) {
                                                  [UIView animateWithDuration:animationStepDuration
                                                                   animations:^{
                                                                       self.transform = transform;
                                                                   }];
                                              }];

                         }];
    } else {
        self.transform = transform;
    }

    [self _addObservers];
}

- (void)dismissAnimated:(BOOL)animated {
    _loadingURL = nil;

    __weak typeof(self) wself = self;
    dispatch_block_t completionBlock = ^{
        __strong typeof(wself) sself = wself;
        [sself _removeObservers];
        [sself removeFromSuperview];
        [sself->_modalBackgroundView removeFromSuperview];
    };

    if (animated) {
        [UIView animateWithDuration:PFOAuth1FlowDialogAnimationDuration
                         animations:^{
                             typeof(wself) sself = wself;
                             sself.alpha = 0.0f;
                         }
                         completion:^(BOOL finished) {
                             completionBlock();
                         }];
    } else {
        completionBlock();
    }
}

- (void)_dismissWithSuccess:(BOOL)success url:(NSURL *)url error:(NSError *)error {
    if (!self.completion) {
        return;
    }

    PFOAuth1FlowDialogCompletion completion = self.completion;
    self.completion = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        completion(success, url, error);
    });

    [self dismissAnimated:YES];
}

- (void)_cancelButtonAction {
    [self _dismissWithSuccess:NO url:nil error:nil];
}

#pragma mark -
#pragma mark Public

- (void)load {
    [self loadURL:_baseURL queryParameters:self.queryParameters];
}

- (void)loadURL:(NSURL *)url queryParameters:(NSDictionary *)parameters {
    _loadingURL = [[self class] _urlFromBaseURL:url queryParameters:parameters];

    NSURLRequest *request = [NSURLRequest requestWithURL:_loadingURL];
    [_webView loadRequest:request];
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    NSURL *url = request.URL;

    if ([url.absoluteString hasPrefix:self.redirectURLPrefix]) {
        [self _dismissWithSuccess:YES url:url error:nil];
        return NO;
    } else if ([_loadingURL isEqual:url]) {
        return YES;
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        if ([self.dataSource dialog:self shouldOpenURLInExternalBrowser:url]) {
            [[UIApplication sharedApplication] openURL:url];
        } else {
            return YES;
        }
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[PFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[PFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];

    [_activityIndicator stopAnimating];
    self.title = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[PFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];

    // 102 == WebKitErrorFrameLoadInterruptedByPolicyChange
    if (!([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)) {
        [self _dismissWithSuccess:NO url:nil error:error];
    }
}

#pragma mark -
#pragma mark Observers

- (void)_addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_deviceOrientationDidChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)_removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

#pragma mark -
#pragma mark UIDeviceOrientationDidChangeNotification

- (void)_deviceOrientationDidChange:(NSNotification *)notification {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if ([self _shouldRotateToOrientation:orientation]) {
        NSTimeInterval duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        [UIView animateWithDuration:duration
                         animations:^{
                             [self _sizeToFitOrientation];
                         }];
    }
}

- (BOOL)_shouldRotateToOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == _orientation) {
        return NO;
    }

    return (orientation == UIDeviceOrientationLandscapeLeft ||
            orientation == UIDeviceOrientationLandscapeRight ||
            orientation == UIDeviceOrientationPortrait ||
            orientation == UIDeviceOrientationPortraitUpsideDown);
}

- (CGAffineTransform)_transformForOrientation:(UIInterfaceOrientation)orientation {
    // No manual rotation required on iOS 8
    // There is coordinateSpace method, since iOS 8
    if (PFOAuth1FlowDialogScreenHasAutomaticRotation()) {
        return CGAffineTransformIdentity;
    }

    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft:
            return CGAffineTransformMakeRotation((CGFloat)(-M_PI / 2.0f));
            break;
        case UIInterfaceOrientationLandscapeRight:
            return CGAffineTransformMakeRotation((CGFloat)(M_PI / 2.0f));
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            return CGAffineTransformMakeRotation((CGFloat)-M_PI);
            break;
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
        default:
            break;
    }

    return CGAffineTransformIdentity;
}

- (void)_sizeToFitOrientation {
    _orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGAffineTransform transform = [self _transformForOrientation:_orientation];

    CGRect bounds = [UIScreen mainScreen].applicationFrame;
    CGRect transformedBounds = CGRectApplyAffineTransform(bounds, transform);
    transformedBounds.origin = CGPointZero;

    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));

    CGFloat scale = (PFOAuth1FlowDialogIsDevicePad() ? 0.6f : 1.0f);

    CGFloat width = PFTFloatRound((scale * CGRectGetWidth(transformedBounds)) - PFOAuth1FlowDialogScreenInset * 2.0f, NSRoundDown);
    CGFloat height = PFTFloatRound((scale * CGRectGetHeight(transformedBounds)) - PFOAuth1FlowDialogScreenInset * 2.0f, NSRoundDown);

    self.transform = transform;
    self.center = center;
    self.bounds = CGRectMake(0.0f, 0.0f, width, height);

    [self setNeedsLayout];
}

#pragma mark -
#pragma mark UIKeyboardNotifications

- (void)_keyboardWillShow:(NSNotification *)notification {
    _showingKeyboard = YES;

    if (PFOAuth1FlowDialogIsDevicePad()) {
        // On the iPad the screen is large enough that we don't need to
        // resize the dialog to accomodate the keyboard popping up
        return;
    }

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        NSDictionary *userInfo = [notification userInfo];
        NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationCurve animationCurve = [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] intValue];

        [UIView animateWithDuration:animationDuration
                              delay:0.0
                            options:animationCurve << 16 | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self setNeedsLayout];
                             [self layoutIfNeeded];

                             [self setNeedsDisplay];
                         }
                         completion:nil];
    }
}

- (void)_keyboardWillHide:(NSNotification *)notification {
    _showingKeyboard = NO;

    if (PFOAuth1FlowDialogIsDevicePad()) {
        return;
    }
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        NSDictionary *userInfo = [notification userInfo];
        NSTimeInterval animationDuration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationCurve animationCurve = [[notification userInfo][UIKeyboardAnimationCurveUserInfoKey] intValue];

        [UIView animateWithDuration:animationDuration
                              delay:0.0
                            options:animationCurve << 16 | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [self setNeedsLayout];
                             [self layoutIfNeeded];

                             [self setNeedsDisplay];
                         }
                         completion:nil];
    }
}

@end
