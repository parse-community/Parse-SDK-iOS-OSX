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

#import "PFSignUpViewController.h"

#import <Parse/PFConstants.h>
#import <Parse/PFUser.h>

#import "PFUIAlertView.h"
#import "PFLocalization.h"
#import "PFPrimaryButton.h"
#import "PFTextField.h"

NSString *const PFSignUpSuccessNotification = @"com.parse.ui.signup.success";
NSString *const PFSignUpFailureNotification = @"com.parse.ui.signup.failure";
NSString *const PFSignUpCancelNotification = @"com.parse.ui.signup.cancel";

// Keys that are used to pass information to the delegate on `signUpViewController:shouldBeginSignUp`.
NSString *const PFSignUpViewControllerDelegateInfoUsernameKey = @"username";
NSString *const PFSignUpViewControllerDelegateInfoPasswordKey = @"password";
NSString *const PFSignUpViewControllerDelegateInfoEmailKey = @"email";
NSString *const PFSignUpViewControllerDelegateInfoAdditionalKey = @"additional";

@interface PFSignUpViewController () {
    struct {
        BOOL shouldSignUp : YES;
        BOOL didSignUp : YES;
        BOOL didFailToSignUp : YES;
        BOOL didCancelSignUp : YES;
    } _delegateExistingMethods;
}

@property (nonatomic, strong, readwrite) PFSignUpView *signUpView;

@property (nonatomic, assign) BOOL loading;

@property (nonatomic, assign) CGFloat visibleKeyboardHeight;

@end

@implementation PFSignUpViewController

#pragma mark -
#pragma mark Init

- (instancetype)init {
    if (self = [super init]) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    _fields = PFSignUpFieldsDefault;

    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
    // Unregister from all notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark UIViewController

- (void)loadView {
    _signUpView = [[PFSignUpView alloc] initWithFields:_fields];
    _signUpView.presentingViewController = self;
    self.view = _signUpView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self _setupHandlers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self _registerForKeyboardNotifications];
    if (self.navigationController &&
        self.fields & PFSignUpFieldsDismissButton) {
        self.fields = self.fields & ~PFSignUpFieldsDismissButton;

        [_signUpView.dismissButton removeFromSuperview];
    }
}

#pragma mark -
#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    }

    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -
#pragma mark PFSignUpViewController

- (PFSignUpView *)signUpView {
    return (PFSignUpView *)self.view; // self.view will call loadView if the view is nil
}

- (void)setDelegate:(id<PFSignUpViewControllerDelegate>)delegate {
    if (self.delegate != delegate) {
        _delegate = delegate;

        _delegateExistingMethods.shouldSignUp = [delegate respondsToSelector:@selector(signUpViewController:
                                                                                       shouldBeginSignUp:)];
        _delegateExistingMethods.didSignUp = [delegate respondsToSelector:@selector(signUpViewController:
                                                                                    didSignUpUser:)];
        _delegateExistingMethods.didFailToSignUp = [delegate respondsToSelector:@selector(signUpViewController:
                                                                                          didFailToSignUpWithError:)];
        _delegateExistingMethods.didCancelSignUp = [delegate
                                                    respondsToSelector:@selector(signUpViewControllerDidCancelSignUp:)];
    }
}

- (void)setEmailAsUsername:(BOOL)otherEmailAsUsername {
    self.signUpView.emailAsUsername = otherEmailAsUsername;
}

- (BOOL)emailAsUsername {
    return self.signUpView.emailAsUsername;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self _updateSignUpViewContentOffsetAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _signUpView.usernameField) {
        [_signUpView.passwordField becomeFirstResponder];
        return YES;
    }

    if (textField == _signUpView.passwordField) {
        if (_signUpView.emailField) {
            [_signUpView.emailField becomeFirstResponder];
            return YES;
        } else if (_signUpView.additionalField) {
            [_signUpView.additionalField becomeFirstResponder];
            return YES;
        }
    }

    if (textField == _signUpView.emailField) {
        if (_signUpView.additionalField) {
            [_signUpView.additionalField becomeFirstResponder];
            return YES;
        }
    }

    [self _signUpAction];

    return YES;
}

#pragma mark -
#pragma mark Private

- (void)_setupHandlers {
    _signUpView.delegate = self; // UIScrollViewDelegate
    [_signUpView.dismissButton addTarget:self
                                  action:@selector(_dismissAction)
                        forControlEvents:UIControlEventTouchUpInside];
    _signUpView.usernameField.delegate = self;
    _signUpView.passwordField.delegate = self;
    _signUpView.emailField.delegate = self;
    _signUpView.additionalField.delegate = self;
    [_signUpView.signUpButton addTarget:self
                                 action:@selector(_signUpAction)
                       forControlEvents:UIControlEventTouchUpInside];

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self
                                                 action:@selector(_dismissKeyboard)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [_signUpView addGestureRecognizer:gestureRecognizer];
}

