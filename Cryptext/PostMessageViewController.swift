//
//  PostMessageViewController.swift
//  Cryptext
//
//  Created by Keith Lee on 1/7/16.
//  Copyright © 2016 Keith Lee. All rights reserved.
//

import UIKit
import CloudKit

class PostMessageViewController: UIViewController {
    var appUser: AppUser?
    var toUsername: String?

    @IBOutlet weak var message: UITextView!
    
    @IBAction func postMessage(sender: UIButton) {
        // Validate
        if nil == message.text || message.text.isEmpty {
            // Display alert
            let alert = UIAlertController(title: "Invalid message", message: "Please provide a valid (non-empty) message", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title:"Okay", style:.Cancel, handler:nil));
            self.presentViewController(alert, animated:true, completion:nil)
        }
        else {
            // Retrieve message text
            print("Posting message")
            let text = message.text
            print(text)
            
            // Encrypt
            let date = NSDate()
            let sharedSecret = getSharedSecret(toUsername!, from: appUser!.username, date: date)
            let encryptedMessage = encryptMessage(message.text, credential: sharedSecret)
            
            // Post to cloud
            postSecureMessage(SecureMessage(to: toUsername!, from: appUser!.username, message: encryptedMessage, date: date))

            // Return to parent view in navigation
//            self.navigationController?.popViewControllerAnimated(true)
        }
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        message.layer.cornerRadius = 5
        message.layer.borderColor = UIColor.purpleColor().CGColor
        message.layer.borderWidth = 1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func postSecureMessage(message: SecureMessage) {
        let record = CKRecord(recordType: "SecureMessage")
        record["to"] = message.to
        record["from"] = message.from
        record["message"] = message.message
        record["date"] = message.date
        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
        publicDB.saveRecord(record) { savedRecord, error in
            var alertMessage = "Error creating message"
            if error == nil {
                // Display status
                alertMessage = "Message posted to \(message.to)"
            }
            else {
                if let description = error?.description {
                    alertMessage = description
                }
            }
            
            let alert = UIAlertController(title: "Message Post", message: alertMessage, preferredStyle: .Alert)
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
}
