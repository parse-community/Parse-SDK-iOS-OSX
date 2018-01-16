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
 `PFSignUpFields` bitmask specifies the sign up elements which are enabled in the view.

 @see PFSignUpViewController
 @see PFSignUpView
 */
typedef NS_OPTIONS(NSInteger, PFSignUpFields) {
    /** Username and password fields. */
    PFSignUpFieldsUsernameAndPassword = 1 << 0,
    /** Email field. */
    PFSignUpFieldsEmail = 1 << 1,
    /** This field can be used for something else. */
    PFSignUpFieldsAdditional = 1 << 2,
    /** Sign Up Button */
    PFSignUpFieldsSignUpButton = 1 << 3,
    /** Dismiss Button */
    PFSignUpFieldsDismissButton = 1 << 4,
    /** Default value. Combines Username, Password, Email, Sign Up and Dismiss Buttons. */
    PFSignUpFieldsDefault = (PFSignUpFieldsUsernameAndPassword |
                             PFSignUpFieldsEmail |
                             PFSignUpFieldsSignUpButton |
                             PFSignUpFieldsDismissButton)
};

/**
 `PFSignUpFields`'s accessibity identifiers
 
 @see PFSignUpView
 */
extern NSString *const PFSignUpViewUsernameFieldAccessibilityIdentifier;
extern NSString *const PFSignUpViewEmailFieldAccessibilityIdentifier;
extern NSString *const PFSignUpViewPasswordFieldAccessibilityIdentifier;
extern NSString *const PFSignUpViewAdditionalFieldAccessibilityIdentifier;
extern NSString *const PFSignUpViewSignUpButtonAccessibilityIdentifier;
extern NSString *const PFSignUpViewDismissButtonAccessibilityIdentifier;

@class PFTextField;

/**
 The `PFSignUpView` class provides a standard sign up interface for authenticating a `PFUser`.
 */
@interface PFSignUpView : UIScrollView

///--------------------------------------
/// @name Creating SignUp View
///--------------------------------------

/**
 Initializes the view with the specified sign up elements.

 @param fields A bitmask specifying the sign up elements which are enabled in the view

 @return An initialized `PFSignUpView` object or `nil` if the object couldn't be created.

 @see PFSignUpFields
 */
- (instancetype)initWithFields:(PFSignUpFields)fields;

/**
 The view controller that will present this view.

 Used to lay out elements correctly when the presenting view controller has translucent elements.
 */
@property (nullable, nonatomic, weak) UIViewController *presentingViewController;

///--------------------------------------
/// @name Customizing the Logo
///--------------------------------------

/**
 The logo. By default, it is the Parse logo.
 */
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
/// @name Sign Up Elements
///--------------------------------------

/**
 The bitmask which specifies the enabled sign up elements in the view
 */
@property (nonatomic, assign, readonly) PFSignUpFields fields;

/**
 The username text field.
 */
@property (nullable, nonatomic, strong, readonly) PFTextField *usernameField;

/**
 The password text field.
 */
@property (nullable, nonatomic, strong, readonly) PFTextField *passwordField;

/**
 The email text field. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) PFTextField *emailField;

/**
 The additional text field. It is `nil` if the element is not enabled.

 This field is intended to be customized.
 */
@property (nullable, nonatomic, strong, readonly) PFTextField *additionalField;

/**
 The sign up button. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) UIButton *signUpButton;

/**
 The dismiss button. It is `nil` if the element is not enabled.
 */
@property (nullable, nonatomic, strong, readonly) UIButton *dismissButton;

@end

NS_ASSUME_NONNULL_END
