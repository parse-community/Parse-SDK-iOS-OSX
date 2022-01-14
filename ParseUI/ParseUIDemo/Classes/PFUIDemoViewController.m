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

#import "PFUIDemoViewController.h"

#import <ParseUI/ParseUI.h>

#import "CustomLogInViewController.h"
#import "CustomProductTableViewController.h"
#import "CustomSignUpViewController.h"
#import "DeletionCollectionViewController.h"
#import "DeletionTableViewController.h"
#import "PaginatedCollectionViewController.h"
#import "PaginatedTableViewController.h"
#import "SectionedCollectionViewController.h"
#import "SectionedTableViewController.h"
#import "SimpleCollectionViewController.h"
#import "SimpleTableViewController.h"
#import "StoryboardCollectionViewController.h"
#import "StoryboardTableViewController.h"
#import "SubtitleImageCollectionViewController.h"
#import "SubtitleImageTableViewController.h"

typedef NS_ENUM(uint8_t, PFUIDemoType) {
    PFUIDemoTypeSimpleTable,
    PFUIDemoTypePaginatedTable,
    PFUIDemoTypeSectionedTable,
    PFUIDemoTypeStoryboardTable,
    PFUIDemoTypeDeletionTable,
    PFUIDemoTypeSimpleCollection,
    PFUIDemoTypePaginatedCollection,
    PFUIDemoTypeSectionedCollection,
    PFUIDemoTypeStoryboardCollection,
    PFUIDemoTypeDeletionCollection,
    PFUIDemoTypeLogInDefault,
    PFUIDemoTypeLogInUsernamePassword,
    PFUIDemoTypeLogInPasswordForgotten,
    PFUIDemoTypeLogInDone,
    PFUIDemoTypeLogInEmailAsUsername,
    PFUIDemoTypeLogInFacebook,
    PFUIDemoTypeLogInFacebookAndTwitter,
    PFUIDemoTypeLogInAll,
    PFUIDemoTypeLogInAllNavigation,
    PFUIDemoTypeLogInCustomizedLogoAndBackground,
    PFUIDemoTypeSignUpDefault,
    PFUIDemoTypeSignUpUsernamePassword,
    PFUIDemoTypeSignUpUsernamePasswordEmail,
    PFUIDemoTypeSignUpUsernamePasswordEmailSignUp,
    PFUIDemoTypeSignUpAll,
    PFUIDemoTypeSignUpEmailAsUsername,
    PFUIDemoTypeSignUpMinPasswordLength,
    PFUIDemoTypeImageTableDefaultStyle,
    PFUIDemoTypeImageTableSubtitleStyle,
    PFUIDemoTypeImageCollection,
    PFUIDemoTypePurchase,
    PFUIDemoTypeCustomizedPurchase
};

@interface PFUIDemoViewController () <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>
{
    NSArray *_descriptions;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil NS_DESIGNATED_INITIALIZER;

@end

@implementation PFUIDemoViewController

#pragma mark -
#pragma mark Init

- (instancetype)init {
    return [super initWithStyle:UITableViewStylePlain];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self init];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    return [self init];
}

