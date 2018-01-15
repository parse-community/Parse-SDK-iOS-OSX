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
#import "PFQueryTableViewController.h"
#else
#import <ParseUI/ParseUIConstants.h>
#import <ParseUI/PFQueryTableViewController.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 `PFProductTableViewController` displays in-app purchase products stored on Parse.
 In addition to setting up in-app purchases in iTunes Connect, the app developer needs
 to register product information on Parse, in the Product class.
 */
@interface PFProductTableViewController : PFQueryTableViewController

/**
 Initializes a product table view controller.

 @param style The UITableViewStyle for the table

 @return An initialized `PFProductTableViewController` object or `nil` if the object couldn't be created.
 */
- (instancetype)initWithStyle:(UITableViewStyle)style NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
