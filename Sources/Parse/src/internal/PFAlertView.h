/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Parse/PFConstants.h>

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

PF_OSX_UNAVAILABLE_WARNING
PF_WATCH_UNAVAILABLE_WARNING

typedef void(^PFAlertViewCompletion)(NSUInteger selectedOtherButtonIndex);

PF_OSX_UNAVAILABLE PF_WATCH_UNAVAILABLE @interface PFAlertView : NSObject

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
         cancelButtonTitle:(NSString *)cancelButtonTitle
         otherButtonTitles:(NSArray *)otherButtonTitles
                completion:(PFAlertViewCompletion)completion NS_EXTENSION_UNAVAILABLE_IOS("");

@end
