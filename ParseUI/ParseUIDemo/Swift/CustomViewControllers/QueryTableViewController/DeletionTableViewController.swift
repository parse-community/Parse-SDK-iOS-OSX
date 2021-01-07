//
//  DeletionTableViewController.swift
//  ParseUIDemo
//
//  Created by Richard Ross III on 5/13/15.
//  Copyright (c) 2015 Parse Inc. All rights reserved.
//

import UIKit

import Parse
import ParseUI

import Bolts.BFTask

class DeletionTableViewController: PFQueryTableViewController, UIAlertViewDelegate {

    // MARK: Init

    convenience init(className: String?) {
        self.init(style: .plain, className: className)

        title = "Deletion Table"
        pullToRefreshEnabled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsMultipleSelectionDuringEditing = true

        navigationItem.rightBarButtonItems = [
            editButtonItem,
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTodo))
        ]
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

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            removeObject(at: indexPath)
        }
    }

    @objc
    func addTodo() {
        
        if #available(iOS 8.0, *) {
            let alertDialog = UIAlertController(title: "Add Todo", message: nil, preferredStyle: .alert)

            var titleTextField : UITextField! = nil
            alertDialog.addTextField(configurationHandler: {
                titleTextField = $0
            })

            alertDialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertDialog.addAction(UIAlertAction(title: "Save", style: .default) { _ in
                if let title = titleTextField.text {
                    let object = PFObject(className: self.parseClassName!, dictionary: [ "title": title ])
                    object.saveInBackground().continueOnSuccessWith { _ -> AnyObject in
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
        removeObjects(at: tableView.indexPathsForSelectedRows)
    }

    // MARK - UIAlertViewDelegate

    @objc
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return
        }

        if let title = alertView.textField(at: 0)?.text {
            let object = PFObject(className: self.parseClassName!, dictionary: [ "title": title ])
            object.saveEventually().continueOnSuccessWith { _ -> AnyObject in
                return self.loadObjects()
            }
        }
    }
}
