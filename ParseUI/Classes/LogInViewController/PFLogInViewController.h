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

#import <Parse/PFConstants.h>

#ifdef COCOAPODS
#import "ParseUIConstants.h"
#import "PFLogInView.h"
#else
#import <ParseUI/ParseUIConstants.h>
#import <ParseUI/PFLogInView.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@import AuthenticationServices;

@class PFSignUpViewController;
@class PFUser;
@protocol PFLogInViewControllerDelegate;

/**
 The `PFLogInViewController` class presents and manages a standard authentication interface for logging in a `PFUser`.
 */
@interface PFLogInViewController : UIViewController <UITextFieldDelegate>

///--------------------------------------
/// @name Configuring Log In Elements
///--------------------------------------

/**
 A bitmask specifying the log in elements which are enabled in the view.

 @see PFLogInFields
 */
@property (nonatomic, assign) PFLogInFields fields;


/**
 The log in view. It contains all the enabled log in elements.

 @see PFLogInView
 */
@property (nullable, nonatomic, strong, readonly) PFLogInView *logInView;

///--------------------------------------
/// @name Configuring Log In Behaviors
///--------------------------------------

/**
 The delegate that responds to the control events of `PFLogInViewController`.

 @see PFLogInViewControllerDelegate
 */
@property (nullable, nonatomic, weak) id<PFLogInViewControllerDelegate> delegate;

/**
 The facebook permissions that Facebook log in requests for.

 If unspecified, the default is basic facebook permissions.
 */
@property (nullable, nonatomic, copy) NSArray<NSString *> *facebookPermissions;

/**
 The sign up controller if sign up is enabled.

 Use this to configure the sign up view, and the transition animation to the sign up view.
 The default is a sign up view with a username, a password, a dismiss button and a sign up button.
 */
@property (nullable, nonatomic, strong) PFSignUpViewController *signUpController;

/**
 Whether to prompt for the email as username on the login view.

 If set to `YES`, we'll prompt for the email in the username field.
 This property value propagates to the attached `signUpController`.
 By default, this is set to `NO`.
 */
@property (nonatomic, assign) BOOL emailAsUsername;

@end

///--------------------------------------
/// @name Notifications
///--------------------------------------

/**
 The notification is posted immediately after the log in succeeds.
 */
extern NSString *const PFLogInSuccessNotification;

/**
 The notification is posted immediately after the log in fails.
 If the delegate prevents the log in from starting, the notification is not sent.
 */
extern NSString *const PFLogInFailureNotification;

/**
 The notification is posted immediately after the log in is cancelled.
 */
extern NSString *const PFLogInCancelNotification;

///--------------------------------------
/// @name PFLogInViewControllerDelegate
///--------------------------------------

/**
 The `PFLogInViewControllerDelegate` protocol defines methods a delegate of a `PFLogInViewController` should implement.
 All methods of this protocol are optional.
 */
@protocol PFLogInViewControllerDelegate <NSObject>

@optional

///--------------------------------------
/// @name Customizing Behavior
///--------------------------------------

/**
 Sent to the delegate to determine whether the log in request should be submitted to the server.

 @param logInController The login view controller that is requesting the data.
 @param username the username the user tries to log in with.
 @param password the password the user tries to log in with.

 @return A `BOOL` indicating whether the log in should proceed.
 */
- (BOOL)logInViewController:(PFLogInViewController *)logInController
shouldBeginLogInWithUsername:(NSString *)username
                   password:(NSString *)password;

///--------------------------------------
/// @name Responding to Actions
///--------------------------------------

/**
 Sent to the delegate when a `PFUser` is logged in.

 @param logInController The login view controller where login finished.
 @param user `PFUser` object that is a result of the login.
 */
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user;

/**
 Sent to the delegate when the log in attempt fails.

 If you implement this method, PFLoginViewController will not automatically show its default
 login failure alert view. Instead, you should show your custom alert view in your implementation.

 @param logInController The login view controller where login failed.
 @param error `NSError` object representing the error that occured.
 */
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(nullable NSError *)error;

/**
 Sent to the delegate when the log in screen is cancelled.

 @param logInController The login view controller where login was cancelled.
 */
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController;

/**
 Sent to the delegate when user data is received following successful login using Sign In With Apple.
 
 @param logInController The login view controller that received the credentials
 @param credential The ASAuthorizationAppleIDCredential object received
 */

-(void)logInViewController:(PFLogInViewController *)logInController didReceiveAppleCredential:(ASAuthorizationAppleIDCredential *)credential forUser:(PFUser *)user API_AVAILABLE(ios(13.0));

@end

NS_ASSUME_NONNULL_END
