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

#import "PFLogInView.h"

#import "PFActionButton.h"
#import "PFColor.h"
#import "PFDismissButton.h"
#import "PFImage.h"
#import "PFLocalization.h"
#import "PFPrimaryButton.h"
#import "PFRect.h"
#import "PFTextButton.h"
#import "PFTextField.h"

static NSString *const PFLogInViewDefaultLogoImageName = @"parse_logo.png";
static NSString *const PFLogInViewDefaultFacebookButtonImageName = @"facebook_icon.png";
static NSString *const PFLogInViewDefaultTwitterButtonImageName = @"twitter_icon.png";

///--------------------------------------
#pragma mark - Accessibility Identifiers
///--------------------------------------

NSString *const PFLogInViewUsernameFieldAccessibilityIdentifier = @"PFLogInViewUsernameFieldAccessibilityIdentifier";
NSString *const PFLogInViewPasswordFieldAccessibilityIdentifier = @"PFLogInViewPasswordFieldAccessibilityIdentifier";
NSString *const PFLogInViewLogInButtonAccessibilityIdentifier = @"PFLogInViewLogInButtonAccessibilityIdentifier";
NSString *const PFLogInViewSignUpButtonAccessibilityIdentifier = @"PFLogInViewSignUpButtonAccessibilityIdentifier";
NSString *const PFLogInViewPasswordForgottenButtonAccessibilityIdentifier = @"PFLogInViewPasswordForgottenButtonAccessibilityIdentifier";
NSString *const PFLogInViewTwitterButtonAccessibilityIdentifier = @"PFLogInViewTwitterButtonAccessibilityIdentifier";
NSString *const PFLogInViewFacebookButtonAccessibilityIdentifier = @"PFLogInViewFacebookButtonAccessibilityIdentifier";
NSString *const PFLogInViewDismissButtonAccessibilityIdentifier = @"PFLogInViewDismissButtonAccessibilityIdentifier";

@implementation PFLogInView

///--------------------------------------
#pragma mark - Class
///--------------------------------------

+ (PFActionButtonConfiguration *)_defaultSignUpButtonConfiguration {
    PFActionButtonConfiguration *configuration = [[PFActionButtonConfiguration alloc] initWithBackgroundImageColor:[PFColor signupButtonBackgroundColor]
                                                                                                             image:nil];
    NSString *title = PFLocalizedString(@"Sign Up", @"Sign Up");
    [configuration setTitle:title forButtonStyle:PFActionButtonStyleNormal];
    [configuration setTitle:title forButtonStyle:PFActionButtonStyleWide];

    return configuration;
}

+ (PFActionButtonConfiguration *)_defaultFacebookButtonConfiguration {
    PFActionButtonConfiguration *configuration = [[PFActionButtonConfiguration alloc] initWithBackgroundImageColor:[PFColor facebookButtonBackgroundColor]
                                                                                                             image:[PFImage imageNamed:PFLogInViewDefaultFacebookButtonImageName]];

    [configuration setTitle:PFLocalizedString(@"Facebook", @"Facebook")
             forButtonStyle:PFActionButtonStyleNormal];
    [configuration setTitle:PFLocalizedString(@"Log In with Facebook", @"Log In with Facebook")

             forButtonStyle:PFActionButtonStyleWide];

    return configuration;
}

+ (PFActionButtonConfiguration *)_defaultTwitterButtonConfiguration {
    PFActionButtonConfiguration *configuration = [[PFActionButtonConfiguration alloc] initWithBackgroundImageColor:[PFColor twitterButtonBackgroundColor]
                                                                                                             image:[PFImage imageNamed:PFLogInViewDefaultTwitterButtonImageName]];

    [configuration setTitle:PFLocalizedString(@"Twitter", @"Twitter")
             forButtonStyle:PFActionButtonStyleNormal];
    [configuration setTitle:PFLocalizedString(@"Log In with Twitter", @"Log In with Twitter")

             forButtonStyle:PFActionButtonStyleWide];

    return configuration;
}

///--------------------------------------
#pragma mark - Init
///--------------------------------------

- (instancetype)initWithFields:(PFLogInFields)otherFields {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;

    [PFLogInView _validateFields:otherFields];

    self.opaque = YES;
    self.backgroundColor = [PFColor commonBackgroundColor];

    _fields = otherFields;

    _logo = [[UIImageView alloc] initWithImage:[PFImage imageNamed:PFLogInViewDefaultLogoImageName]];
    _logo.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_logo];

    [self _updateAllFields];

    return self;
}

