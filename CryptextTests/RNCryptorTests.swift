//
//  RNCryptorTests.swift
//  Cryptext
//
//  Created by Keith Lee on 1/5/16.
//  Copyright © 2016 Keith Lee. All rights reserved.
//

import XCTest
@testable import Cryptext

class RNCryptorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRandomData() {
        let len = 1024
        let data = RNCryptor.randomDataOfLength(len)
        XCTAssertEqual(data.length, len)
        
        let secondData = RNCryptor.randomDataOfLength(len)
        XCTAssertNotEqual(data, secondData, "Random data this long should never be equal")
    }
    
    func testEncrypt() {
        let data: NSData = "Hello, world!".dataUsingEncoding(NSUTF8StringEncoding)!
        let encrypted = RNCryptor.encryptData(data, password: "password")
        XCTAssertNotNil(encrypted, "Should produce encrypted data")
    }
    
    func testDecrypt() {
        let data: NSData = "Hello, world!".dataUsingEncoding(NSUTF8StringEncoding)!
        let encrypted = RNCryptor.encryptData(data, password: "password")
        do {
            let decrypted = try RNCryptor.decryptData(encrypted, password: "password")
            let hello = String(data: decrypted, encoding: NSUTF8StringEncoding)
            print("Decrypted data: " + hello!)
            XCTAssert(data == decrypted, "Decrypted value should equal original")
        }
        catch {
            print("Error decrypting value")
        }
    }

}
