/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PFOAuth1FlowDialog;

@protocol PFOAuth1FlowDialogDataSource <NSObject>

/**
 Asks if a link touched by a user should be opened in an external browser.

 If a user touches a link, the default behavior is to open the link in the Safari browser,
 which will cause your app to quit.  You may want to prevent this from happening, open the link
 in your own internal browser, or perhaps warn the user that they are about to leave your app.
 If so, implement this method on your delegate and return NO.  If you warn the user, you
 should hold onto the URL and once you have received their acknowledgement open the URL yourself
 using [[UIApplication sharedApplication] openURL:].
 */
- (BOOL)dialog:(PFOAuth1FlowDialog *)dialog shouldOpenURLInExternalBrowser:(NSURL *)url;

@end

typedef void (^PFOAuth1FlowDialogCompletion)(BOOL succeeded, NSURL *url, NSError *error);

/**
 To allow for greater mockability, this protocol exposes all of the methods implemented by PFOAuth1FlowDialog.
 */
@protocol PFOAuth1FlowDialogInterface <NSObject>

@property (nonatomic, weak) id<PFOAuth1FlowDialogDataSource> dataSource;
@property (nonatomic, strong) PFOAuth1FlowDialogCompletion completion;

@property (nonatomic, copy) NSDictionary *queryParameters;
@property (nonatomic, copy) NSString *redirectURLPrefix;

/**
 The title that is shown in the header atop the view.
 */
@property (nonatomic, copy) NSString *title;

+ (instancetype)dialogWithURL:(NSURL *)url queryParameters:(NSDictionary *)queryParameters;

/**
 The view will be added to the top of the current key window.
 */
- (void)showAnimated:(BOOL)animated;

/**
 Hides the view.
 This method does not call the completion block.
 */
- (void)dismissAnimated:(BOOL)animated;

/**
 Displays a URL in the dialog.
 */
- (void)loadURL:(NSURL *)url queryParameters:(NSDictionary *)parameters;

@end

@interface PFOAuth1FlowDialog : UIView <UIWebViewDelegate, PFOAuth1FlowDialogInterface> {
@public
    // Ensures that UI elements behind the dialog are disabled.
    UIView *_modalBackgroundView;

    NSURL *_baseURL;
    NSURL *_loadingURL;

    UILabel *_titleLabel;
    UIButton *_closeButton;
    UIWebView *_webView;
    UIActivityIndicatorView *_activityIndicator;

    UIInterfaceOrientation _orientation;
    BOOL _showingKeyboard;
}

- (instancetype)initWithURL:(NSURL *)url queryParameters:(NSDictionary *)parameters;

@end
