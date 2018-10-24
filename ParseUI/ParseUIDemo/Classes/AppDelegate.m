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

#import "AppDelegate.h"

#import <Parse/Parse.h>
#import <ParseTwitterUtils/ParseTwitterUtils.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKApplicationDelegate.h>

#import "PFUIDemoViewController.h"

@implementation AppDelegate

#pragma mark -
#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Parse setApplicationId:@"UdNpOP2XFoEiXLZEBDl6xONmCMH8VjETmnEsl0xJ"
                  clientKey:@"wNJFho0fQaQFQ2Fe1x9b67lVBakJiAtFj1Uz30A9"];
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    [PFTwitterUtils initializeWithConsumerKey:@"3Q9hMEKqqSg4ie2pibZ2sVJuv"
                               consumerSecret:@"IEZ9wv2d1EpXNGFKGp7sAGdxRtyqtPwygyciFZwTHTGhPp4FMj"];

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[PFUIDemoViewController alloc] init]];
    [self.window makeKeyAndVisible];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self _setupTestData];
    });

    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

#pragma mark -
#pragma mark Test Data

- (void)_setupTestData {
    NSArray *todoTitles = @[ @"Build Parse",
                             @"Make everything awesome",
                             @"Go out for the longest run",
                             @"Do more stuff",
                             @"Conquer the world",
                             @"Build a house",
                             @"Grow a tree",
                             @"Be awesome",
                             @"Setup an app",
                             @"Do stuff",
                             @"Buy groceries",
                             @"Wash clothes" ];

    NSMutableArray *objects = [NSMutableArray array];

    PFQuery *query = [PFQuery queryWithClassName:@"Todo"];
    NSArray *todos = [query findObjects];
    if ([todos count] == 0) {
        int count = 0;
        for (NSString *title in todoTitles) {
            int priority = count % 3;

            PFObject *todo = [[PFObject alloc] initWithClassName:@"Todo"];
            todo[@"title"] = title;
            todo[@"priority"] = @(priority);
            [objects addObject:todo];

            count++;
        }
    }

    NSArray *appNames = @[ @"Anypic",
                           @"Anywall",
                           @"f8" ];

    PFQuery *appsQuery = [PFQuery queryWithClassName:@"App"];
    NSArray *apps = [appsQuery findObjects];
    if ([apps count] == 0) {
        for (NSUInteger i = 0; i < 3; i++) {
            NSString *name = [NSString stringWithFormat:@"%d", (int)i];
            NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"png"];
            NSData *data = [NSData dataWithContentsOfFile:path];

            PFFileObject *file = [PFFileObject fileWithName:[path lastPathComponent] data:data];

            PFObject *object = [[PFObject alloc] initWithClassName:@"App"];
            object[@"icon"] = file;
            object[@"name"] = appNames[i];
            [objects addObject:object];
        }
    }

    if ([objects count] != 0) {
        [PFObject saveAll:objects];
    }
}

@end
