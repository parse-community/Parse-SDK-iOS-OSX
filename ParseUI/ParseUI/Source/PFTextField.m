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

#import "PFTextField.h"

#import "PFColor.h"

@implementation PFTextField

#pragma mark -
#pragma mark Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.backgroundColor = [PFColor textFieldBackgroundColor];
    self.textColor = [PFColor textFieldTextColor];

    self.font = [UIFont systemFontOfSize:17.0f];

    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    _separatorColor = [PFColor textFieldSeparatorColor];

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame separatorStyle:(PFTextFieldSeparatorStyle)separatorStyle {
    self = [self initWithFrame:frame];
    if (!self) return nil;

    _separatorStyle = separatorStyle;

    return self;
}

#pragma mark -
#pragma mark Accessors

- (void)setPlaceholder:(NSString *)placeholder {
    NSDictionary *attributes = @{ NSForegroundColorAttributeName : [PFColor textFieldPlaceholderColor] };
    self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:attributes];
}

- (void)setSeparatorStyle:(PFTextFieldSeparatorStyle)separatorStyle {
    if (self.separatorStyle != separatorStyle) {
        _separatorStyle = separatorStyle;
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    const CGRect bounds = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (self.separatorStyle != PFTextFieldSeparatorStyleNone) {
        [self.separatorColor setFill];
    }

    if (self.separatorStyle & PFTextFieldSeparatorStyleTop) {
        CGRect borderRect = CGRectMake(0.0f, 0.0f, CGRectGetWidth(bounds), 1.0f);
        CGContextFillRect(context, borderRect);
    }

    if (self.separatorStyle & PFTextFieldSeparatorStyleBottom) {
        CGRect borderRect = CGRectMake(0.0f, CGRectGetMaxY(bounds) - 1.0f, CGRectGetWidth(bounds), 1.0f);
        CGContextFillRect(context, borderRect);
    }
}

#pragma mark -
#pragma mark Frame

- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectMake(20.0f, 0.0f, CGRectGetWidth(bounds) - 30.0f, CGRectGetHeight(bounds));
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

#pragma mark -
#pragma mark Sizing

- (CGSize)sizeThatFits:(CGSize)boundingSize {
    CGSize size = CGSizeZero;
    size.width = boundingSize.width;
    size.height = MIN(44.0f, boundingSize.height);
    return size;
}

@end
