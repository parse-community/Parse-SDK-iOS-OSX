/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

@import UIKit;

#import <OCMock/OCMock.h>

#import "PFAlertView.h"
#import "PFMacros.h"
#import "PFTestCase.h"
#import "PFTestSwizzlingUtilities.h"

// Swizzling UIAlertController doesn't seem to work without these defined in UIAlertController itself.
@implementation UIAlertController (ClassOverrides)

+ (Class)class {
    return [super class];
}

+ (Class)_nilClass {
    return nil;
}

@end

@interface AlertViewTests : PFTestCase

@end

@implementation AlertViewTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

- (void)testShowAlertWithAlertViewController {
    id mockedAlertController = PFStrictClassMock([UIAlertController class]);
    id mockedApplication = PFStrictClassMock([UIApplication class]);
    UIWindow *mockedWindow = PFStrictClassMock([UIWindow class]);
    UIViewController *mockedViewController = PFStrictClassMock([UIViewController class]);
    OCMStub(mockedViewController.presentedViewController).andReturn(nil);

    // Using .andReturn() here will result in a retain cycle, which will cause our mocked shared application to
    // persist across tests.
    @weakify(mockedAlertController);
    OCMStub(ClassMethod([[mockedAlertController ignoringNonObjectArgs] alertControllerWithTitle:@"Title"
                                                                                        message:@"Message"
                                                                                 preferredStyle:0]))
        .andDo(^(NSInvocation *invocation) {
            @strongify(mockedAlertController);
            [invocation setReturnValue:&mockedAlertController];
        });


    @weakify(mockedApplication);
    OCMStub(ClassMethod([mockedApplication sharedApplication])).andDo(^(NSInvocation *invocation) {
        @strongify(mockedApplication);
        [invocation setReturnValue:(void *)&mockedApplication];
    });

    OCMStub([mockedApplication keyWindow]).andReturn(mockedWindow);
    OCMStub(mockedWindow.rootViewController).andReturn(mockedViewController);

    NSMutableArray *actions = [NSMutableArray new];
    __block UIAlertAction *cancelAction = nil;

    id checker = [OCMArg checkWithBlock:^BOOL(UIAlertAction *obj) {
        if ([obj.title isEqualToString:@"Cancel"] && obj.style == UIAlertActionStyleCancel) {
            cancelAction = obj;
            return YES;
        }

        return ([obj.title isEqualToString:@"No"] && obj.style == UIAlertActionStyleDefault) ||
        ([obj.title isEqualToString:@"Yes"] && obj.style == UIAlertActionStyleDefault);
    }];

    OCMStub([mockedAlertController addAction:checker]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained id action = nil;
        [invocation getArgument:&action atIndex:2];

        [actions addObject:action];
    });

    OCMStub([mockedAlertController actions]).andReturn(actions);

    OCMExpect([mockedViewController presentViewController:mockedAlertController
                                                 animated:YES
                                               completion:nil]).andDo(^(NSInvocation *invocation) {
        // Private API here to make UIAlertAction completed.
        void (^cancelActionHandler)(UIAlertAction *) = [cancelAction valueForKey:@"handler"];
        cancelActionHandler(cancelAction);
    });

    XCTestExpectation *expectation = [self currentSelectorTestExpectation];
    [PFAlertView showAlertWithTitle:@"Title"
                            message:@"Message"
                  cancelButtonTitle:@"Cancel"
                  otherButtonTitles:@[ @"Yes", @"No" ]
                         completion:^(NSUInteger selectedOtherButtonIndex) {
                             XCTAssertEqual(selectedOtherButtonIndex, NSNotFound);

                             [expectation fulfill];
                         }];

    [self waitForTestExpectations];
    OCMVerifyAll(mockedAlertController);
}

- (void)testShowWithoutAlertViewController {
    id mockedAlertView = PFStrictClassMock([UIAlertView class]);

    PFTestSwizzledMethod *swizzledMethod = [PFTestSwizzlingUtilities swizzleClassMethod:@selector(class)
                                                                    inClass:[UIAlertController class]
                                                                 withMethod:@selector(_nilClass)
                                                                    inClass:[UIAlertController class]];
    @try {
        OCMStub([mockedAlertView alloc]).andReturn(mockedAlertView);

        __block __weak id<UIAlertViewDelegate> delegate = nil;

        OCMExpect([mockedAlertView initWithTitle:@"Title"
                                         message:@"Message"
                                        delegate:OCMOCK_ANY
                               cancelButtonTitle:@"Cancel"
                               otherButtonTitles:nil]).andReturn(mockedAlertView);

        OCMExpect([mockedAlertView addButtonWithTitle:@"Yes"]);
        OCMExpect([mockedAlertView addButtonWithTitle:@"No"]);


        OCMExpect([mockedAlertView setDelegate:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
            __unsafe_unretained id newDelegate = nil;
            [invocation getArgument:&newDelegate atIndex:2];

            delegate = newDelegate;
        });

        OCMExpect([mockedAlertView show]).andDo(^(NSInvocation *invocation) {
            __unsafe_unretained UIAlertView *self = nil;
            [invocation getArgument:&self atIndex:0];

            [delegate alertView:self clickedButtonAtIndex:0];
        });

        OCMStub([mockedAlertView cancelButtonIndex]).andReturn(0);

        XCTestExpectation *expectation = [self currentSelectorTestExpectation];
        [PFAlertView showAlertWithTitle:@"Title"
                                message:@"Message"
                      cancelButtonTitle:@"Cancel"
                      otherButtonTitles:@[ @"Yes", @"No" ]
                             completion:^(NSUInteger selectedOtherButtonIndex) {
                                 XCTAssertEqual(selectedOtherButtonIndex, NSNotFound);

                                 [expectation fulfill];
                             }];

        [self waitForTestExpectations];
        OCMVerifyAll(mockedAlertView);
    } @finally {
        [swizzledMethod setSwizzled:NO];
    }
}

@end
