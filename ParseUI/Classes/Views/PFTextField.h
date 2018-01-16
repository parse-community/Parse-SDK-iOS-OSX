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

#ifdef COCOAPODS
#import "ParseUIConstants.h"
#else
#import <ParseUI/ParseUIConstants.h>
#endif


NS_ASSUME_NONNULL_BEGIN

/**
 `PFTextFieldSeparatorStyle` bitmask specifies the style of the separators,
 that should be used for a given `PFTextField`.

 @see PFTextField
 */
typedef NS_OPTIONS(uint8_t, PFTextFieldSeparatorStyle){
    /** No separators are visible. */
    PFTextFieldSeparatorStyleNone = 0,
    /** Separator on top of the text field. */
    PFTextFieldSeparatorStyleTop = 1 << 0,
    /** Separator at the bottom of the text field. */
    PFTextFieldSeparatorStyleBottom = 1 << 1
};

/**
 `PFTextField` class serves as a stylable subclass of `UITextField`.
 It includes styles that are specific to `ParseUI` framework and allows advanced customization.
 */
@interface PFTextField : UITextField

/**
 Separator style bitmask that should be applied to this textfield.

 Default: `PFTextFieldSeparatorStyleNone`

 @see PFTextFieldSeparatorStyle
 */
@property (nonatomic, assign) PFTextFieldSeparatorStyle separatorStyle;

/**
 Color that should be used for the separators, if they are visible.

 Default: `227,227,227,1.0`.
 */
@property (nullable, nonatomic, strong) UIColor *separatorColor UI_APPEARANCE_SELECTOR;

/**
 This method is a convenience initializer that sets both `frame` and `separatorStyle` for an instance of `PFTextField.`

 @param frame          The frame rectangle for the view, measured in points.
 @param separatorStyle Initial separator style to use.

 @return An initialized instance of `PFTextField` or `nil` if it couldn't be created.
 */
- (instancetype)initWithFrame:(CGRect)frame separatorStyle:(PFTextFieldSeparatorStyle)separatorStyle;

@end

NS_ASSUME_NONNULL_END