///--------------------------------------
#pragma mark - Fields
///--------------------------------------

- (void)_updateAllFields {
    if (_fields & PFLogInFieldsDismissButton) {
        if (!_dismissButton) {
            _dismissButton = [[PFDismissButton alloc] initWithFrame:CGRectZero];
            _dismissButton.accessibilityIdentifier = PFLogInViewDismissButtonAccessibilityIdentifier;
            [self addSubview:_dismissButton];
        }
    } else {
        [_dismissButton removeFromSuperview];
        _dismissButton = nil;
    }

    if (_fields & PFLogInFieldsUsernameAndPassword) {
        if (!_usernameField) {
            _usernameField = [[PFTextField alloc] initWithFrame:CGRectZero
                                                 separatorStyle:(PFTextFieldSeparatorStyleTop |
                                                                 PFTextFieldSeparatorStyleBottom)];
            _usernameField.accessibilityIdentifier = PFLogInViewUsernameFieldAccessibilityIdentifier;
            _usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
            _usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            _usernameField.returnKeyType = UIReturnKeyNext;
            [self addSubview:_usernameField];
            [self _updateUsernameFieldStyle];
        }

        if (!_passwordField) {
            _passwordField = [[PFTextField alloc] initWithFrame:CGRectZero
                                                 separatorStyle:PFTextFieldSeparatorStyleBottom];
            _passwordField.accessibilityIdentifier = PFLogInViewPasswordFieldAccessibilityIdentifier;
            _passwordField.placeholder = PFLocalizedString(@"Password", @"Password");
            _passwordField.secureTextEntry = YES;
            _passwordField.autocorrectionType = UITextAutocorrectionTypeNo;
            _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            _passwordField.returnKeyType = UIReturnKeyDone;
            [self addSubview:_passwordField];
        }
    } else {
        [_usernameField removeFromSuperview];
        _usernameField = nil;

        [_passwordField removeFromSuperview];
        _passwordField = nil;
    }

    if (_fields & PFLogInFieldsSignUpButton) {
        if (!_signUpButton) {
            _signUpButton = [[PFActionButton alloc] initWithConfiguration:[[self class] _defaultSignUpButtonConfiguration]
                                                              buttonStyle:PFActionButtonStyleNormal];
            _signUpButton.accessibilityIdentifier = PFLogInViewSignUpButtonAccessibilityIdentifier;
            [self addSubview:_signUpButton];
        }
    } else {
        [_signUpButton removeFromSuperview];
        _signUpButton = nil;
    }

    if (_fields & PFLogInFieldsPasswordForgotten) {
        if (!_passwordForgottenButton) {
            _passwordForgottenButton = [[PFTextButton alloc] initWithFrame:CGRectZero];
            _passwordForgottenButton.accessibilityIdentifier = PFLogInViewPasswordForgottenButtonAccessibilityIdentifier;
            [_passwordForgottenButton setTitle:PFLocalizedString(@"Forgot Password?", "Forgot Password?")
                                      forState:UIControlStateNormal];
            [self addSubview:_passwordForgottenButton];
        }
    } else {
        [_passwordForgottenButton removeFromSuperview];
        _passwordForgottenButton = nil;
    }

    if (_fields & PFLogInFieldsLogInButton) {
        if (!_logInButton) {
            _logInButton = [[PFPrimaryButton alloc] initWithBackgroundImageColor:[PFColor loginButtonBackgroundColor]];
            _logInButton.accessibilityIdentifier = PFLogInViewLogInButtonAccessibilityIdentifier;
            [_logInButton setTitle:PFLocalizedString(@"Log In", @"Log In") forState:UIControlStateNormal];
            [self addSubview:_logInButton];
        }
    } else {
        [_logInButton removeFromSuperview];
        _logInButton = nil;
    }

    if (_fields & PFLogInFieldsFacebook) {
        if (!_facebookButton) {
            _facebookButton = [[PFActionButton alloc] initWithConfiguration:[[self class] _defaultFacebookButtonConfiguration]
                                                                buttonStyle:PFActionButtonStyleNormal];
            _facebookButton.accessibilityIdentifier = PFLogInViewFacebookButtonAccessibilityIdentifier;
            [self addSubview:_facebookButton];
        }
    } else {
        [_facebookButton removeFromSuperview];
        _facebookButton = nil;
    }

    if (_fields & PFLogInFieldsTwitter) {
        if (!_twitterButton) {
            _twitterButton = [[PFActionButton alloc] initWithConfiguration:[[self class] _defaultTwitterButtonConfiguration]
                                                               buttonStyle:PFActionButtonStyleNormal];
            _twitterButton.accessibilityIdentifier = PFLogInViewTwitterButtonAccessibilityIdentifier;
            [self addSubview:_twitterButton];
        }
    } else {
        [_twitterButton removeFromSuperview];
        _twitterButton = nil;
    }
}

