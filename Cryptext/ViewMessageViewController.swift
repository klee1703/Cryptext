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
        let credential = SharedCredential(to: (secureMessage?.to)!, from: (secureMessage?.from)!, credential: sharedSecret, date: (secureMessage?.date)!)
        
        // Decrypt
        do {
            
            let data = try decryptMessage((secureMessage?.message)!, credential: credential)
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
        let predicate = NSPredicate(format: "to == %@ AND from == %@ AND date == %@", (secureMessage?.to)!, (secureMessage?.from)!, (secureMessage?.date)!)
        let query = CKQuery(recordType: "SecureMessage", predicate: predicate)
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        publicDB.performQuery(query, inZoneWithID: nil) {results, error in
            if error == nil {
                if !results!.isEmpty {
                    // process
                    for record in results! {
                        publicDB.deleteRecordWithID(record.recordID, completionHandler: { (recordID, error) -> Void in
                            if (nil == error) {
                                print("Message deleted")
                                
                                // Return to parent view in navigation
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.navigationController?.popViewControllerAnimated(true)
                                })
                            }
                            else {
                                print("Error deleting message")
                                print(error)
                                
                                // Return to parent view in navigation
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.navigationController?.popViewControllerAnimated(true)
                                })
                            }
                        })
                    }
                }
                else {
                    print("No message found for this ID")
                }
            }
            else {
                print("Message not found for query")
                print(error)
                
                // Return to parent view in navigation
                dispatch_async(dispatch_get_main_queue(), {
                    self.navigationController?.popViewControllerAnimated(true)
                })
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

}
