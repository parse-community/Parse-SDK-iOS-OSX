/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFOAuth1FlowDialog.h"
#import "PFTwitterTestCase.h"
#import <WebKit/WebKit.h>

@interface UIActivityIndicatorView (Private)

- (void)_generateImages;

@end

@interface FakeWKNavigationAction : WKNavigationAction
// Redefined WKNavigationAction properties as readwrite.
@property(nullable, nonatomic, copy) WKFrameInfo* sourceFrame;
@property(nullable, nonatomic, copy) WKFrameInfo* targetFrame;
@property(nonatomic) WKNavigationType navigationType;
@property(nullable, nonatomic, copy) NSURLRequest* request;

@end

@implementation FakeWKNavigationAction
@synthesize sourceFrame, targetFrame, navigationType, request;

+ (Class)class {
    return [super class];
}

+ (Class)_nilClass {
    return nil;
}

@end

@interface OAuth1FlowDialogTests : PFTwitterTestCase
@end

@interface UIDevice (Yolo)

- (void)setOrientation:(UIDeviceOrientation)orientation animated:(BOOL)animated;

@end

@implementation OAuth1FlowDialogTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testConstructors {
    NSURL *exampleURL = [NSURL URLWithString:@"http://foo.bar"];
    NSDictionary *parameters = @{ @"a" : @"b" };

    PFOAuth1FlowDialog *flowDialog = [[PFOAuth1FlowDialog alloc] initWithURL:exampleURL
                                                             queryParameters:parameters];
    XCTAssertNotNil(flowDialog);
    XCTAssertEqualObjects(flowDialog.queryParameters, parameters);
    XCTAssertEqualObjects(flowDialog->_baseURL, exampleURL);

    flowDialog = [PFOAuth1FlowDialog dialogWithURL:exampleURL queryParameters:parameters];
    XCTAssertNotNil(flowDialog);
    XCTAssertEqualObjects(flowDialog.queryParameters, parameters);
    XCTAssertEqualObjects(flowDialog->_baseURL, exampleURL);
}

- (void)testTitle {
    PFOAuth1FlowDialog *flowDialog = [[PFOAuth1FlowDialog alloc] initWithURL:nil queryParameters:nil];
    XCTAssertEqualObjects(flowDialog.title, @"Connect to Service");
    flowDialog.title = @"Bleh";
    XCTAssertEqualObjects(flowDialog.title, @"Bleh");
}

- (void)testShow {
    PFOAuth1FlowDialog *flowDialog = [[PFOAuth1FlowDialog alloc] initWithURL:nil queryParameters:nil];

    [flowDialog showAnimated:NO];
    [flowDialog layoutSubviews];
    [flowDialog dismissAnimated:NO];
}

- (void)testKeyboard {
    PFOAuth1FlowDialog *flowDialog = [[PFOAuth1FlowDialog alloc] initWithURL:nil queryParameters:nil];
    [flowDialog showAnimated:NO];

    NSDictionary *notificationuserInfo = @{ UIKeyboardAnimationDurationUserInfoKey : @0,
                                            UIKeyboardAnimationCurveUserInfoKey : @(UIViewAnimationCurveLinear) };
    [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillShowNotification
                                                        object:nil
                                                      userInfo:notificationuserInfo];

    [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillHideNotification
                                                        object:nil
                                                      userInfo:notificationuserInfo];

    [flowDialog dismissAnimated:NO];
}

- (void)testRotation {
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setOrientation:UIDeviceOrientationPortrait animated:NO];

    PFOAuth1FlowDialog *flowDialog = [[PFOAuth1FlowDialog alloc] initWithURL:nil queryParameters:nil];

    [flowDialog showAnimated:NO];
    CGRect oldBounds = flowDialog.bounds;

    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft];
    [[UIDevice currentDevice] setOrientation:UIDeviceOrientationLandscapeLeft animated:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification object:nil];

    CGRect newBounds = flowDialog.bounds;
    XCTAssertFalse(CGRectEqualToRect(oldBounds, newBounds));

    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait];
    [[UIDevice currentDevice] setOrientation:UIDeviceOrientationPortrait animated:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification object:nil];

    newBounds = flowDialog.bounds;
    XCTAssertTrue(CGRectEqualToRect(oldBounds, newBounds));

    [flowDialog dismissAnimated:NO];
}

- (void)testWebViewDelegate {
    NSURL *sampleURL = [NSURL URLWithString:@"http://foo.bar"];
    NSURL *successURL = [NSURL URLWithString:@"foo://success"];

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    PFOAuth1FlowDialog *flowDialog = [[PFOAuth1FlowDialog alloc] initWithURL:sampleURL queryParameters:nil];
    flowDialog.redirectURLPrefix = @"foo://";
    flowDialog.completion = ^(BOOL succeeded, NSURL *url, NSError *error) {
        XCTAssertTrue(succeeded);
        XCTAssertNil(error);
        XCTAssertEqualObjects(url, successURL);

        [expectation fulfill];
    };

    [flowDialog showAnimated:NO];

    id webView = PFStrictClassMock([WKWebView class]);

    NSURLRequest *request = [NSURLRequest requestWithURL:sampleURL];
    XCTestExpectation *decisionExpectation = [expectation initWithDescription:@"Waiting for policy decision"];
    
    
    FakeWKNavigationAction *navigationAction = [[FakeWKNavigationAction alloc] init];
    navigationAction.navigationType = WKNavigationTypeOther;
    navigationAction.request = request;
    
    
    [flowDialog webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:^(WKNavigationActionPolicy policy) {
        XCTAssertTrue(policy == WKNavigationActionPolicyAllow);
        [decisionExpectation fulfill];
    }];
    
    [self waitForTestExpectations];
}

@end