///--------------------------------------
#pragma mark - UIView
///--------------------------------------

- (void)layoutSubviews {
    [super layoutSubviews];

    const CGRect bounds = PFRectMakeWithOriginSize(CGPointZero, self.bounds.size);

    if (_dismissButton) {
        CGPoint origin = CGPointMake(16.0f, 16.0f);
        UIViewController *presentingViewController = self.presentingViewController;
        // In iOS 7+, if this view is presented fullscreen, it's top edge will be behind the status bar.
        // This lets us move down the dismiss button a bit so that it's not covered by the status bar.
        if ([presentingViewController respondsToSelector:@selector(topLayoutGuide)]) {
            origin.y += presentingViewController.topLayoutGuide.length;
        }

        CGRect frame = PFRectMakeWithOriginSize(origin, [_dismissButton sizeThatFits:bounds.size]);
        _dismissButton.frame = frame;
    }

    CGRect contentRect = PFRectMakeWithSizeCenteredInRect(PFSizeMin(bounds.size, [self _maxContentSize]),
                                                          bounds);
    const CGSize contentSizeScale = [self _contentSizeScaleForContentSize:contentRect.size];

    CGFloat socialButtonsDefaultInset = 16.0f;
    UIEdgeInsets socialButtonsRectInsets = UIEdgeInsetsZero;
    if (CGRectGetMinX(contentRect) <= CGRectGetMinX(bounds)) {
        socialButtonsRectInsets = UIEdgeInsetsMake(0.0f,
                                                   socialButtonsDefaultInset,
                                                   0.0f,
                                                   socialButtonsDefaultInset);
    }
    CGRect socialButtonsRect = UIEdgeInsetsInsetRect(contentRect, socialButtonsRectInsets);

    if (_signUpButton) {
        CGSize buttonSize = [_signUpButton sizeThatFits:socialButtonsRect.size];
        [(PFActionButton *)_signUpButton setButtonStyle:PFActionButtonStyleWide];

        CGRect frame = PFRectMakeWithSizeCenteredInRect(buttonSize, socialButtonsRect);
        frame.origin.y = CGRectGetMaxY(socialButtonsRect) - CGRectGetHeight(frame) - socialButtonsRectInsets.left;
        _signUpButton.frame = frame;

        contentRect.size.height = CGRectGetMinY(frame) - CGRectGetMinY(contentRect);
        socialButtonsRect = UIEdgeInsetsInsetRect(contentRect, socialButtonsRectInsets);
    }

    if (_facebookButton && _twitterButton) {
        CGSize buttonSize = [_facebookButton sizeThatFits:socialButtonsRect.size];
        buttonSize.width = (socialButtonsRect.size.width - socialButtonsDefaultInset) / 2.0f;

        CGRect frame = PFRectMakeWithOriginSize(socialButtonsRect.origin, buttonSize);
        frame.origin.y = CGRectGetMaxY(socialButtonsRect) - buttonSize.height - socialButtonsDefaultInset;
        [(PFActionButton *)_facebookButton setButtonStyle:PFActionButtonStyleNormal];
        _facebookButton.frame = frame;

        frame.origin.x = CGRectGetMaxX(frame) + socialButtonsDefaultInset;
        [(PFActionButton *)_twitterButton setButtonStyle:PFActionButtonStyleNormal];
        _twitterButton.frame = frame;

        contentRect.size.height = CGRectGetMinY(frame) - CGRectGetMinY(contentRect);
        socialButtonsRect = UIEdgeInsetsInsetRect(contentRect, socialButtonsRectInsets);
    } else if (_facebookButton) {
        CGSize buttonSize = [_facebookButton sizeThatFits:socialButtonsRect.size];
        CGRect frame = PFRectMakeWithOriginSize(socialButtonsRect.origin, buttonSize);
        frame.origin.y = CGRectGetMaxY(socialButtonsRect) - buttonSize.height - socialButtonsDefaultInset;
        _facebookButton.frame = frame;

        [(PFActionButton *)_facebookButton setButtonStyle:PFActionButtonStyleWide];

        contentRect.size.height = CGRectGetMinY(frame) - CGRectGetMinY(contentRect);
        socialButtonsRect = UIEdgeInsetsInsetRect(contentRect, socialButtonsRectInsets);
    } else if (_twitterButton) {
        CGSize buttonSize = [_twitterButton sizeThatFits:socialButtonsRect.size];
        CGRect frame = PFRectMakeWithOriginSize(socialButtonsRect.origin, buttonSize);
        frame.origin.y = CGRectGetMaxY(socialButtonsRect) - buttonSize.height - socialButtonsDefaultInset;
        _twitterButton.frame = frame;

        [(PFActionButton *)_twitterButton setButtonStyle:PFActionButtonStyleWide];

        contentRect.size.height = CGRectGetMinY(frame) - CGRectGetMinY(contentRect);
        socialButtonsRect = UIEdgeInsetsInsetRect(contentRect, socialButtonsRectInsets);
    }

    if (_signUpButton || _facebookButton || _twitterButton) {
        contentRect.size.height -= socialButtonsDefaultInset;
    }

    const CGRect loginContentRect = PFRectMakeWithSizeCenteredInRect([self _loginContentSizeThatFits:contentRect.size
                                                                                withContentSizeScale:contentSizeScale],
                                                                     contentRect);
    const CGSize loginContentSize = loginContentRect.size;
    CGFloat currentY = CGRectGetMinY(loginContentRect);

    if (_logo) {
        CGFloat logoTopInset = (CGRectGetMinX(contentRect) > 0.0f ? 36.0f : 88.0f) * contentSizeScale.height;
        CGFloat logoBottomInset = floor(36.0f * contentSizeScale.height);

        CGFloat logoAvailableHeight = floor(68.0f * contentSizeScale.height);

        CGSize logoSize = [_logo sizeThatFits:CGSizeMake(loginContentSize.width, logoAvailableHeight)];
        logoSize.width = MIN(loginContentSize.width, logoSize.width);
        logoSize.height = MIN(logoAvailableHeight, logoSize.height);

        CGRect frame = PFRectMakeWithSizeCenteredInRect(logoSize, loginContentRect);
        frame.origin.y = CGRectGetMinY(loginContentRect) + logoTopInset;
        _logo.frame = CGRectIntegral(frame);

        currentY = floor(CGRectGetMaxY(frame) + logoBottomInset);
    }

    if (_usernameField) {
        CGRect frame = PFRectMakeWithSizeCenteredInRect([_usernameField sizeThatFits:loginContentSize],
                                                        loginContentRect);
        frame.origin.y = currentY;
        _usernameField.frame = frame;

        currentY = CGRectGetMaxY(frame);
    }

    if (_passwordField) {
        CGRect frame = PFRectMakeWithSizeCenteredInRect([_passwordField sizeThatFits:loginContentSize],
                                                        loginContentRect);
        frame.origin.y = currentY;
        _passwordField.frame = frame;

        currentY = CGRectGetMaxY(frame);
    }

    if (_logInButton) {
        CGFloat loginButtonTopInset = floor(24.0f * contentSizeScale.height);

        CGRect frame = PFRectMakeWithSizeCenteredInRect([_logInButton sizeThatFits:loginContentSize], loginContentRect);
        frame.origin.y = currentY + loginButtonTopInset;
        _logInButton.frame = frame;

        currentY = CGRectGetMaxY(frame);
    }

    if (_passwordForgottenButton) {
        CGFloat forgotPasswordInset = floor(12.0f * contentSizeScale.height);

        CGSize buttonSize = [_passwordForgottenButton sizeThatFits:loginContentSize];
        CGRect frame = PFRectMakeWithSizeCenteredInRect(buttonSize, loginContentRect);
        frame.origin.y = currentY + forgotPasswordInset;
        _passwordForgottenButton.frame = frame;
    }
}

