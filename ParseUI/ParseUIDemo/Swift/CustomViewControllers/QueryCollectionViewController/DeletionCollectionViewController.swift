//
//  DeletionCollectionViewController.swift
//  ParseUIDemo
//
//  Created by Richard Ross III on 5/14/15.
//  Copyright (c) 2015 Parse Inc. All rights reserved.
//

import UIKit

import Parse
import ParseUI

import Bolts.BFTask

class DeletionCollectionViewController: PFQueryCollectionViewController, UIAlertViewDelegate {
    convenience init(className: String?) {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 10.0)
        layout.minimumInteritemSpacing = 5.0

        self.init(collectionViewLayout: layout, className: className)

        title = "Deletion Collection"
        if #available(iOS 10.0, *) {
            pullToRefreshEnabled = true
        } else {
            // Fallback on earlier versions
        }
        objectsPerPage = 10
        paginationEnabled = true

        collectionView?.allowsMultipleSelection = true

        navigationItem.rightBarButtonItems = [
            editButtonItem,
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action:#selector(addTodo))
        ]
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if let layout = collectionViewLayout as? UICollectionViewFlowLayout {
            let bounds = view.bounds.inset(by: layout.sectionInset)
            let sideLength = min(bounds.width, bounds.height) / 2.0 - layout.minimumInteritemSpacing
            layout.itemSize = CGSize(width: sideLength, height: sideLength)
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        if (editing) {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .trash,
                target: self,
                action: #selector(deleteSelectedItems)
            )
        } else {
            navigationItem.leftBarButtonItem = navigationItem.backBarButtonItem
        }
    }

    @objc
    func addTodo() {
        if #available(iOS 8.0, *) {
            let alertDialog = UIAlertController(title: "Add Todo", message: nil, preferredStyle: .alert)

            var titleTextField : UITextField? = nil
            alertDialog.addTextField(configurationHandler: {
                titleTextField = $0
            })

            alertDialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertDialog.addAction(UIAlertAction(title: "Save", style: .default) { action in
                if let title = titleTextField?.text {
                    let object = PFObject(className: self.parseClassName!, dictionary: [ "title": title ])
                    object.saveEventually().continueOnSuccessWith { _ -> AnyObject in
                        return self.loadObjects()
                    }
                }
                })

            present(alertDialog, animated: true, completion: nil)
        } else {
            let alertView = UIAlertView(
                title: "Add Todo",
                message: "",
                delegate: self,
                cancelButtonTitle: "Cancel",
                otherButtonTitles: "Save"
            )

            alertView.alertViewStyle = .plainTextInput
            alertView.textField(at: 0)?.placeholder = "Name"

            alertView.show()
        }
    }

    @objc
    func deleteSelectedItems() {
        guard let paths = collectionView?.indexPathsForSelectedItems else { return }
        removeObjects(at: paths)
    }

    // MARK - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath, object: PFObject?) -> PFCollectionViewCell? {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath, object: object)
        cell?.textLabel.textAlignment = .center
        cell?.textLabel.text = object?["title"] as? String

        cell?.contentView.layer.borderWidth = 1.0
        cell?.contentView.layer.borderColor = UIColor.lightGray.cgColor

        return cell
    }

    // MARK - UIAlertViewDelegate

    @objc
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return
        }

        if let title =  alertView.textField(at: 0)?.text {
            let object = PFObject(
                className: self.parseClassName!,
                dictionary: [ "title": title ]
            )
            
            object.saveEventually().continueOnSuccessWith { _ -> AnyObject in
                return self.loadObjects()
            }
        }
    }
}
