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

class SectionedTableViewController: PFQueryTableViewController {

    var sections: [Int: [PFObject]] = Dictionary()
    var sectionKeys: [Int] = Array()

    // MARK: Init

    convenience init(className: String?) {
        self.init(style: .plain, className: className)

        title = "Sectioned Table"
        pullToRefreshEnabled = true
    }

    // MARK: Data

    override func objectsDidLoad(_ error: Error?) {
        super.objectsDidLoad(error)

        sections.removeAll(keepingCapacity: false)
        if let objects = objects {
            for object in objects {
                let priority = (object["priority"] as? Int) ?? 0
                var array = sections[priority] ?? Array()
                array.append(object)
                sections[priority] = array
            }
        }
        sectionKeys = sections.keys.sorted(by: <)

        tableView.reloadData()
    }

    override func object(at indexPath: IndexPath?) -> PFObject? {
        if let indexPath = indexPath {
            let array = sections[sectionKeys[indexPath.section]]
            return array?[indexPath.row]
        }
        return nil
    }
}

extension SectionedTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let array = sections[sectionKeys[section]]
        return array?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Priority \(sectionKeys[section])"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt: IndexPath, object: PFObject?) -> PFTableViewCell? {
        let cellIdentifier = "cell"

        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? PFTableViewCell
        if cell == nil {
            cell = PFTableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }

        cell?.textLabel?.text = object?["title"] as? String

        return cell
    }

}
