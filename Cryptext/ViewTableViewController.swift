//
//  ViewTableViewController.swift
//  Cryptext
//
//  Created by Keith Lee on 1/7/16.
//  Copyright © 2016 Keith Lee. All rights reserved.
//

import UIKit
import CloudKit

class ViewTableViewController: UITableViewController {
    
    @IBOutlet weak var messagesLabel: UINavigationItem!
    var appUser: AppUser?
    var messages: [SecureMessage] = []
    var secureMessage: SecureMessage?
    var labelTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let title = labelTitle {
             self.messagesLabel.title = title
        }
        
        if isSignedIn() == false {
            // Popup icloud login screen
            let alert = UIAlertController(title: "Sign in to iCloud", message: "Sign in to your iCloud account to write records. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title:"Okay", style:.Cancel, handler:nil));
            self.presentViewController(alert, animated:true, completion:nil)
        }
        else {
            // Get/create app username
            getAppUser()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows
        return self.messages.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ViewCell", forIndexPath: indexPath)
    

        // Configure the cell...
        cell.textLabel?.text = "From: \(self.messages[indexPath.row].from)"
        cell.detailTextLabel?.text = self.messages[indexPath.row].date.description
    
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // Mark the message being selected
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        secureMessage = messages[indexPath.row]
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        secureMessage = messages[indexPath.row]
        return indexPath
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "ViewSegue")
        {
            // Get reference to the destination view controller
            let dvc = segue.destinationViewController as! ViewMessageViewController
            
            // Pass any objects to the view controller here, like...
            dvc.secureMessage = secureMessage!
        }
    }
    
    
    func getAppUser() {
        // Fetch iCloud user record ID
        CKContainer.defaultContainer().fetchUserRecordIDWithCompletionHandler(){ recordID, error in
            if error == nil {
                // Now check if username already created for this account!
                let userID = recordID!
                let predicate = NSPredicate(format: "userRef == %@", CKReference(recordID: userID, action: CKReferenceAction.None))
                let query = CKQuery(recordType: "AppUser", predicate: predicate)
                let publicDB = CKContainer.defaultContainer().publicCloudDatabase
                publicDB.performQuery(query, inZoneWithID: nil) {results, error in
                    if error == nil {
                        if results!.isEmpty {
                        // No username exists for this account, create one
                        dispatch_async(dispatch_get_main_queue(), {
                            let alert = UIAlertController(title: "App Username", message: "Enter your unique App username", preferredStyle: UIAlertControllerStyle.Alert)
                            let usernameAction = UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
                                let usernameText = alert.textFields![0] as UITextField
                                self.setUsername(usernameText.text!, userID: userID)
                                })
                            alert.addAction(usernameAction);
                            alert.addTextFieldWithConfigurationHandler { (textField) in
                                textField.placeholder = "username"
                            }
                            self.presentViewController(alert, animated:true, completion:nil)
                            print("No username, create one!")
                            })
                        }
                        else {
                            // process
                            for record in results! {
                                self.appUser = AppUser(userRef: record["userRef"] as! CKReference, username: record["username"] as! String)
                            }
                        
                            dispatch_async(dispatch_get_main_queue(), {
                                if nil == self.labelTitle {
                                    self.labelTitle = (self.appUser?.username)
                                    self.messagesLabel.title = self.labelTitle!
                                }
                            })
                        
                            // Now load messages
                            self.getMessages()
                        }
                    }
                    else {
                        print("Error performing query")
                        print(error)
                    }
                }
            }
            else {
                print("Error retrieving iCloud user ID")
            }
        }
    }
    
    
    // Fetch all messages for user (VIEW messages table view)
    func getMessages() {
        let predicate = NSPredicate(format: "to == %@", appUser!.username)
        let query = CKQuery(recordType: "SecureMessage", predicate: predicate)
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        publicDB.performQuery(query, inZoneWithID: nil) {results, error in
            if error == nil {
                // process - decrypt and view
                self.messages = []
                for record in results! {
                    let message = SecureMessage(to: record["to"] as! String, from: record["from"] as! String, message: record["message"] as! NSData, date: record["date"] as! NSDate)
                    self.messages.append(message)
                }
                
                // Reload data
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
            else {
                let alert = UIAlertController(title: "Message Retrieval", message: "Error performing query", preferredStyle: .Alert)
                self.presentSimpleAlert(alert, animated: true)
            }
        }
    }
    
    func setUsername(text: String, userID: CKRecordID) {
        let record = CKRecord(recordType: "AppUser")
        record["userRef"] = CKReference(recordID: userID, action: .None)
        record["username"] = text
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        publicDB.saveRecord(record) { savedRecord, error in
            if error == nil {
                self.appUser = AppUser(userRef: record["userRef"] as! CKReference, username: record["username"] as! String)            
                dispatch_async(dispatch_get_main_queue(), {
                    if nil == self.labelTitle {
                        self.labelTitle = (self.appUser?.username)
                        self.messagesLabel.title = self.labelTitle!
                    }
                })
            
                // Now load messages
                self.getMessages()
            }
            else {
                print("Error creating app user")
            }
        }
    }

    
    func presentSimpleAlert(alert: UIAlertController, animated: Bool) {
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
}
