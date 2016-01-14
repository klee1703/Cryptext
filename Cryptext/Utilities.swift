//
//  Utilities.swift
//  Cryptext
//
//  Created by Keith Lee on 1/6/16.
//  Copyright © 2016 Keith Lee. All rights reserved.
//

import Foundation
import CloudKit

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

