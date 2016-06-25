/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

import UIKit

import Parse

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    //--------------------------------------
    // MARK: - UIApplicationDelegate
    //--------------------------------------

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let configuration = ParseClientConfiguration {
            $0.applicationId = "your_application_id"
            $0.clientKey     = "your_client_key"
            $0.server        = "https://YOUR_PARSE_SERVER/parse"
        }
        Parse.initializeWithConfiguration(configuration)

        PFUser.enableAutomaticUser()

        let defaultACL = PFACL()
        defaultACL.publicReadAccess = true // If you would like all objects to be private by default, remove this line.
        PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)

        return true
    }

}
