//
//  Utilities.swift
//  Cryptext
//
//  Created by Keith Lee on 1/6/16.
//  Copyright © 2016 Keith Lee. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

struct AppUser {
    var userRef: CKReference
    var username: String
}

struct SecureMessage {
    var to: String
    var from: String
    var message: NSData
    var date: NSDate
}


func setUserID(var userID: CKRecordID) {
    CKContainer.defaultContainer().fetchUserRecordIDWithCompletionHandler(){ recordID, error in
        if error == nil {
            userID = recordID!
        }
        else {
            print("Error retrieving iCloud user ID")
        }
    }
}


func encryptMessage(message: String, credential: String) -> NSData {
    let data: NSData = message.dataUsingEncoding(NSUTF8StringEncoding)!
    return RNCryptor.encryptData(data, password: credential)
}


func decryptMessage(message: NSData, credential: String) throws -> NSData {
    return try RNCryptor.decryptData(message, password: credential)
}


// Return current user icloud account status
func isSignedIn() -> Bool {
    return NSFileManager.defaultManager().ubiquityIdentityToken != nil ? true : false
}


func getSharedSecret(to: String, from: String, date: NSDate) -> String {
    return "\(to).\(from).\(date.description)"
}


func getStandardAlert(title title: String, message: String) -> UIAlertController {
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    return alert
}

extension NSURLSession {
    func sendSynchronousRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) {
        let semaphore = dispatch_semaphore_create(0)
        let task = self.dataTaskWithRequest(request) { data, response, error in
            completionHandler(data, response, error)
            dispatch_semaphore_signal(semaphore)
        }
        
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
}


func isNetworkUp() -> Bool {
    let request = NSURLRequest(URL: NSURL(string: "http://www.apple.com")!)
    var status = false
    NSURLSession.sharedSession().sendSynchronousRequest(request) { data, response, error in
        if let response = response {
            let httpResponse = response as! NSHTTPURLResponse
            if httpResponse.statusCode == 200 {
                status = true
            }
        }
    }
    
    return status
}

