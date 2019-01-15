//
//  MapsTests.swift
//  Mobile
//
//  Created by Raji Aboulhosn on 5/12/16.
//  Copyright © 2016 Ellucian Company L.P. and its affiliates. All rights reserved.
//

import XCTest

class MapsTests: XCTestCase {
        
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
    func initMapsModule(_ app:  XCUIApplication) {
        
        
        app.navigationBars.buttons["Menu"].tap()
        app.tables.staticTexts["Campus Maps"].tap()
        app.toolbars.buttons["Campus"].tap()
        app.sheets["Select Campus"].collectionViews.buttons["Miller Chester University"].tap()
       
    }
    func testMapsCount() {
        let app = XCUIApplication()
        initMapsModule(app)
        
        //Count the number of buildings
        
        app.navigationBars.buttons["icon building"].tap()
        let table = app.tables["Maps"]
        let cells = table.cells
        XCTAssertEqual(cells.count, 62)
        XCUIApplication().navigationBars["Buildings"].buttons["Miller Chester University"].tap()
        
    }
    
    func testMapsConfirmData() {
    
        //Confirm correct data for Albert Einstein Hall
        
        let app = XCUIApplication()
        initMapsModule(app)
        XCUIApplication().navigationBars["Miller Chester University"].buttons["icon building"].tap()
        XCUIApplication().tables["Maps"].staticTexts["Albert Einstein Hall"].tap()
        let elementsQuery = XCUIApplication().scrollViews.otherElements
        let address = elementsQuery.staticTexts["address"];
        XCTAssert(address.exists)
        XCTAssertEqual(address.label, "4272 Kearney Lane Fairfax, VA  22033")
        XCTAssert(elementsQuery.staticTexts["Get Directions"].exists)
        app.navigationBars["Miller Chester University"].buttons["Buildings"].tap()
        app.navigationBars["Buildings"].buttons["Miller Chester University"].tap()
        
    }
    
    func testMapsSearch() {
    
    //Seaching for a building and confirming the correct data is returned
        
        let app = XCUIApplication()
        initMapsModule(app)
        app.navigationBars.buttons["icon building"].tap()
        app.tables["Maps"].searchFields["Search"].tap()
        let mapsTable = app.tables["Maps"]
        mapsTable.searchFields["Search"].tap()
        mapsTable.typeText("Vince")
        XCUIApplication().tables["Maps"].staticTexts["Vince Lombardi Stadium"].tap()
        let elementsQuery = XCUIApplication().scrollViews.otherElements
        let address = elementsQuery.staticTexts["address"];
        XCTAssert(address.exists)
        XCTAssertEqual(address.label, "4300 Fair Lakes Ct Fairfax, VA  22033")
        XCTAssert(elementsQuery.staticTexts["Get Directions"].exists)
        app.navigationBars["Miller Chester University"].buttons["Buildings"].tap()
        app.tables["Maps"].buttons["Cancel"].tap()
        app.navigationBars["Buildings"].buttons["Miller Chester University"].tap()
        app.toolbars.buttons["Campus"].tap()
    }
        
        func testSwitchCampus() {
          
    //Switching Campus and selecting a building and confirming the correct data is returned
            
        let app = XCUIApplication()
        initMapsModule(app)
        app.toolbars.buttons["Campus"].tap()
        app.sheets["Select Campus"].collectionViews.buttons["Dalton-Tierney University"].tap()
        let daltonTierneyUniversityNavigationBar = app.navigationBars["Dalton-Tierney University"]
        daltonTierneyUniversityNavigationBar.buttons["icon building"].tap()
        app.tables["Maps"].staticTexts["Byrd Hall"].tap()
        let elementsQuery = XCUIApplication().scrollViews.otherElements
        let address = elementsQuery.staticTexts["address"];
        XCTAssert(address.exists)
        XCTAssertEqual(address.label, "320 Byrd St Greenwood, SC  29646")
        XCTAssert(elementsQuery.staticTexts["Get Directions"].exists)
            
}
    
    
        func testMenu() {
            let app = XCUIApplication()
            initMapsModule(app)
            app.otherElements["Rosa Parks Hall, Residence Hall"].tap()
            let button = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .button).element
            button.tap()
            
           
}
}


    

