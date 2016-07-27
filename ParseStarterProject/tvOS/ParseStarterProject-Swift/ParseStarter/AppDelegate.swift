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
        // ****************************************************************************
        // Initialize Parse SDK
        // ****************************************************************************

        let configuration = ParseClientConfiguration {
            // Add your Parse applicationId:
            $0.applicationId = "your_application_id"
            // Uncomment and add your clientKey (it's not required if you are using Parse Server):
            $0.clientKey = "your_client_key"

            // Uncomment the following line and change to your Parse Server address;
            $0.server = "https://YOUR_PARSE_SERVER/parse"
        }
        Parse.initializeWithConfiguration(configuration)

        PFUser.enableAutomaticUser()

        let defaultACL = PFACL()
        defaultACL.publicReadAccess = true // If you would like all objects to be private by default, remove this line.
        PFACL.setDefaultACL(defaultACL, withAccessForCurrentUser: true)

        return true
    }

}
