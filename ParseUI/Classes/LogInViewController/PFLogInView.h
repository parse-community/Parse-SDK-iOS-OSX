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

/**
 `PFLogInFields` bitmask specifies the log in elements which are enabled in the view.

 @see PFLogInViewController
 @see PFLogInView
 */
typedef NS_OPTIONS(NSInteger, PFLogInFields) {
    /** No fields. */
    PFLogInFieldsNone = 0,
    /** Username and password fields. */
    PFLogInFieldsUsernameAndPassword = 1 << 0,
    /** Forgot password button. */
    PFLogInFieldsPasswordForgotten = 1 << 1,
    /** Login button. */
    PFLogInFieldsLogInButton = 1 << 2,
    /** Button to login with Facebook. */
    PFLogInFieldsFacebook = 1 << 3,
    /** Button to login with Twitter. */
    PFLogInFieldsTwitter = 1 << 4,
    /** Signup Button. */
    PFLogInFieldsSignUpButton = 1 << 5,
    /** Dismiss Button. */
    PFLogInFieldsDismissButton = 1 << 6,

    /** Default value. Combines Username, Password, Login, Signup, Forgot Password and Dismiss buttons. */
    PFLogInFieldsDefault = (PFLogInFieldsUsernameAndPassword |
                            PFLogInFieldsLogInButton |
                            PFLogInFieldsSignUpButton |
                            PFLogInFieldsPasswordForgotten |
                            PFLogInFieldsDismissButton)
};

/**
 `PFLoginFields`'s accessibility label identifiers
 
 @see PFLogInView
 */
extern NSString *const PFLogInViewUsernameFieldAccessibilityIdentifier;
extern NSString *const PFLogInViewPasswordFieldAccessibilityIdentifier;
extern NSString *const PFLogInViewLogInButtonAccessibilityIdentifier;
extern NSString *const PFLogInViewSignUpButtonAccessibilityIdentifier;
extern NSString *const PFLogInViewPasswordForgottenButtonAccessibilityIdentifier;
extern NSString *const PFLogInViewTwitterButtonAccessibilityIdentifier;
extern NSString *const PFLogInViewFacebookButtonAccessibilityIdentifier;
extern NSString *const PFLogInViewDismissButtonAccessibilityIdentifier;

@class PFTextField;

/**
 The `PFLogInView` class provides a standard log in interface for authenticating a `PFUser`.
 */
@interface PFLogInView : UIScrollView

///--------------------------------------
/// @name Creating Log In View
///--------------------------------------

/**
 Initializes the view with the specified log in elements.

 @param fields A bitmask specifying the log in elements which are enabled in the view

 @return An initialized `PFLogInView` object or `nil` if the object couldn't be created.

 @see PFLogInFields
 */
- (instancetype)initWithFields:(PFLogInFields)fields;

/**
 The view controller that will present this view.

 Used to lay out elements correctly when the presenting view controller has translucent elements.
 */
@property (nullable, nonatomic, weak) UIViewController *presentingViewController;

///--------------------------------------
/// @name Customizing the Logo
///--------------------------------------

/// The logo. By default, it is the Parse logo.
@property (nullable, nonatomic, strong) UIView *logo;

///--------------------------------------
/// @name Configure Username Behaviour
///--------------------------------------

/**
 If email should be used to log in, instead of username

 By default, this is set to `NO`.
 */
@property (nonatomic, assign) BOOL emailAsUsername;

///--------------------------------------
/// @name Log In Elements
///--------------------------------------

/**
 The bitmask which specifies the enabled log in elements in the view.
 */
@property (nonatomic, assign, readonly) PFLogInFields fields;

/**
 The username text field. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) PFTextField *usernameField;

/**
 The password text field. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) PFTextField *passwordField;

/**
 The password forgotten button. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) UIButton *passwordForgottenButton;

/**
 The log in button. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) UIButton *logInButton;

/**
 The Facebook button. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) UIButton *facebookButton;

/**
 The Twitter button. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) UIButton *twitterButton;

/**
 The sign up button. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) UIButton *signUpButton;

/**
 It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) UIButton *dismissButton;

/**
 The facebook/twitter login label.

 @deprecated This property is deprecated and will always be nil.
 */
@property (nullable, nonatomic, strong, readonly) UILabel *externalLogInLabel __attribute__(PARSE_UI_DEPRECATED("This property is deprecated and will always be nil."));

/**
 The sign up label.

 @deprecated This property is deprecated and will always be nil.
 */
@property (nullable, nonatomic, strong, readonly) UILabel *signUpLabel __attribute__(PARSE_UI_DEPRECATED("This property is deprecated and will always be nil."));

@end

NS_ASSUME_NONNULL_END
