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
    
    @IBAction func deleteMessage(_ sender: UIButton) {
        // Delete from cloud
        let alert = getStandardAlert(title: "Confirm Delete", message: "Delete message from \((secureMessage?.from)!)?")
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (alertAction) -> Void in
            // Delete method
            self.deleteRecord(self.secureMessage!)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (alertAction) -> Void in
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
            let text = String(data: data, encoding: String.Encoding.utf8)
            
            // Display
            message.text = text
        }
        catch {
            let alert = getStandardAlert(title: "Message Decrypt", message: "Error decrypting message")
            self.presentSimpleAlert(alert, animated: true)
        }
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func deleteRecord(_ secureMessage: SecureMessage) {
        // Retrieve record in database
        let predicate = NSPredicate(format: "to == %@ AND from == %@ AND date == %@", (secureMessage.to), secureMessage.from, secureMessage.date as CVarArg)
        let query = CKQuery(recordType: "SecureMessage", predicate: predicate)
        let publicDB = CKContainer.default().publicCloudDatabase
        publicDB.perform(query, inZoneWith: nil) {results, error in
            // Create alert
            let alert = getStandardAlert(title: "Message Delete", message: "Error deleting message")
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: { (alertAction) -> Void in
                // Pop current view of stack
                DispatchQueue.main.async(execute: { () -> Void in
                    _ = self.navigationController?.popViewController(animated: false)
                })
            }))
            
            // Process results of query
            if error == nil {
                if !results!.isEmpty {
                    for record in results! {
                        publicDB.delete(withRecordID: record.recordID, completionHandler: { (recordID, error) -> Void in
                            // Process results of delete
                            if error == nil {
                                alert.message = "Message from \(secureMessage.from) deleted"
                            }
                            else {
                                alert.message = error.debugDescription
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
                alert.message = error.debugDescription
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

    
    func presentSimpleAlert(_ alert: UIAlertController, animated: Bool) {
        DispatchQueue.main.async(execute: {
            self.present(alert, animated: true, completion: nil)
        })
    }

}