- (void)_dismissAction {
    [self _cancelSignUp];

    // Normally the role of dismissing a modal controller lies on the presenting controller.
    // Here we violate the principle so that the presenting modal log in controller is especially easy.
    // Cons of this design is that it makes working with non-modally presented log in controller hard;
    // but this concern is mitigated by the fact that navigationally presented controller should not have
    // dismiss button.

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)_signUpAction {
    if (self.loading) {
        return;
    }

    [self _dismissKeyboard];

    NSString *username = _signUpView.usernameField.text ?: @"";
    NSString *password = _signUpView.passwordField.text ?: @"";
    NSString *email = (self.emailAsUsername ? username : _signUpView.emailField.text);
    email = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSString *additional = _signUpView.additionalField.text;

    NSMutableDictionary *dictionary = [@{ PFSignUpViewControllerDelegateInfoUsernameKey : username,
                                          PFSignUpViewControllerDelegateInfoPasswordKey : password } mutableCopy];

    if (email) {
        dictionary[PFSignUpViewControllerDelegateInfoEmailKey] = email;
    }
    if (additional) {
        dictionary[PFSignUpViewControllerDelegateInfoAdditionalKey] = additional;
    }

    if (_delegateExistingMethods.shouldSignUp) {
        if (![_delegate signUpViewController:self shouldBeginSignUp:dictionary]) {
            return;
        }
    }

    if ([password length] < _minPasswordLength) {
        NSString *errorMessage = PFLocalizedString(@"Password must be at least %d characters.",
                                                   @"Password too short error message in PFSignUpViewController");
        errorMessage = [NSString stringWithFormat:errorMessage, (unsigned long)_minPasswordLength];
        NSError *error = [NSError errorWithDomain:PFParseErrorDomain
                                             code:0
                                         userInfo:@{ NSLocalizedDescriptionKey : errorMessage }];
        [self _signUpDidFailWithError:error];
        [_signUpView.passwordField becomeFirstResponder];

        return;
    }

    PFUser *user = [PFUser user];
    user.username = username;
    user.password = password;

    if (email) {
        user.email = email;
    }
    if (additional) {
        user[PFSignUpViewControllerDelegateInfoAdditionalKey] = additional;
    }

    self.loading = YES;
    if ([_signUpView.signUpButton isKindOfClass:[PFPrimaryButton class]]) {
        [(PFPrimaryButton *)_signUpView.signUpButton setLoading:YES];
    }
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        self.loading = NO;
        if ([_signUpView.signUpButton isKindOfClass:[PFPrimaryButton class]]) {
            [(PFPrimaryButton *)_signUpView.signUpButton setLoading:NO];
        }

        if (succeeded) {
            [self _signUpDidSuceedWithUser:user];
        }
        else {
            [self _signUpDidFailWithError:error];
        }
    }];
}

- (void)_signUpDidSuceedWithUser:(PFUser *)user {
    if (_delegateExistingMethods.didSignUp) {
        [_delegate signUpViewController:self didSignUpUser:user];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:PFSignUpSuccessNotification object:self];
}

- (void)_signUpDidFailWithError:(NSError *)error {
    if (_delegateExistingMethods.didFailToSignUp) {
        [_delegate signUpViewController:self didFailToSignUpWithError:error];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:PFSignUpFailureNotification object:self];

    NSString *title = PFLocalizedString(@"Sign Up Error", @"Sign Up Error");

    if ([[error domain] isEqualToString:PFParseErrorDomain]) {
        NSInteger errorCode = [error code];
        NSString *message = nil;
        UIResponder *responder = nil;

        if (errorCode == kPFErrorInvalidEmailAddress) {
            message = PFLocalizedString(@"The email address is invalid. Please enter a valid email.",
                                        @"Invalid email address error message in PFSignUpViewControllers");
            responder = _signUpView.emailField ?: _signUpView.usernameField;
        } else if (errorCode == kPFErrorUsernameMissing) {
            message = PFLocalizedString(@"Please enter a username.",
                                        @"Username missing error message in PFSignUpViewController");
            responder = _signUpView.usernameField;
        } else if (errorCode == kPFErrorUserPasswordMissing) {
            message = PFLocalizedString(@"Please enter a password.",
                                        @"Password missing error message in PFSignUpViewController");
            responder = _signUpView.passwordField;
        } else if (errorCode == kPFErrorUsernameTaken) {
            NSString *format = PFLocalizedString(@"The username '%@' is taken. Please try choosing a different username.",
                                                 @"Username taken error format in PFSignUpViewController");
            message = [NSString stringWithFormat:format, _signUpView.usernameField.text];
            responder = _signUpView.usernameField;
        } else if (error.code == kPFErrorUserEmailTaken) {
            NSString *format = PFLocalizedString(@"The email '%@' is taken. Please try using a different email.",
                                                 @"Email is taken error format in PFSignUpViewController.");
            UITextField *textField = self.emailAsUsername ? _signUpView.usernameField : _signUpView.emailField;

            message = [NSString stringWithFormat:format, textField.text];
            responder = textField;
        } else if (error.code == kPFErrorUserEmailMissing) {
            message = PFLocalizedString(@"Please enter an email.",
                                        @"Email missing error message in PFSignUpViewController");
            responder = _signUpView.emailField;
        }

        if (message != nil) {
            [PFUIAlertView presentAlertInViewController:self withTitle:title message:message];
            [responder becomeFirstResponder];

            return;
        }
    }

    // Show the generic error alert, as no custom cases matched before
    [PFUIAlertView presentAlertInViewController:self withTitle:title error:error];
}

