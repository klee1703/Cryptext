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


func storeUser(id: CKRecordID, username: String) {
    let appUser = CKRecord(recordType: "AppUser")
    appUser["userRef"] = CKReference(recordID: id, action: .None)
    appUser["username"] = username
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    publicDB.saveRecord(appUser) { savedRecord, error in
        if error == nil {
            print("User saved")
        }
        else {
            print("Error creating app user")
        }
    }
}


func getCurrentUser(userRef: CKReference, var appUser: AppUser) {
    let predicate = NSPredicate(format: "following == %@", userRef)
    let query = CKQuery(recordType: "AppUser", predicate: predicate)
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    publicDB.performQuery(query, inZoneWithID: nil) {results, error in
        if error == nil {
            // process
            for record in results! {
                appUser = AppUser(userRef: record["userRef"] as! CKReference, username: record["username"] as! String)
            }
        }
        else {
            print("Error performing query")
        }
    }
}


// Post secure message
// toUsername | fromUsername | message | date
func postSecureMessage(message: SecureMessage) {
    let record = CKRecord(recordType: "SecureMessage")
    record["to"] = message.to
    record["from"] = message.from
    record["message"] = message.message
    record["date"] = message.date
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    publicDB.saveRecord(record) { savedRecord, error in
        if error == nil {
            print("Message saved")
        }
        else {
            print("Error creating message")
        }
    }
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


// Fetch all app users (POST message table view)
func getAppUsers(var appUsers: [AppUser]) {
    let predicate = NSPredicate(format: "TRUEPREDICATE")
    let query = CKQuery(recordType: "AppUser", predicate: predicate)
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    publicDB.performQuery(query, inZoneWithID: nil) {results, error in
        if error == nil {
            // process
            for record in results! {
                let appUser = AppUser(userRef: record["userRef"] as! CKReference, username: record["username"] as! String)
                appUsers.append(appUser)
            }
        }
        else {
            print("Error performing query")
        }
    }
}


// Fetch all messages for user (VIEW messages table view)
func getMessages(var messages: [SecureMessage], username: String) {
    let predicate = NSPredicate(format: "to == " + username)
    let query = CKQuery(recordType: "SecureMessage", predicate: predicate)
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    publicDB.performQuery(query, inZoneWithID: nil) {results, error in
        if error == nil {
            // process - decrypt and view
            for record in results! {
                let message = SecureMessage(to: record["to"] as! String, from: record["from"] as! String, message: record["data"] as! NSData, date: record["date"] as! NSDate)
                messages.append(message)
            }
        }
        else {
            print("Error performing query")
        }
    }
}


// Fetch credential for decrypting secure message
func getCredential(var credential: SharedCredential, to: String, from: String, date: NSDate) {
    let predicate = NSPredicate(format: "to == \(to) AND from == \(from) AND date == \(date)")
    let query = CKQuery(recordType: "Credential", predicate: predicate)
    let publicDB = CKContainer.defaultContainer().publicCloudDatabase
    publicDB.performQuery(query, inZoneWithID: nil) {results, error in
        if error == nil {
            // process
            for record in results! {
                credential = SharedCredential(to: record["toUsername"] as! String, from: record["from"] as! String, credential: record["credential"] as! String, date: record["date"] as! NSDate)
            }
        }
        else {
            print("Error performing query")
        }
    }
}


// Return current user icloud account status
func isSignedIn() -> Bool {
    return NSFileManager.defaultManager().ubiquityIdentityToken != nil ? true : false
}


func getAppUser(var appUser: AppUser?) {
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
                        print("No username, create one!")
                        let record = CKRecord(recordType: "AppUser")
                        record["userRef"] = CKReference(recordID: userID, action: .None)
                        record["username"] = "Test User 1"
                        let publicDB = CKContainer.defaultContainer().publicCloudDatabase
                        publicDB.saveRecord(record) { savedRecord, error in
                            if error == nil {
                                print("User saved")
                            }
                            else {
                                print("Error creating app user")
                            }
                        }
                    }
                    else {
                        // process
                        for record in results! {
                            appUser = AppUser(userRef: record["userRef"] as! CKReference, username: record["username"] as! String)
                        }
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
    
    // Check if icloud user has an app username
    
    // No app username, display popup to create one
}


func getSharedSecret(to: String, from: String, date: NSDate) -> String {
    return "\(to).\(from).\(date.description)"
}