- (CGSize)_loginContentSizeThatFits:(CGSize)boundingSize withContentSizeScale:(CGSize)contentSizeScale {
    CGSize size = boundingSize;
    size.height = 0.0f;
    if (_logo) {
        CGFloat logoTopInset = floor(36.0f * contentSizeScale.height);
        CGFloat logoBottomInset = floor(36.0f * contentSizeScale.height);

        CGFloat logoAvailableHeight = floor(68.0f * contentSizeScale.height);

        CGFloat scale = MAX(contentSizeScale.width, contentSizeScale.height);

        CGSize logoSize = [_logo sizeThatFits:CGSizeMake(boundingSize.width, logoAvailableHeight)];
        logoSize.height *= scale;
        logoSize.width *= scale;

        size.height += logoSize.height + logoTopInset + logoBottomInset;
    }
    if (_usernameField) {
        CGSize fieldSize = [_usernameField sizeThatFits:boundingSize];
        size.height += fieldSize.height;
    }
    if (_passwordField) {
        CGSize fieldSize = [_passwordField sizeThatFits:boundingSize];
        size.height += fieldSize.height;
    }
    if (_logInButton) {
        CGFloat loginButtonTopInset = 24.0f * contentSizeScale.height;

        CGSize buttonSize = [_logInButton sizeThatFits:boundingSize];

        size.height += buttonSize.height + loginButtonTopInset;
    }
    if (_passwordForgottenButton) {
        CGFloat forgotPasswordInset = 12.0f * contentSizeScale.height;

        UIView *button = _signUpButton ?: _passwordForgottenButton;
        CGSize buttonSize = [button sizeThatFits:boundingSize];

        size.height += buttonSize.height + forgotPasswordInset * 2.0f;
    }
    size.width = floor(size.width);
    size.height = floor(size.height);

    return size;
}

