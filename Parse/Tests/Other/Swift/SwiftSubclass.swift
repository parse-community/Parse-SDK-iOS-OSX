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

    public var relationProperty: PFRelation<PFObject> {
        return relation(forKey: "relationProperty")
    }
    @NSManaged public var badProperty: CGPoint

    public static func parseClassName() -> String {
        return "SwiftSubclass"
    }

    func test_validateSwiftImport() {
        let _ = SwiftSubclass(withoutDataWithObjectId: "")
    }

    func test_properACLSetters() {
        let acl = PFACL()
        acl.hasPublicReadAccess = true
        acl.hasPublicWriteAccess = true
        _ = acl.hasPublicWriteAccess
        _ = acl.hasPublicReadAccess
    }

    func testPolygon() {
        let points = [[0,0], [0,1], [1,1], [1,0]]
        let polygon = PFPolygon(coordinates: points)

        let geoPoint1 = PFGeoPoint(latitude: 10.0, longitude: 20.0)
        let geoPoint2 = PFGeoPoint(latitude: 20.0, longitude: 30.0)
        let geoPoint3 = PFGeoPoint(latitude: 30.0, longitude: 40.0)
        let query = PFQuery(className: "Locations")
        query.whereKey("location", withinPolygon: [geoPoint1, geoPoint2, geoPoint3])

        let geoPoint = PFGeoPoint(latitude: 0.5, longitude: 0.5)
        let q2 = PFQuery(className: "Locations")
        q2.whereKey("bounds", polygonContains: geoPoint)

        let inside = PFGeoPoint(latitude: 0.5, longitude: 0.5)
        let outside = PFGeoPoint(latitude: 10, longitude: 10)
        // Returns true
        polygon.contains(inside)
        // Returns false
        polygon.contains(outside)
    }

    func testFullTExt() {
        let query = PFQuery(className: "BarbecueSauce")
        query.whereKey("name", matchesText: "bbq")
    }

    func testOther() {
        let query = PFQuery(className: "BarbecueSauce")
        query.whereKey("name", matchesText: "bbq")
        query.order(byAscending: "$score")
        query.selectKeys(["$score"])
        query.findObjectsInBackground { (objects, error) in
            guard let objects = objects else {
                return
            }
            objects.forEach { (object) in
                print("Successfully retrieved \(String(describing: object["$score"])) weight / rank.");
            }
        }
    }

    @objc
    public func testDoIt() {
        let _ = PFQuery(className: "BarbecueSauce")
    }
}
