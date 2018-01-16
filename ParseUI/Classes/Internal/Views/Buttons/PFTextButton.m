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

#import "PFTextButton.h"

@implementation PFTextButton

#pragma mark -
#pragma mark Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.titleLabel.font = [UIFont systemFontOfSize:16.0f];
    [self setTitleColor:[UIColor colorWithRed:82.0f/255.0f
                                        green:152.0f/255.0f
                                         blue:252.0f/255.0f
                                        alpha:1.0f]
               forState:UIControlStateNormal];

    return self;
}

#pragma mark -
#pragma mark UIView

- (CGSize)sizeThatFits:(CGSize)boundingSize {
    CGSize size = [super sizeThatFits:boundingSize];
    size.width = MAX(32.0f, boundingSize.width);
    size.height = MIN(32.0f, boundingSize.height);
    return size;
}

@end
