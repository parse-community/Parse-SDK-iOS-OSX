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

class SubtitleImageCollectionViewController: PFQueryCollectionViewController {

    // MARK: Init

    convenience init(className: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)
        layout.minimumInteritemSpacing = 5.0
        self.init(collectionViewLayout: layout, className: className)

        title = "Image Collection"
        pullToRefreshEnabled = true
        paginationEnabled = false
    }

    // MARK: UIViewController

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            let bounds = UIEdgeInsetsInsetRect(view.bounds, layout.sectionInset)
            let sideLength = min(bounds.width, bounds.height) / 2.0 - layout.minimumInteritemSpacing
            layout.itemSize = CGSize(width: sideLength, height: sideLength)
        }
    }

    // MARK: CollectionView

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath, object: PFObject?) -> PFCollectionViewCell? {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath, object: object)

        cell?.textLabel.textAlignment = .center
        cell?.textLabel.text = object?["name"] as? String

        cell?.imageView.file = object?["icon"] as? PFFileObject
        if cell?.imageView.image == nil {
            cell?.imageView.image = UIImage(named: "Icon.png")
            cell?.imageView.loadInBackground()
        }

        cell?.contentView.layer.borderWidth = 1.0
        cell?.contentView.layer.borderColor = UIColor.lightGray.cgColor
        
        return cell
    }
    
}
