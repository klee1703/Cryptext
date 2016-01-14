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
        // Retrieve message
        print("Deleting message")
        
        // Delete from cloud
        deleteRecord(secureMessage!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set text area border
        message.layer.cornerRadius = 5
        message.layer.borderColor = UIColor.purpleColor().CGColor
        message.layer.borderWidth = 1
        
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
          print("Error decrypting message")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func deleteRecord(message: SecureMessage) {
        // Retrieve record in database
        let predicate = NSPredicate(format: "to == %@ AND from == %@ AND date == %@", (message.to), message.from, message.date)
        let query = CKQuery(recordType: "SecureMessage", predicate: predicate)
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        publicDB.performQuery(query, inZoneWithID: nil) {results, error in
            var alertMessage = "Error deleting message"
            if error == nil {
                if !results!.isEmpty {
                    // process
                    for record in results! {
                        publicDB.deleteRecordWithID(record.recordID, completionHandler: { (recordID, error) -> Void in
                            if (error == nil) {
                                alertMessage = "Message from \(message.from) deleted"
                            }
                            else {
                                if let description = error?.description {
                                    alertMessage = description
                                }
                            }
                        })
                    }
                }
                else {
                    alertMessage = "Message not found"
                }
            }
            else {
                if let description = error?.description {
                    alertMessage = description
                }
            }
            
            
            let alert = UIAlertController(title: "Message Delete", message: alertMessage, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .Cancel, handler: { (alertAction) -> Void in
                // Pop current view of stack
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.navigationController?.popViewControllerAnimated(false)
                })
            }))
            
            // Now present alert
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(alert, animated: true, completion: nil)
            })
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

}
