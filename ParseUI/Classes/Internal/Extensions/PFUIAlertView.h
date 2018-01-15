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

NS_ASSUME_NONNULL_BEGIN

typedef void(^PFUIAlertViewCompletion)(NSUInteger selectedOtherButtonIndex);
typedef void(^PFUIAlertViewTextFieldCompletion)(UITextField *textField, NSUInteger selectedOtherButtonIndex);
typedef void(^PFUIAlertViewTextFieldCustomizationHandler)(UITextField *textField);

@interface PFUIAlertView : NSObject

///--------------------------------------
#pragma mark - Present
///--------------------------------------

+ (void)presentAlertInViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                             message:(nullable NSString *)message
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(nullable NSArray *)otherButtonTitles
                          completion:(nullable PFUIAlertViewCompletion)completion;

+ (void)presentAlertInViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                             message:(nullable NSString *)message
       textFieldCustomizationHandler:(PFUIAlertViewTextFieldCustomizationHandler)textFieldCustomizationHandler
                   cancelButtonTitle:(NSString *)cancelButtonTitle
                   otherButtonTitles:(nullable NSArray *)otherButtonTitles
                          completion:(nullable PFUIAlertViewTextFieldCompletion)completion;

///--------------------------------------
#pragma mark - Convenience
///--------------------------------------

+ (void)presentAlertInViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                               error:(NSError *)error;
+ (void)presentAlertInViewController:(UIViewController *)viewController
                           withTitle:(NSString *)title
                             message:(nullable NSString *)message;

@end

NS_ASSUME_NONNULL_END
