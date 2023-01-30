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

typedef NS_ENUM(uint8_t, PFActionButtonStyle)
{
    PFActionButtonStyleNormal,
    PFActionButtonStyleWide
};

@class PFActionButtonConfiguration;

@interface PFActionButton : UIButton

@property (nonatomic, assign, getter=isLoading) BOOL loading;

@property (nonatomic, assign) PFActionButtonStyle buttonStyle;

///--------------------------------------
/// @name Class
///--------------------------------------

+ (NSString *)titleForButtonStyle:(PFActionButtonStyle)buttonStyle;

///--------------------------------------
/// @name Init
///--------------------------------------

- (instancetype)initWithConfiguration:(PFActionButtonConfiguration *)configuration
                          buttonStyle:(PFActionButtonStyle)buttonStyle NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

@end

@interface PFActionButtonConfiguration : NSObject

@property (nonatomic, strong, readonly) UIColor *backgroundImageColor;
@property (nonatomic, strong, readonly) UIImage *image;

- (instancetype)initWithBackgroundImageColor:(UIColor *)backgroundImageColor
                                       image:(UIImage *)image NS_DESIGNATED_INITIALIZER;

- (void)setTitle:(NSString *)title forButtonStyle:(PFActionButtonStyle)style;
- (NSString *)titleForButtonStyle:(PFActionButtonStyle)style;

@end