- (CGSize)_maxContentSize {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? CGSizeMake(420.0f, 550.0f) : CGSizeMake(500.0f, 800.0f));
}

- (CGSize)_contentSizeScaleForContentSize:(CGSize)contentSize {
    CGSize maxContentSize = [self _maxContentSize];
    if (maxContentSize.width < contentSize.width &&
        maxContentSize.height < contentSize.height) {
        return CGSizeMake(1.0f, 1.0f);
    }

    CGSize contentSizeScale = CGSizeMake(contentSize.width / maxContentSize.width,
                                         contentSize.height / maxContentSize.height);
    return contentSizeScale;
}

///--------------------------------------
#pragma mark - Accessors
///--------------------------------------

- (void)setFields:(PFLogInFields)fields {
    if (_fields != fields) {
        _fields = fields;
        [self _updateAllFields];
        [self setNeedsLayout];
    }
}

- (void)setLogo:(UIView *)logo {
    if (self.logo != logo) {
        [_logo removeFromSuperview];
        _logo = logo;
        [self addSubview:_logo];

        [self setNeedsLayout];
    }
}

- (void)setEmailAsUsername:(BOOL)otherEmailAsUsername {
    if (_emailAsUsername != otherEmailAsUsername) {
        _emailAsUsername = otherEmailAsUsername;

        [self _updateUsernameFieldStyle];
    }
}

///--------------------------------------
#pragma mark - Private
///--------------------------------------

+ (void)_validateFields:(PFLogInFields)fields {
    if (fields == PFLogInFieldsNone) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Fields must be set before initializing PFLogInView."];
    }

    if (fields & PFLogInFieldsLogInButton) {
        if (!(fields & PFLogInFieldsUsernameAndPassword)) {
            [NSException raise:NSInvalidArgumentException
                        format:@"Username and password must be enabled if done button is enabled."];
        }
    }

    if (fields & PFLogInFieldsPasswordForgotten) {
        if (!(fields & PFLogInFieldsUsernameAndPassword)) {
            [NSException raise:NSInvalidArgumentException
                        format:@"Username and password must be enabled if password forgotten button is enabled."];
        }
    }
}

- (void)_updateUsernameFieldStyle {
    UIKeyboardType keyboardType = UIKeyboardTypeDefault;
    NSString *usernamePlaceholder = nil;
    if (!_emailAsUsername) {
        keyboardType = UIKeyboardTypeDefault;
        usernamePlaceholder = PFLocalizedString(@"Username", @"Username");
    } else {
        keyboardType = UIKeyboardTypeEmailAddress;
        usernamePlaceholder = PFLocalizedString(@"Email", @"Email");
    }
    
    _usernameField.placeholder = usernamePlaceholder;
    _usernameField.keyboardType = keyboardType;
}

@end
