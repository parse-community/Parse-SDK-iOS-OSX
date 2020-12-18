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

class SimpleCollectionReusableView : UICollectionReusableView {
    let label: UILabel = UILabel(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.textAlignment = .center
        addSubview(label)
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        label.textAlignment = .center
        addSubview(label)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        label.frame = bounds
    }
}

class SectionedCollectionViewController: PFQueryCollectionViewController {

    var sections: [Int: [PFObject]] = Dictionary()
    var sectionKeys: [Int] = Array()

    // MARK: Init

    convenience init(className: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
        layout.minimumInteritemSpacing = 5.0
        self.init(collectionViewLayout: layout, className: className)

        title = "Sectioned Collection"
        if #available(iOS 10.0, *) {
            pullToRefreshEnabled = true
        } else {
            // Fallback on earlier versions
        }
    }

    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.register(SimpleCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            let bounds = view.bounds.inset(by: layout.sectionInset)
            let sideLength = min(bounds.width, bounds.height) / 2.0 - layout.minimumInteritemSpacing
            layout.itemSize = CGSize(width: sideLength, height: sideLength)
        }
    }

    // MARK: Data

    override func objectsDidLoad(_ error: Error?) {
        super.objectsDidLoad(error)

        sections.removeAll(keepingCapacity: false)
        for object in objects {
            let priority = (object["priority"] as? Int) ?? 0
            var array = sections[priority] ?? Array()
            array.append(object)
            sections[priority] = array
        }
        sectionKeys = sections.keys.sorted(by: <)

        collectionView?.reloadData()
    }

    override func object(at indexPath: IndexPath?) -> PFObject? {
        if let indexPath = indexPath {
            let array = sections[sectionKeys[indexPath.section]]
            return array?[indexPath.row]
        }
        return nil
    }

}

extension SectionedCollectionViewController {


    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let array = sections[sectionKeys[section]]
        return array?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath, object: PFObject?) -> PFCollectionViewCell? {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath, object: object)

        cell?.textLabel.textAlignment = .center
        cell?.textLabel.text = object?["title"] as? String

        cell?.contentView.layer.borderWidth = 1.0
        cell?.contentView.layer.borderColor = UIColor.lightGray.cgColor

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader,
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as? SimpleCollectionReusableView {
                view.label.text = "Priority \(sectionKeys[indexPath.section])"
                return view
        }
        return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 layout collectionViewLayout: UICollectionViewLayout,
                                 referenceSizeForHeaderInSection section: Int) -> CGSize {
        if sections.count > 0 {
            return CGSize(width: collectionView.bounds.width, height: 40.0)
        }
        return .zero
    }

}
