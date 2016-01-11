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

struct SharedCredential {
    var to: String
    var from: String
    var credential: String
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


func encryptMessage(message: String, credential: SharedCredential) -> NSData {
    let data: NSData = message.dataUsingEncoding(NSUTF8StringEncoding)!
    return RNCryptor.encryptData(data, password: credential.credential)
}


func decryptMessage(message: NSData, credential: SharedCredential) throws -> NSData {
    return try RNCryptor.decryptData(message, password: credential.credential)
}


// Store shared credential for encrypting message
// toUsername | fromUsername | credential
func postCredential(credential: SharedCredential) {
    let record = CKRecord(recordType: "Credential")
    record["to"] = credential.to
    record["from"] = credential.from
    record["credential"] = credential.credential
    record["date"] = credential.date
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    publicDB.saveRecord(record) { savedRecord, error in
        if error == nil {
            print("Credential saved")
        }
        else {
            print("Error creating message")
        }
    }
}


// Return current user icloud account status
func isSignedIn() -> Bool {
    return NSFileManager.defaultManager().ubiquityIdentityToken != nil ? true : false
}


func getSharedSecret(to: String, from: String, date: NSDate) -> String {
    return "\(to).\(from).\(date.description)"
}

