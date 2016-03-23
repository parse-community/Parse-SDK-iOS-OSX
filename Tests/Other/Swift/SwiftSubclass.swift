/**
* Copyright (c) 2015-present, Parse, LLC.
* All rights reserved.
*
* This source code is licensed under the BSD-style license found in the
* LICENSE file in the root directory of this source tree. An additional grant
* of patent rights can be found in the PATENTS file in the same directory.
*/

import Foundation

import Parse

@objc
public class SwiftSubclass: PFObject, PFSubclassing {
    @NSManaged public var primitiveProperty: Int
    @NSManaged public var objectProperty: AnyObject?

    @NSManaged public var relationProperty: PFRelation?
    @NSManaged public var badProperty: CGPoint

    public static func parseClassName() -> String {
        return "SwiftSubclass"
    }

    func test_validateSwiftImport() {
        let _ = SwiftSubclass(withoutDataWithObjectId: "")
    }
}
