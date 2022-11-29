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

#import "PFImage.h"

#import "PFColor.h"
#import "PFRect.h"
#import "PFResources.h"

@implementation PFImage

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, (CGRect){.size = size});

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius {
    CGSize size = CGSizeMake(cornerRadius * 2.0f + 1.0f, cornerRadius * 2.0f + 1.0f);

    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);

    [color setFill];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:PFRectMakeWithSize(size) cornerRadius:cornerRadius];
    [path fill];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(cornerRadius,
                                                                cornerRadius,
                                                                cornerRadius,
                                                                cornerRadius)
                                  resizingMode:UIImageResizingModeStretch];

    return image;
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    return [self imageWithColor:color size:CGSizeMake(1.0f, 1.0f)];
}

+ (UIImage *)imageNamed:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    if (image) {
        // If there is an external override for the image at the given path, use it.
        return image;
    }

    NSString *fileExtension = [imageName pathExtension];
    NSMutableString *filenameWithoutExtension = [[imageName stringByDeletingPathExtension] mutableCopy];
    [filenameWithoutExtension replaceOccurrencesOfString:@"-\\."
                                              withString:@"_"
                                                 options:NSRegularExpressionSearch
                                                   range:NSMakeRange(0, [filenameWithoutExtension length])];

    NSData *data = nil;

    int imageScale = (int)ceil([UIScreen mainScreen].scale);
    while (data == nil && imageScale > 1) {
        NSString *selectorName = [filenameWithoutExtension stringByAppendingFormat:@"%dx_%@",
                                  imageScale,
                                  fileExtension];
        SEL selector = NSSelectorFromString(selectorName);
        if ([PFResources respondsToSelector:selector]) {
            data = (NSData *)[PFResources performSelector:selector];
        }
        if (data == nil) {
            imageScale--;
        }
    }
    if (!data) {
        NSString *selectorName = [filenameWithoutExtension stringByAppendingFormat:@"_%@", fileExtension];
        SEL selector = NSSelectorFromString(selectorName);
        data = (NSData *)[PFResources performSelector:selector];
    }
    image = [[UIImage alloc] initWithData:data];

    // we need to indicate to the framework that the data is already a 2x image, otherwise the framework
    // stretches the image by 2x again. To do that, we drop down to CGImage layer to take advantage of
    // +[UIImage imageWithCGImage:scale:orientation]
    return [UIImage imageWithCGImage:image.CGImage scale:imageScale orientation:image.imageOrientation];
}

@end
