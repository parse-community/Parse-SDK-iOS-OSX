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

#import "PFRect.h"

CGRect PFRectMakeWithOriginSize(CGPoint origin, CGSize size) {
    return CGRectMake(origin.x, origin.y, size.width, size.height);
}

CGRect PFRectMakeWithOrigin(CGPoint origin) {
    return PFRectMakeWithOriginSize(origin, CGSizeZero);
}

CGRect PFRectMakeWithSize(CGSize size) {
    return PFRectMakeWithOriginSize(CGPointZero, size);
}

CGRect PFRectMakeWithSizeCenteredInRect(CGSize size, CGRect rect) {
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGPoint origin = CGPointMake(floorf(center.x - size.width / 2.0f),
                                 floorf(center.y - size.height / 2.0f));
    return PFRectMakeWithOriginSize(origin, size);
}

CGSize PFSizeMin(CGSize size1, CGSize size2) {
    CGSize size = CGSizeZero;
    size.width = MIN(size1.width, size2.width);
    size.height = MIN(size1.height, size2.height);
    return size;
}
