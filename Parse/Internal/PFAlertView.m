/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFAlertView.h"

@interface PFAlertView () <UIAlertViewDelegate>

@property (nonatomic, copy) PFAlertViewCompletion completion;

@end

@implementation PFAlertView

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
         cancelButtonTitle:(NSString *)cancelButtonTitle
         otherButtonTitles:(NSArray *)otherButtonTitles
                completion:(PFAlertViewCompletion)completion {
    if ([UIAlertController class] != nil) {
        __block UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                         message:message
                                                                                  preferredStyle:UIAlertControllerStyleAlert];

        void (^alertActionHandler)(UIAlertAction *) = [^(UIAlertAction *action){
            // This block intentionally retains alertController, and releases it afterwards.
            if (action.style == UIAlertActionStyleCancel) {
                completion(NSNotFound);
            } else {
                NSUInteger index = [alertController.actions indexOfObject:action];
                completion(index - 1);
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

        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        UIViewController *viewController = keyWindow.rootViewController;
        while (viewController.presentedViewController) {
            viewController = viewController.presentedViewController;
        }

        [viewController presentViewController:alertController animated:YES completion:nil];
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
        __block PFAlertView *pfAlertView = [[self alloc] init];
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
