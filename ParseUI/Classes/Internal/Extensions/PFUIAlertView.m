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

#import "PFUIAlertView.h"

#import "PFLocalization.h"

@interface PFUIAlertView () <UIAlertViewDelegate>

@property (nonatomic, copy) PFUIAlertViewCompletion completion;

@end

@implementation PFUIAlertView

///--------------------------------------
#pragma mark - Present
///--------------------------------------

+ (void)presentAlertInViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                             message:(nullable NSString *)message
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(nullable NSArray *)otherButtonTitles
                          completion:(nullable PFUIAlertViewCompletion)completion {
    if ([UIAlertController class] != nil) {
        __block UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                         message:message
                                                                                  preferredStyle:UIAlertControllerStyleAlert];

        void (^alertActionHandler)(UIAlertAction *) = [^(UIAlertAction *action) {
            if (completion) {
                // This block intentionally retains alertController, and releases it afterwards.
                if (action.style == UIAlertActionStyleCancel) {
                    completion(NSNotFound);
                } else {
                    NSUInteger index = [alertController.actions indexOfObject:action];
                    completion(index - 1);
                }
            }
            alertController = nil;
        } copy];

        [alertController addAction:[UIAlertAction actionWithTitle:cancelButtonTitle
                                                            style:UIAlertActionStyleCancel
                                                          handler:alertActionHandler]];

        for (NSString *buttonTitle in otherButtonTitles) {
            [alertController addAction:[UIAlertAction actionWithTitle:buttonTitle
                                                                style:UIAlertActionStyleDefault
                                                              handler:alertActionHandler]];
        }

        [viewController presentViewController:alertController animated:YES completion:nil];
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
        __block PFUIAlertView *pfAlertView = [[self alloc] init];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:cancelButtonTitle
                                                  otherButtonTitles:nil];

        for (NSString *buttonTitle in otherButtonTitles) {
            [alertView addButtonWithTitle:buttonTitle];
        }

        pfAlertView.completion = ^(NSUInteger index) {
            if (completion) {
                completion(index);
            }

            pfAlertView = nil;
        };

        alertView.delegate = pfAlertView;
        [alertView show];
#endif
    }
}

+ (void)presentAlertInViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                             message:(nullable NSString *)message
       textFieldCustomizationHandler:(PFUIAlertViewTextFieldCustomizationHandler)textFieldCustomizationHandler
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(nullable NSArray *)otherButtonTitles
                          completion:(nullable PFUIAlertViewTextFieldCompletion)completion {
    if ([UIAlertController class] != nil) {
        __block UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                         message:message
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:textFieldCustomizationHandler];
        void (^alertActionHandler)(UIAlertAction *) = [^(UIAlertAction *action) {
            if (completion) {
                UITextField *textField = alertController.textFields.firstObject;
                // This block intentionally retains alertController, and releases it afterwards.
                if (action.style == UIAlertActionStyleCancel) {
                    completion(textField, NSNotFound);
                } else {
                    NSUInteger index = [alertController.actions indexOfObject:action];
                    completion(textField, index - 1);
                }
            }
            alertController = nil;
        } copy];

        [alertController addAction:[UIAlertAction actionWithTitle:cancelButtonTitle
                                                            style:UIAlertActionStyleCancel
                                                          handler:alertActionHandler]];

        for (NSString *buttonTitle in otherButtonTitles) {
            [alertController addAction:[UIAlertAction actionWithTitle:buttonTitle
                                                                style:UIAlertActionStyleDefault
                                                              handler:alertActionHandler]];
        }

        [viewController presentViewController:alertController animated:YES completion:nil];
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
        __block PFUIAlertView *pfAlertView = [[self alloc] init];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:cancelButtonTitle
                                                  otherButtonTitles:nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        for (NSString *buttonTitle in otherButtonTitles) {
            [alertView addButtonWithTitle:buttonTitle];
        }
        textFieldCustomizationHandler([alertView textFieldAtIndex:0]);

        __weak UIAlertView *walertView = alertView;
        pfAlertView.completion = ^(NSUInteger index) {
            if (completion) {
                UITextField *textField = [walertView textFieldAtIndex:0];
                completion(textField, index);
            }

            pfAlertView = nil;
        };

        alertView.delegate = pfAlertView;
        [alertView show];
#endif
    }
}

///--------------------------------------
#pragma mark - Convenience
///--------------------------------------

+ (void)presentAlertInViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                               error:(NSError *)error {
    NSString *message = error.userInfo[@"error"];
    if (!message) {
        message = [error.userInfo[@"originalError"] localizedDescription];
    }
    if (!message) {
        message = [error localizedDescription];
    }
    [self presentAlertInViewController:viewController withTitle:title message:message];
}

+ (void)presentAlertInViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                             message:(nullable NSString *)message {
    [self presentAlertInViewController:viewController
                             withTitle:title
                               message:message
                     cancelButtonTitle:PFLocalizedString(@"OK", @"OK")
                     otherButtonTitles:nil
                            completion:nil];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0

///--------------------------------------
#pragma mark - UIAlertViewDelegate
///--------------------------------------

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.completion) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            self.completion(NSNotFound);
        } else {
            self.completion(buttonIndex - 1);
        }
    }
}

#endif

@end