#pragma mark -
#pragma mark View

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.title) {
        self.title = @"ParseUI Demo";
    }
    if (!_descriptions) {
        _descriptions = @[ @"Simple Table",
                           @"Paginated Table",
                           @"Sectioned Table",
                           @"Simple Storyboard Table",
                           @"Deletion Table",
                           @"Simple Collection",
                           @"Paginated Collection",
                           @"Sectioned Collection",
                           @"Simple Storyboard Collection",
                           @"Deletion Collection",
                           @"Log In Default",
                           @"Log In Username and Password",
                           @"Log In Password Forgotten",
                           @"Log In Done Button",
                           @"Log In Email as Username",
                           @"Log In Facebook",
                           @"Log In Facebook and Twitter",
                           @"Log In All",
                           @"Log In All as Navigation",
                           @"Log In Customized Background",
                           @"Sign Up Default",
                           @"Sign Up Username and Password",
                           @"Sign Up Email",
                           @"Sign Up Email And SignUp",
                           @"Sign Up All",
                           @"Sign Up Email as Username",
                           @"Sign Up Minimum Password Length",
                           @"Remote Image Table Default Style",
                           @"Remote Image Table Subtitle Style",
                           @"Remote Image Collection",
                           @"Purchase",
                           @"Custom Purchase" ];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_descriptions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    cell.textLabel.text = _descriptions[indexPath.row];

    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case PFUIDemoTypeSimpleTable: {
            PFQueryTableViewController *controller = [[SimpleTableViewController alloc] initWithClassName:@"Todo"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case PFUIDemoTypePaginatedTable: {
            PFQueryTableViewController *controller = [[PaginatedTableViewController alloc] initWithClassName:@"Todo"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case PFUIDemoTypeSectionedTable: {
            PFQueryTableViewController *controller = [[SectionedTableViewController alloc] initWithClassName:@"Todo"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case PFUIDemoTypeStoryboardTable: {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SimpleQueryTableStoryboard" bundle:NULL];
            StoryboardTableViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"StoryboardTableViewController"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case PFUIDemoTypeDeletionTable: {
            PFQueryTableViewController *controller = [[DeletionTableViewController alloc] initWithClassName:@"PublicTodo"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case PFUIDemoTypeSimpleCollection: {
            SimpleCollectionViewController *controller = [[SimpleCollectionViewController alloc] initWithClassName:@"Todo"];
            [self.navigationController pushViewController:controller animated:YES];
        }
            break;
        case PFUIDemoTypePaginatedCollection: {
            PaginatedCollectionViewController *controller = [[PaginatedCollectionViewController alloc] initWithClassName:@"Todo"];
            [self.navigationController pushViewController:controller animated:YES];
        }
            break;
        case PFUIDemoTypeSectionedCollection: {
            SectionedCollectionViewController *controller = [[SectionedCollectionViewController alloc] initWithClassName:@"Todo"];
            [self.navigationController pushViewController:controller animated:YES];
        }
            break;
        case PFUIDemoTypeStoryboardCollection: {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SimpleQueryCollectionStoryboard" bundle:NULL];
            StoryboardCollectionViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"StoryboardCollectionViewController"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case PFUIDemoTypeDeletionCollection: {
            PFQueryCollectionViewController *controller = [[DeletionCollectionViewController alloc] initWithClassName:@"PublicTodo"];
            [self.navigationController pushViewController:controller animated:YES];
            break;
        }
        case PFUIDemoTypeLogInDefault: {
            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
            logInController.delegate = self;
            [self presentViewController:logInController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeLogInUsernamePassword: {
            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
            logInController.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsDismissButton;
            logInController.delegate = self;
            [self presentViewController:logInController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeLogInPasswordForgotten: {
            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
            logInController.fields = (PFLogInFieldsUsernameAndPassword
                                      | PFLogInFieldsPasswordForgotten
                                      | PFLogInFieldsDismissButton);
            logInController.delegate = self;
            [self presentViewController:logInController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeLogInDone: {
            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
            logInController.fields = (PFLogInFieldsUsernameAndPassword
                                      | PFLogInFieldsLogInButton
                                      | PFLogInFieldsDismissButton);
            logInController.delegate = self;
            [self presentViewController:logInController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeLogInEmailAsUsername: {
            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
            logInController.fields = (PFLogInFieldsUsernameAndPassword
                                      | PFLogInFieldsLogInButton
                                      | PFLogInFieldsDismissButton
                                      | PFLogInFieldsSignUpButton);
            logInController.emailAsUsername = YES;
            logInController.delegate = self;
            [self presentViewController:logInController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeLogInFacebook: {
            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
            logInController.fields = (PFLogInFieldsUsernameAndPassword
                                      | PFLogInFieldsFacebook
                                      | PFLogInFieldsDismissButton);
            logInController.delegate = self;
            [self presentViewController:logInController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeLogInFacebookAndTwitter: {
            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
            logInController.fields = PFLogInFieldsFacebook | PFLogInFieldsTwitter | PFLogInFieldsDismissButton;
            logInController.delegate = self;
            [self presentViewController:logInController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeLogInAll: {
            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
            logInController.fields = (PFLogInFieldsUsernameAndPassword
                                      | PFLogInFieldsLogInButton
                                      | PFLogInFieldsPasswordForgotten
                                      | PFLogInFieldsApple
                                      | PFLogInFieldsFacebook
                                      | PFLogInFieldsTwitter
                                      | PFLogInFieldsSignUpButton
                                      | PFLogInFieldsDismissButton);
            logInController.delegate = self;

            logInController.signUpController.fields = (PFSignUpFieldsUsernameAndPassword
                                                       | PFSignUpFieldsEmail
                                                       | PFSignUpFieldsAdditional
                                                       | PFSignUpFieldsDismissButton
                                                       | PFSignUpFieldsSignUpButton);
            logInController.signUpController.delegate = self;

            [self presentViewController:logInController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeLogInAllNavigation: {
            PFLogInViewController *logInController = [[PFLogInViewController alloc] init];
            logInController.fields = (PFLogInFieldsUsernameAndPassword
                                      | PFLogInFieldsLogInButton
                                      | PFLogInFieldsPasswordForgotten
                                      | PFLogInFieldsFacebook
                                      | PFLogInFieldsTwitter
                                      | PFLogInFieldsSignUpButton
                                      | PFLogInFieldsDismissButton);
            logInController.delegate = self;

            logInController.signUpController.fields = (PFSignUpFieldsUsernameAndPassword
                                                       | PFSignUpFieldsEmail
                                                       | PFSignUpFieldsAdditional
                                                       | PFSignUpFieldsDismissButton
                                                       | PFSignUpFieldsSignUpButton);
            logInController.signUpController.delegate = self;
            [self.navigationController pushViewController:logInController animated:YES];
            break;
        }
        case PFUIDemoTypeLogInCustomizedLogoAndBackground: {
            PFLogInViewController *logInController = [[CustomLogInViewController alloc] init];
            logInController.fields = PFLogInFieldsDefault | PFLogInFieldsFacebook | PFLogInFieldsTwitter;
            logInController.delegate= self;

            PFSignUpViewController *signUpController = [[CustomSignUpViewController alloc] init];
            signUpController.fields = PFSignUpFieldsDefault;
            signUpController.delegate = self;

            logInController.signUpController = signUpController;
            [self presentViewController:logInController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeSignUpDefault: {
            PFSignUpViewController *signUpController = [[PFSignUpViewController alloc] init];
            signUpController.delegate = self;
            [self presentViewController:signUpController animated:YES completion:nil];
        }
            break;
        case PFUIDemoTypeSignUpUsernamePassword: {
            PFSignUpViewController *signUpController = [[PFSignUpViewController alloc] init];
            signUpController.fields = PFSignUpFieldsUsernameAndPassword | PFSignUpFieldsDismissButton;
            signUpController.delegate = self;
            [self presentViewController:signUpController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeSignUpUsernamePasswordEmail: {
            PFSignUpViewController *signUpController = [[PFSignUpViewController alloc] init];
            signUpController.fields = (PFSignUpFieldsUsernameAndPassword
                                       | PFSignUpFieldsEmail
                                       | PFSignUpFieldsDismissButton);
            signUpController.delegate = self;
            [self presentViewController:signUpController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeSignUpUsernamePasswordEmailSignUp: {
            PFSignUpViewController *signUpController = [[PFSignUpViewController alloc] init];
            signUpController.fields = (PFSignUpFieldsUsernameAndPassword
                                       | PFSignUpFieldsEmail
                                       | PFSignUpFieldsSignUpButton
                                       | PFSignUpFieldsDismissButton);
            signUpController.delegate = self;
            [self presentViewController:signUpController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeSignUpAll: {
            PFSignUpViewController *signUpController = [[PFSignUpViewController alloc] init];
            signUpController.fields = (PFSignUpFieldsEmail
                                       | PFSignUpFieldsAdditional
                                       | PFSignUpFieldsSignUpButton
                                       | PFSignUpFieldsDismissButton);
            signUpController.delegate = self;
            signUpController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:signUpController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeSignUpEmailAsUsername: {
            PFSignUpViewController *signUpController = [[PFSignUpViewController alloc] init];
            signUpController.fields = (PFSignUpFieldsUsernameAndPassword
                                       | PFSignUpFieldsSignUpButton
                                       | PFSignUpFieldsDismissButton);
            signUpController.emailAsUsername = YES;
            signUpController.delegate = self;
            [self presentViewController:signUpController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeSignUpMinPasswordLength: {
            PFSignUpViewController *signUpController = [[PFSignUpViewController alloc] init];
            signUpController.fields = (PFSignUpFieldsUsernameAndPassword
                                       | PFSignUpFieldsSignUpButton
                                       | PFSignUpFieldsDismissButton);
            signUpController.minPasswordLength = 6;
            signUpController.delegate = self;
            [self presentViewController:signUpController animated:YES completion:nil];
            break;
        }
        case PFUIDemoTypeImageTableDefaultStyle: {
            PFQueryTableViewController *tableViewController = [[PFQueryTableViewController alloc] initWithClassName:@"App"];
            tableViewController.imageKey = @"icon";
            tableViewController.textKey = @"name";
            tableViewController.paginationEnabled = NO;
            tableViewController.placeholderImage = [UIImage imageNamed:@"Icon.png"];
            [self.navigationController pushViewController:tableViewController animated:YES];
            break;
        }
        case PFUIDemoTypeImageTableSubtitleStyle: {
            SubtitleImageTableViewController *tableViewController = [[SubtitleImageTableViewController alloc] initWithClassName:@"App"];
            tableViewController.imageKey = @"icon";
            tableViewController.textKey = @"name";
            tableViewController.paginationEnabled = NO;
            tableViewController.placeholderImage = [UIImage imageNamed:@"Icon.png"];
            [self.navigationController pushViewController:tableViewController animated:YES];
            break;
        }
        case PFUIDemoTypeImageCollection: {
            SubtitleImageCollectionViewController *controller = [[SubtitleImageCollectionViewController alloc] initWithClassName:@"App"];
            [self.navigationController pushViewController:controller animated:YES];
        }
            break;
        case PFUIDemoTypePurchase: {
            PFProductTableViewController *purchaseController = [[PFProductTableViewController alloc] init];
            [self.navigationController pushViewController:purchaseController animated:YES];
            break;
        }
        case PFUIDemoTypeCustomizedPurchase: {
            CustomProductTableViewController *purchaseController = [[CustomProductTableViewController alloc] init];
            [self.navigationController pushViewController:purchaseController animated:YES];
        }
    }
}

#pragma mark -
#pragma mark PFLogInViewControllerDelegate

- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    // Do nothing, as the view controller dismisses itself
}

#pragma mark -
#pragma mark PFSignUpViewControllerDelegate

- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    // Do nothing, as the view controller dismisses itself
}

@end
