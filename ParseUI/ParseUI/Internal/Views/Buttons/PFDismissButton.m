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

#import "PFDismissButton.h"

#import "PFRect.h"

@implementation PFDismissButton

#pragma mark -
#pragma mark Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    [self setImage:[self _defaultImage] forState:UIControlStateNormal];

    return self;
}

#pragma mark -
#pragma mark Init

- (UIImage *)_defaultImage {
    CGRect imageRect = PFRectMakeWithSize(CGSizeMake(22.0f, 22.0f));

    UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, 0.0f);

    [[UIColor colorWithRed:91.0f/255.0f green:107.0f/255.0f blue:118.0f/255.0f alpha:1.0f] setStroke];

    UIBezierPath *path = [UIBezierPath bezierPath];

    [path moveToPoint:CGPointZero];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(imageRect), CGRectGetMaxY(imageRect))];

    [path moveToPoint:CGPointMake(CGRectGetMaxX(imageRect), CGRectGetMinY(imageRect))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(imageRect), CGRectGetMaxY(imageRect))];

    path.lineWidth = 2.0f;

    [path stroke];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)boundingSize {
    CGSize size = CGSizeZero;
    size.width = MIN(22.0f, boundingSize.width);
    size.height = MIN(22.0f, boundingSize.height);
    return size;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect bigBounds = CGRectInset(self.bounds, -22.0f, -22.0f);
    return CGRectContainsPoint(bigBounds, point);
}

@end
