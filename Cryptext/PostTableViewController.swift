//
//  PostTableViewController.swift
//  Cryptext
//
//  Created by Keith Lee on 1/7/16.
//  Copyright © 2016 Keith Lee. All rights reserved.
//

import UIKit
import CloudKit

class PostTableViewController: UITableViewController {
    var appUser: AppUser?
    var appUsers: [AppUser] = []
    var toUsername: String?
    var alertMessage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // Get/create app username
        
        if isNetworkUp() {
            getAppUser()
        }
        else {
            let alert = UIAlertController(title: "Cellular Data is Turned Off", message: "Turn on cellular dta or use Wi-Fi to access data.", preferredStyle: UIAlertControllerStyle.Alert)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if isNetworkUp() {
            if isSignedIn() == false {
                // Popup icloud login screen
                let alert = UIAlertController(title: "Sign in to iCloud", message: "Sign in to your iCloud account to write records. On the Home screen, launch Settings, tap iCloud, and enter your Apple ID. Turn iCloud Drive on. If you don't have an iCloud account, tap Create a new Apple ID.", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title:"Okay", style:.Cancel, handler:nil));
                self.presentViewController(alert, animated:true, completion:nil)
            }
        }
        else {
            let alert = UIAlertController(title: "Cellular Data is Turned Off", message: "Turn on cellular dta or use Wi-Fi to access data.", preferredStyle: UIAlertControllerStyle.Alert)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows
        return self.appUsers.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell", forIndexPath: indexPath)
        
        // Configure the cell...
        cell.textLabel?.text = self.appUsers[indexPath.row].username
        
        return cell
    }
    
    // Mark the message being selected
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath {
        self.toUsername = self.appUsers[indexPath.row].username
        
        return indexPath
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
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "PostSegue")
        {
            // Get reference to the destination view controller
            let dvc = segue.destinationViewController as! PostMessageViewController
            
            // Pass any objects to the view controller here, like...
            dvc.appUser = appUser
            dvc.toUsername = toUsername
        }
    }
    
    
    func getAppUsers() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "AppUser", predicate: predicate)
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        publicDB.performQuery(query, inZoneWithID: nil) {results, error in
            if error == nil {
                // process
                self.appUsers = []
                for record in results! {
                    let appUser = AppUser(userRef: record["userRef"] as! CKReference, username: record["username"] as! String)
                    // Add other users (not current user) to list!
                    if (self.appUser?.username != appUser.username) {
                        self.appUsers.append(appUser)
                    }
                }
                
                // Reload data
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
            else {
                let alert = self.getSimpleAlertController("AppUsers Query", message: "Error performing query")
                self.presentViewController(alert, animated:true, completion:nil)
            }
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
                                let alert = self.getUsernameViewController("App Username", message: "Create your unique App username", userID: userID)
                                self.presentViewController(alert, animated: true, completion: nil)
                            })
                        }
                        else {
                            // process
                            for record in results! {
                                self.appUser = AppUser(userRef: record["userRef"] as! CKReference, username: record["username"] as! String)
                            }
                            self.getAppUsers()
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
    
    
    func setUsername(text: String, userID: CKRecordID) {
        // First verify the name not already in use
        let predicate = NSPredicate(format: "username == %@", text)
        let query = CKQuery(recordType: "AppUser", predicate: predicate)
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        publicDB.performQuery(query, inZoneWithID: nil) {results, error in
            if error == nil {
                // process - check if record found
                if results != nil && results!.count > 0 {
                    // userAlert with username found, display alert
                    dispatch_async(dispatch_get_main_queue(), {
                        let alert = self.getUsernameViewController("Duplicate Username", message: "Create your unique App username", userID: userID)
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
                }
                else {
                    // No record with this username, create one!
                    let record = CKRecord(recordType: "AppUser")
                    record["userRef"] = CKReference(recordID: userID, action: .None)
                    record["username"] = text
                    publicDB.saveRecord(record) { savedRecord, error in
                        if error == nil {
                            // Set current user
                            self.appUser = AppUser(userRef: record["userRef"] as! CKReference, username: record["username"] as! String)
                            
                            // Now load users
                            self.getAppUsers()
                        }
                        else {
                            let alert = UIAlertController(title: "Creating User", message: error!.description, preferredStyle: UIAlertControllerStyle.Alert)
                            dispatch_async(dispatch_get_main_queue(), {
                                self.presentSimpleAlert(alert, animated: true)
                            })
                        }
                    }  // publicDB.saveRecord
                }
            }
            else {
                // Error with query, display alert
                let alert = UIAlertController(title: "User Query", message: error!.description, preferredStyle: UIAlertControllerStyle.Alert)
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentSimpleAlert(alert, animated: true)
                })
            }
        }  // performQuery
    }

    
    func presentSimpleAlert(alert: UIAlertController, animated: Bool) {
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }

    
    func getUsernameViewController(title: String, message: String, userID: CKRecordID) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let usernameAction = UIAlertAction(title: "Save", style: .Default, handler: { (action) -> Void in
            let usernameText = alert.textFields![0] as UITextField
            self.setUsername(usernameText.text!, userID: userID)
            
        })
        alert.addAction(usernameAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (alertAction) -> Void in
        }))
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "username"
        }
        
        return alert
    }

    
    func getSimpleAlertController(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        return alert
    }
}