- (void)_cancelSignUp {
    if (_delegateExistingMethods.didCancelSignUp) {
        [_delegate signUpViewControllerDidCancelSignUp:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:PFSignUpCancelNotification object:self];
}

- (UIView *)_currentFirstResponder {
    if ([_signUpView.usernameField isFirstResponder]) {
        return _signUpView.usernameField;
    }
    if ([_signUpView.passwordField isFirstResponder]) {
        return _signUpView.passwordField;
    }
    if ([_signUpView.emailField isFirstResponder]) {
        return _signUpView.emailField;
    }
    if ([_signUpView.additionalField isFirstResponder]) {
        return _signUpView.additionalField;
    }

    return nil;
}

#pragma mark Keyboard

- (void)_dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)_registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)_keyboardWillShow:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    CGRect keyboardFrame = [self.view convertRect:endFrame fromView:self.view.window];
    CGFloat visibleKeyboardHeight = CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(keyboardFrame);

    [self setVisibleKeyboardHeight:visibleKeyboardHeight
                 animationDuration:duration
                  animationOptions:curve << 16];
}

- (void)_keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [self setVisibleKeyboardHeight:0.0
                 animationDuration:duration
                  animationOptions:curve << 16];
}

- (void)setVisibleKeyboardHeight:(CGFloat)visibleKeyboardHeight
               animationDuration:(NSTimeInterval)animationDuration
                animationOptions:(UIViewAnimationOptions)animationOptions {

    dispatch_block_t animationsBlock = ^{
        self.visibleKeyboardHeight = visibleKeyboardHeight;
    };

    if (animationDuration == 0.0) {
        animationsBlock();
    } else {
        [UIView animateWithDuration:animationDuration
                              delay:0.0
                            options:animationOptions | UIViewAnimationOptionBeginFromCurrentState
                         animations:animationsBlock
                         completion:nil];
    }
}

- (void)setVisibleKeyboardHeight:(CGFloat)visibleKeyboardHeight {
    if (self.visibleKeyboardHeight != visibleKeyboardHeight) {
        _visibleKeyboardHeight = visibleKeyboardHeight;
        [self _updateSignUpViewContentOffsetAnimated:NO];
    }
}

- (void)_updateSignUpViewContentOffsetAnimated:(BOOL)animated {
    CGPoint contentOffset = CGPointZero;
    if (self.visibleKeyboardHeight > 0.0f) {
        // Scroll the view to keep fields visible
        CGFloat offsetForScrollingTextFieldToTop = CGRectGetMinY([self _currentFirstResponder].frame);

        UIView *lowestView;
        if (_signUpView.signUpButton) {
            lowestView = _signUpView.signUpButton;
        } else if (_signUpView.additionalField) {
            lowestView = _signUpView.additionalField;
        } else if (_signUpView.emailField) {
            lowestView = _signUpView.emailField;
        } else {
            lowestView = _signUpView.passwordField;
        }

        CGFloat offsetForScrollingLowestViewToBottom = 0.0f;
        offsetForScrollingLowestViewToBottom += self.visibleKeyboardHeight;
        offsetForScrollingLowestViewToBottom += CGRectGetMaxY(lowestView.frame);
        offsetForScrollingLowestViewToBottom -= CGRectGetHeight(_signUpView.bounds);

        if (offsetForScrollingLowestViewToBottom < 0) {
            return; // No scrolling required
        }

        contentOffset = CGPointMake(0.0f, MIN(offsetForScrollingTextFieldToTop,
                                              offsetForScrollingLowestViewToBottom));
    }

    [_signUpView setContentOffset:contentOffset animated:animated];
}

#pragma mark -
#pragma mark Accessors

- (void)setLoading:(BOOL)loading {
    if (self.loading != loading) {
        _loading = loading;

        _signUpView.usernameField.enabled = !self.loading;
        _signUpView.passwordField.enabled = !self.loading;
        _signUpView.emailField.enabled = !self.loading;
        _signUpView.additionalField.enabled = !self.loading;
        _signUpView.dismissButton.enabled = !self.loading;
    }
}

@end
