//
//  LoginTests.swift
//  Mobile
//
//  Created by Jason Hocker on 5/23/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import XCTest

class LoginTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    //REQUIRES TOUCH ID DEVICE
    func testSwitches() {
        let app = XCUIApplication()
        app.navigationBars.buttons["Menu"].tap()
        app.tables.staticTexts["Sign In"].tap()
        
        let useFingerprintToUnlockSwitch = app.switches["Use fingerprint to unlock"]
        let staySignedInSwitch = app.switches["Stay signed in"]
        
        XCTAssertTrue(staySignedInSwitch.isEnabled)
//        XCTAssertFalse(staySignedInSwitch.value!.boolValue)
        XCTAssertTrue(useFingerprintToUnlockSwitch.isEnabled)
//        XCTAssertFalse(useFingerprintToUnlockSwitch.value!.boolValue)
        
        //turn on fingerprint
        useFingerprintToUnlockSwitch.tap()
        XCTAssertFalse(staySignedInSwitch.isEnabled)
//        XCTAssertFalse(staySignedInSwitch.value!.boolValue)
        XCTAssertTrue(useFingerprintToUnlockSwitch.isEnabled)
//        XCTAssertTrue(useFingerprintToUnlockSwitch.value!.boolValue)
        
        //reset
        useFingerprintToUnlockSwitch.tap()
        XCTAssertTrue(staySignedInSwitch.isEnabled)
//        XCTAssertFalse(staySignedInSwitch.value!.boolValue)
        XCTAssertTrue(useFingerprintToUnlockSwitch.isEnabled)
//        XCTAssertFalse(useFingerprintToUnlockSwitch.value!.boolValue)
        
        //turn on remember
        staySignedInSwitch.tap()
        XCTAssertTrue(staySignedInSwitch.isEnabled)
//        XCTAssertTrue(staySignedInSwitch.value!.boolValue)
        XCTAssertFalse(useFingerprintToUnlockSwitch.isEnabled)
//        XCTAssertFalse(useFingerprintToUnlockSwitch.value!.boolValue)
        
        //reset
        staySignedInSwitch.tap()
        XCTAssertTrue(staySignedInSwitch.isEnabled)
//        XCTAssertFalse(staySignedInSwitch.value!.boolValue)
        XCTAssertTrue(useFingerprintToUnlockSwitch.isEnabled)
//        XCTAssertFalse(useFingerprintToUnlockSwitch.value!.boolValue)
        
    }
    
}

