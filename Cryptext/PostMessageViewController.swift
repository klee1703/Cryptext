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
    
    @IBOutlet weak var subject: UITextField!
    @IBOutlet weak var message: UITextView!
    
    @IBAction func postMessage(_ sender: UIButton) {
        // Validate
        if nil == message.text || message.text.isEmpty {
            // Display alert
            let alert = getStandardAlert(title: "Invalid message", message: "Please provide a valid (non-empty) message")
            alert.addAction(UIAlertAction(title:"Okay", style:.cancel, handler:nil));
            self.present(alert, animated:true, completion:nil)
        }
        else {
            // Retrieve message text
            var subjectText = ""
            if let text = subject.text {
                if !text.isEmpty {
                    subjectText = text
                }
            }
            
            // Encrypt
            let date = Date()
            let sharedSecret = getSharedSecret(toUsername!, from: appUser!.username, date: date)
            let encryptedMessage = encryptMessage(message.text, credential: sharedSecret)
            
            // Post to cloud
            postSecureMessage(SecureMessage(to: toUsername!, from: appUser!.username, subject: subjectText, message: encryptedMessage, date: date))
        }
     }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        message.layer.cornerRadius = 5
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

    func postSecureMessage(_ message: SecureMessage) {
        let record = CKRecord(recordType: "SecureMessage")
        record["to"] = message.to as CKRecordValue?
        record["from"] = message.from as CKRecordValue?
        record["subject"] = message.subject as CKRecordValue?
        record["message"] = message.message as CKRecordValue?
        record["date"] = message.date as CKRecordValue?
        let publicDB = CKContainer.default().publicCloudDatabase
        publicDB.save(record, completionHandler: { savedRecord, error in
            let alert = getStandardAlert(title: "Message Post", message: "Error creating message")
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: { (alertAction) -> Void in
                // Pop current view of stack
                DispatchQueue.main.async(execute: { () -> Void in
                    _ = self.navigationController?.popViewController(animated: false)
                })
            }))
            if error == nil {
                // Display status
                alert.message = "Message posted to \(message.to)"
            }
            else {
                alert.message = error.debugDescription
            }

            // Now present alert
            DispatchQueue.main.async(execute: {
                self.present(alert, animated: true, completion: nil)
            })
        }) 
    }
}
