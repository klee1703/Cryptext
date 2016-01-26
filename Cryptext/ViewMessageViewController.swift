//
//  ViewMessageViewController.swift
//  Cryptext
//
//  Created by Keith Lee on 1/7/16.
//  Copyright © 2016 Keith Lee. All rights reserved.
//

import UIKit
import CloudKit

class ViewMessageViewController: UIViewController {
    var secureMessage: SecureMessage?

    @IBOutlet weak var message: UITextView!
    
    @IBAction func deleteMessage(sender: UIButton) {
        // Delete from cloud
        let alert = UIAlertController(title: "Confirm Delete", message: "Delete message from \((secureMessage?.from)!)?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { (alertAction) -> Void in
            // Delete method
            self.deleteRecord(self.secureMessage!)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (alertAction) -> Void in
        }))
        presentSimpleAlert(alert, animated: true)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set text area border
        message.layer.cornerRadius = 5
        
        // Get credential
        let sharedSecret = getSharedSecret((secureMessage?.to)!, from: (secureMessage?.from)!, date: (secureMessage?.date)!)
        
        // Decrypt
        do {
            
            let data = try decryptMessage((secureMessage?.message)!, credential: sharedSecret)
            let text = String(data: data, encoding: NSUTF8StringEncoding)
            
            // Display
            message.text = text
        }
        catch {
            let alert = UIAlertController(title: "Message Decrypt", message: "Error decrypting message", preferredStyle: .Alert)
            self.presentSimpleAlert(alert, animated: true)
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func deleteRecord(secureMessage: SecureMessage) {
        // Retrieve record in database
        let predicate = NSPredicate(format: "to == %@ AND from == %@ AND date == %@", (secureMessage.to), secureMessage.from, secureMessage.date)
        let query = CKQuery(recordType: "SecureMessage", predicate: predicate)
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        publicDB.performQuery(query, inZoneWithID: nil) {results, error in
            // Create alert
            let alert = UIAlertController(title: "Message Delete", message: "Error deleting message", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: { (alertAction) -> Void in
                // Pop current view of stack
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.navigationController?.popViewControllerAnimated(false)
                })
            }))
            
            // Process results of query
            if error == nil {
                if !results!.isEmpty {
                    for record in results! {
                        publicDB.deleteRecordWithID(record.recordID, completionHandler: { (recordID, error) -> Void in
                            // Process results of delete
                            if error == nil {
                                alert.message = "Message from \(secureMessage.from) deleted"
                            }
                            else {
                                if let description = error?.description {
                                    alert.message = description
                                }
                            }
                            self.presentSimpleAlert(alert, animated: true)
                        })
                    }
                }
                else {
                    alert.message = "Message not found"
                    self.presentSimpleAlert(alert, animated: true)
                }
            }
            else {
                if let description = error?.description {
                    alert.message = description
                }
                self.presentSimpleAlert(alert, animated: true)
            }
        }
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    func presentSimpleAlert(alert: UIAlertController, animated: Bool) {
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }

}
