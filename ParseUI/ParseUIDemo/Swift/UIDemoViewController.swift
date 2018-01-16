/*
*  Copyright (c) 2015, Parse, LLC. All rights reserved.
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

import UIKit

import Parse
import ParseUI

enum UIDemoType : Int {
    case LogInDefault
    case LogInUsernamePassword
    case LogInPasswordForgotten
    case LogInDone
    case LogInEmailAsUsername
    case LogInFacebook
    case LogInFacebookAndTwitter
    case LogInAll
    case LogInAllNavigation
    case LogInCustomizedLogoAndBackground
    case SignUpDefault
    case SignUpUsernamePassword
    case SignUpUsernamePasswordEmail
    case SignUpUsernamePasswordEmailSignUp
    case SignUpAll
    case SignUpEmailAsUsername
    case SignUpMinPasswordLength
    case SimpleTable
    case PaginatedTable
    case SectionedTable
    case StoryboardTable
    case DeletionTable
    case ImageTableDefaultStyle
    case ImageTableSubtitleStyle
    case SimpleCollection
    case PaginatedCollection
    case SectionedCollection
    case StoryboardCollection
    case DeletionCollection
    case ImageCollection
    case Product
    case CustomizedProduct

    static var count: Int {
        var count = 0
        while let _ = self.init(rawValue: count) {
            count = count + 1
        }
        return count
    }
}

extension UIDemoType : CustomStringConvertible {

    var description: String {
        switch (self) {
        case .LogInDefault:
            return "Log In Default"
        case .LogInUsernamePassword:
            return "Log In Username and Password"
        case .LogInPasswordForgotten:
            return "Log In Password Forgotten"
        case .LogInDone:
            return "Log In Done Button"
        case .LogInEmailAsUsername:
            return "Log In Email as Username"
        case .LogInFacebook:
            return "Log In Facebook"
        case .LogInFacebookAndTwitter:
            return "Log In Facebook and Twitter"
        case .LogInAll:
            return "Log In All"
        case .LogInAllNavigation:
            return "Log In All as Navigation"
        case .LogInCustomizedLogoAndBackground:
            return "Log In Customized Background"
        case .SignUpDefault:
            return "Sign Up Default"
        case .SignUpUsernamePassword:
            return "Sign Up Username and Password"
        case .SignUpUsernamePasswordEmail:
            return "Sign Up Email"
        case .SignUpUsernamePasswordEmailSignUp:
            return "Sign Up Email And SignUp"
        case .SignUpAll:
            return "Sign Up All"
        case .SignUpEmailAsUsername:
            return "Sign Up Email as Username"
        case .SignUpMinPasswordLength:
            return "Sign Up Minimum Password Length"
        case .SimpleTable:
            return "Simple Table"
        case .PaginatedTable:
            return "Paginated Table"
        case .SectionedTable:
            return "Sectioned Table"
        case .StoryboardTable:
            return "Simple Storyboard Table"
        case .DeletionTable:
            return "Deletion Table"
        case .ImageTableDefaultStyle:
            return "Remote Image Table Default Style"
        case .ImageTableSubtitleStyle:
            return "Remote Image Table Subtitle Style"
        case .SimpleCollection:
            return "Simple Collection"
        case .PaginatedCollection:
            return "Paginated Collection"
        case .SectionedCollection:
            return "Sectioned Collection"
        case .StoryboardCollection:
            return "Simple Storyboard Collection"
        case .DeletionCollection:
            return "Deletion Collection"
        case .ImageCollection:
            return "Remote Image Collection"
        case .Product:
            return "Product"
        case .CustomizedProduct:
            return "Customized Product"
        }
    }

}

class UIDemoViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "ParseUI Demo"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

}

extension UIDemoViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UIDemoType.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = UIDemoType(rawValue: indexPath.row)?.description
        return cell
    }
}

extension UIDemoViewController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let demoType = UIDemoType(rawValue: indexPath.row) {
            switch (demoType) {
                // -----
                // PFLogInViewController
                // -----
            case .LogInDefault:
                let logInViewController = PFLogInViewController()
                logInViewController.delegate = self
                present(logInViewController, animated: true, completion: nil)
            case .LogInUsernamePassword:
                let logInViewController = PFLogInViewController()
                logInViewController.delegate = self
                logInViewController.fields = [.usernameAndPassword, .dismissButton]
                present(logInViewController, animated: true, completion: nil)
            case .LogInPasswordForgotten:
                let logInViewController = PFLogInViewController()
                logInViewController.delegate = self
                logInViewController.fields = [.usernameAndPassword, .passwordForgotten, .dismissButton]
                present(logInViewController, animated: true, completion: nil)
            case .LogInDone:
                let logInViewController = PFLogInViewController()
                logInViewController.delegate = self
                logInViewController.fields = [.usernameAndPassword, .logInButton, .dismissButton]
                present(logInViewController, animated: true, completion: nil)
            case .LogInEmailAsUsername:
                let logInViewController = PFLogInViewController()
                logInViewController.delegate = self
                logInViewController.fields = [.usernameAndPassword, .logInButton, .signUpButton, .dismissButton]
                logInViewController.emailAsUsername = true
                present(logInViewController, animated: true, completion: nil)
            case .LogInFacebook:
                let logInViewController = PFLogInViewController()
                logInViewController.delegate = self
                logInViewController.fields = [.usernameAndPassword, .facebook, .dismissButton]
                present(logInViewController, animated: true, completion: nil)
            case .LogInFacebookAndTwitter:
                let logInViewController = PFLogInViewController()
                logInViewController.delegate = self
                logInViewController.fields = [.facebook, .twitter, .dismissButton]
                present(logInViewController, animated: true, completion: nil)
            case .LogInAll:
                let logInViewController = PFLogInViewController()
                logInViewController.delegate = self
                logInViewController.fields = [.usernameAndPassword, .passwordForgotten, .logInButton, .facebook, .twitter, .signUpButton, .dismissButton]
                if let signUpController = logInViewController.signUpController {
                    signUpController.delegate = self
                    signUpController.fields = [.usernameAndPassword, .email, .additional, .signUpButton, .dismissButton]
                }
                present(logInViewController, animated: true, completion: nil)
            case .LogInAllNavigation:
                let logInViewController = PFLogInViewController()
                logInViewController.delegate = self
                logInViewController.fields = [.usernameAndPassword, .passwordForgotten, .logInButton, .facebook, .twitter, .signUpButton, .dismissButton]
                if let signUpViewController = logInViewController.signUpController {
                    signUpViewController.delegate = self
                    signUpViewController.fields = [.usernameAndPassword, .email, .additional, .signUpButton, .dismissButton]
                }
                navigationController?.pushViewController(logInViewController, animated: true)
            case .LogInCustomizedLogoAndBackground:
                let logInViewController = CustomLogInViewController()
                logInViewController.delegate = self
                logInViewController.fields = [.default, .facebook, .twitter]

                let signUpViewController = CustomSignUpViewController()
                signUpViewController.delegate = self
                signUpViewController.fields = .default

                logInViewController.signUpController = signUpViewController
                present(logInViewController, animated: true, completion: nil)
                // -----
                // PFSignUpViewController
                // -----
            case .SignUpDefault:
                let signUpViewController = PFSignUpViewController()
                signUpViewController.delegate = self
                present(signUpViewController, animated: true, completion: nil)
            case .SignUpUsernamePassword:
                let signUpViewController = PFSignUpViewController()
                signUpViewController.delegate = self
                signUpViewController.fields = [.usernameAndPassword, .dismissButton]
                present(signUpViewController, animated: true, completion: nil)
            case .SignUpUsernamePasswordEmail:
                let signUpViewController = PFSignUpViewController()
                signUpViewController.delegate = self
                signUpViewController.fields = [.usernameAndPassword, .email, .dismissButton]
                present(signUpViewController, animated: true, completion: nil)
            case .SignUpUsernamePasswordEmailSignUp:
                let signUpViewController = PFSignUpViewController()
                signUpViewController.delegate = self
                signUpViewController.fields = [.usernameAndPassword, .email, .signUpButton, .dismissButton]
                present(signUpViewController, animated: true, completion: nil)
            case .SignUpAll:
                let signUpViewController = PFSignUpViewController()
                signUpViewController.delegate = self
                signUpViewController.fields = [.usernameAndPassword, .email, .additional, .signUpButton, .dismissButton]
                present(signUpViewController, animated: true, completion: nil)
            case .SignUpEmailAsUsername:
                let signUpViewController = PFSignUpViewController()
                signUpViewController.delegate = self
                signUpViewController.fields = [.usernameAndPassword, .signUpButton, .dismissButton]
                signUpViewController.emailAsUsername = true
                present(signUpViewController, animated: true, completion: nil)
            case .SignUpMinPasswordLength:
                let signUpViewController = PFSignUpViewController()
                signUpViewController.delegate = self
                signUpViewController.fields = [.usernameAndPassword, .signUpButton, .dismissButton]
                signUpViewController.minPasswordLength = 6
                present(signUpViewController, animated: true, completion: nil)
                // -----
                // PFQueryTableViewController
                // -----
            case .SimpleTable:
                let tableViewController = SimpleTableViewController(className: "Todo")
                navigationController?.pushViewController(tableViewController, animated: true)
            case .PaginatedTable:
                let tableViewController = PaginatedTableViewController(className: "Todo")
                navigationController?.pushViewController(tableViewController, animated: true)
            case .SectionedTable:
                let tableViewController = SectionedTableViewController(className: "Todo")
                navigationController?.pushViewController(tableViewController, animated: true)
            case .StoryboardTable:
                let storyboard = UIStoryboard(name: "SimpleQueryTableStoryboard-Swift", bundle: nil)
                let tableViewController = storyboard.instantiateViewController(withIdentifier: "StoryboardTableViewController") as? StoryboardTableViewController
                navigationController?.pushViewController(tableViewController!, animated: true)
            case .DeletionTable:
                let tableViewController = DeletionTableViewController(className: "PublicTodo");
                navigationController?.pushViewController(tableViewController, animated: true);
            case .ImageTableDefaultStyle:
                let tableViewController = PFQueryTableViewController(className: "App")
                tableViewController.imageKey = "icon"
                tableViewController.textKey = "name"
                tableViewController.paginationEnabled = false
                tableViewController.placeholderImage = UIImage(named: "Icon.png")
                navigationController?.pushViewController(tableViewController, animated: true)
            case .ImageTableSubtitleStyle:
                let tableViewController = SubtitleImageTableViewController(className: "App")
                tableViewController.imageKey = "icon"
                tableViewController.textKey = "name"
                tableViewController.paginationEnabled = false
                tableViewController.placeholderImage = UIImage(named: "Icon.png")
                navigationController?.pushViewController(tableViewController, animated: true)
                // -----
                // PFQueryCollectionViewController
                // -----
            case .SimpleCollection:
                let collectionViewController = SimpleCollectionViewController(className: "Todo")
                navigationController?.pushViewController(collectionViewController, animated: true)
            case .PaginatedCollection:
                let collectionViewController = PaginatedCollectionViewController(className: "Todo")
                navigationController?.pushViewController(collectionViewController, animated: true)
            case .SectionedCollection:
                let collectionViewController = SectionedCollectionViewController(className: "Todo")
                navigationController?.pushViewController(collectionViewController, animated: true)
            case .StoryboardCollection:
                let storyboard = UIStoryboard(name: "SimpleQueryCollectionStoryboard-Swift", bundle: nil)
                let collectionViewController = storyboard.instantiateViewController(withIdentifier: "StoryboardCollectionViewController") as? StoryboardCollectionViewController
                navigationController?.pushViewController(collectionViewController!, animated: true)
            case .DeletionCollection:
                let collectionViewController = DeletionCollectionViewController(className: "PublicTodo");
                navigationController?.pushViewController(collectionViewController, animated: true)
            case .ImageCollection:
                let collectionViewController = SubtitleImageCollectionViewController(className: "App")
                navigationController?.pushViewController(collectionViewController, animated: true)
                // -----
                // PFProductTableViewController
                // -----
            case .Product:
                let productTableViewController = PFProductTableViewController()
                navigationController?.pushViewController(productTableViewController, animated: true)
            case .CustomizedProduct:
                let productTableViewController = CustomProductTableViewController()
                navigationController?.pushViewController(productTableViewController, animated: true)
            }
        }
    }

}

extension UIDemoViewController : PFLogInViewControllerDelegate {

    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        dismiss(animated: true, completion: nil)
    }

}

extension UIDemoViewController : PFSignUpViewControllerDelegate {

    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        dismiss(animated: true, completion: nil)
    }

}
