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

#import "PFColor.h"

@implementation PFColor

#pragma mark -
#pragma mark Common

+ (UIColor *)commonBackgroundColor {
    return [UIColor colorWithRed:249/255.0f
                           green:251.0f/255.0f
                            blue:1.0f
                           alpha:1.0f];
}

#pragma mark -
#pragma mark TextField

+ (UIColor *)textFieldBackgroundColor {
    return [UIColor whiteColor];
}

+ (UIColor *)textFieldTextColor {
    return [UIColor blackColor];
}

+ (UIColor *)textFieldPlaceholderColor {
    return [UIColor colorWithWhite:194.0f/255.0f alpha:1.0f];
}

+ (UIColor *)textFieldSeparatorColor {
    return [UIColor colorWithWhite:227.0f/255.0f alpha:1.0f];
}

#pragma mark -
#pragma mark Buttons

+ (UIColor *)loginButtonBackgroundColor {
    return [UIColor colorWithRed:97.0f/255.0f
                           green:106.f/255.0f
                            blue:116.0f/255.0f
                           alpha:1.0f];
}

+ (UIColor *)signupButtonBackgroundColor {
    return [UIColor colorWithRed:108.0f/255.0f
                           green:150.0f/255.0f
                            blue:249.0f/255.0f
                           alpha:1.0f];
}

+ (UIColor *)facebookButtonBackgroundColor {
    return [UIColor colorWithRed:58.0f/255.0f
                           green:89.0f/255.0f
                            blue:152.0f/255.0f
                           alpha:1.0f];
}

+ (UIColor *)twitterButtonBackgroundColor {
    return [UIColor colorWithRed:45.0f/255.0f
                           green:170.0f/255.0f
                            blue:1.0f
                           alpha:1.0f];
}

@end
