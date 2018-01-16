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

class SimpleTableViewController: PFQueryTableViewController {

    // MARK: Init

    convenience init(className: String?) {
        self.init(style: .plain, className: className)

        title = "Simple Table"
        pullToRefreshEnabled = true
        paginationEnabled = false
    }

    // MARK: Data

    override func queryForTable() -> PFQuery<PFObject> {
        return super.queryForTable().order(byAscending: "priority")
    }

    // MARK: TableView

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, object: PFObject?) -> PFTableViewCell? {
        let cellIdentifier = "cell"

        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? PFTableViewCell
        if cell == nil {
            cell = PFTableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }

        cell?.textLabel?.text = object?["title"] as? String

        var subtitle: String
        if let priority = object?["priority"] as? Int {
            subtitle = "Priority: \(priority)"
        } else {
            subtitle = "No Priority"
        }
        cell?.detailTextLabel?.text = subtitle

        return cell
    }

}
