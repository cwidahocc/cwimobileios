//
//  ImportantNumbersTests.swift
//  Mobile
//
//  Created by Raji Aboulhosn on 5/11/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import XCTest

class ImportantNumbersTests: XCTestCase {
        
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
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
 
    func testImportantNumbersCount() {
        
        let app = XCUIApplication()
        app.navigationBars["Ellucian_GO.HomeView"].buttons["Menu"].tap()
        app.tables.staticTexts["Important Numbers"].tap()
        let table = app.tables["Important Numbers"]
        let cells = table.cells
        XCTAssertEqual(cells.count, 19)
}
    
    func testImportantNumbers() {
        let app = XCUIApplication()
        app.navigationBars["Ellucian_GO.HomeView"].buttons["Menu"].tap()
        app.tables.staticTexts["Important Numbers"].tap()
        let table = app.tables["Important Numbers"]
        let cells = table.cells
        XCTAssertEqual(cells.count, 19)
        XCTAssert(table.cells.staticTexts["Registrar"].exists)
        table.cells.staticTexts["Registrar"].tap()
        let elementsQuery = XCUIApplication().scrollViews.otherElements
        let phone = elementsQuery.staticTexts["phone"];
        XCTAssert(phone.exists)
        XCTAssertEqual(phone.label, "(703) 123-5678")
        let email = elementsQuery.staticTexts["email"];
        XCTAssert(email.exists)
        XCTAssertEqual(email.label, "registrar@ellucian.edu")
        let address = elementsQuery.staticTexts["address"];
        XCTAssert(address.exists)
        XCTAssertEqual(address.label, "Albert Einstein Hall 4272 Kearney Lane Fairfax, VA  22033")
        XCTAssert(elementsQuery.staticTexts["Get Directions"].exists)
        
        
     

        
//        XCTAssert(elementsQuery.staticTexts["Get Directions"].exists)
//        
//        let name = elementsQuery.staticTexts["name"];
//        XCTAssert(name.exists)
//        XCTAssertEqual(name.label, "Admissions Office")
//        
//        let type = elementsQuery.staticTexts["type"];
//        XCTAssert(type.exists)
//        XCTAssertEqual(type.label, "ADMIN")
//        
        
       
        
        
}
}