import XCTest

/// UI test suite focused on measuring performance characteristics of
/// common customer journeys in the WooCommerce iOS app.
///
/// These tests are designed to be used in conjunction with Instruments
/// and os_signpost markers provided by PerformanceLogger.
final class PerformanceUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launchArguments.append(contentsOf: [
            "-UITest_PerformanceMode",
            "YES"
        ])
        
        app.launch()
    }
    
    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    private func scroll(element: XCUIElement, times: Int = 5) {
        for _ in 0..<times {
            element.swipeUp()
            sleep(1)
        }
    }
    
    private func waitForElement(_ element: XCUIElement,
                                timeout: TimeInterval = 15,
                                file: StaticString = #filePath,
                                line: UInt = #line) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Element did not appear in time", file: file, line: line)
    }
    
    private func navigateToCatalog() {
        // Assumes a tab bar or entry point to the product catalog exists.
        let tabBarsQuery = app.tabBars
        if tabBarsQuery.buttons["Shop"].exists {
            tabBarsQuery.buttons["Shop"].tap()
        }
    }
    
    private func navigateToCart() {
        if app.tabBars.buttons["Cart"].exists {
            app.tabBars.buttons["Cart"].tap()
        }
    }
    
    private func navigateToAccount() {
        if app.tabBars.buttons["My Account"].exists {
            app.tabBars.buttons["My Account"].tap()
        }
    }
    
    // MARK: - Scenario 1: Browse Product Catalog (FPS & CPU)
    
    func testScenario1_BrowseProductCatalog() {
        measure(metrics: [
            XCTOSSignpostMetric.applicationLaunch,
            XCTClockMetric(),
            XCTCPUMetric(),
            XCTMemoryMetric()
        ]) {
            navigateToCatalog()
            
            let collectionView = app.collectionViews.firstMatch
            waitForElement(collectionView)
            
            scroll(element: collectionView, times: 8)
        }
    }
    
    // MARK: - Scenario 2: Add Products to Cart (Memory)
    
    func testScenario2_AddProductsToCart() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTCPUMetric(),
            XCTClockMetric()
        ]) {
            navigateToCatalog()
            
            let collectionView = app.collectionViews.firstMatch
            waitForElement(collectionView)
            
            // Tap the first few products and add them to cart, if the UI matches.
            for i in 0..<5 {
                let cell = collectionView.cells.element(boundBy: i)
                if cell.exists {
                    cell.tap()
                    
                    let addToCartButton = app.buttons.matching(identifier: "add-to-cart").firstMatch
                    if addToCartButton.exists {
                        addToCartButton.tap()
                    } else if app.buttons["Add to cart"].exists {
                        app.buttons["Add to cart"].tap()
                    }
                    
                    app.navigationBars.buttons.element(boundBy: 0).tap()
                }
            }
            
            navigateToCart()
        }
    }
    
    // MARK: - Scenario 3: Complete Checkout (Latency)
    
    func testScenario3_CompleteCheckout() {
        measure(metrics: [
            XCTClockMetric(),
            XCTCPUMetric(),
            XCTMemoryMetric()
        ]) {
            navigateToCart()
            
            let checkoutButton = app.buttons.matching(identifier: "proceed-to-checkout").firstMatch
            if checkoutButton.exists {
                checkoutButton.tap()
            } else if app.buttons["Proceed to checkout"].exists {
                app.buttons["Proceed to checkout"].tap()
            }
            
            // Fill in dummy data where applicable
            let tablesQuery = app.tables
            if tablesQuery.textFields["First name"].exists {
                tablesQuery.textFields["First name"].tap()
                tablesQuery.textFields["First name"].typeText("Test")
            }
            
            if tablesQuery.textFields["Last name"].exists {
                tablesQuery.textFields["Last name"].tap()
                tablesQuery.textFields["Last name"].typeText("User")
            }
            
            if tablesQuery.textFields["Address"].exists {
                tablesQuery.textFields["Address"].tap()
                tablesQuery.textFields["Address"].typeText("123 Test Street")
            }
            
            if tablesQuery.textFields["City"].exists {
                tablesQuery.textFields["City"].tap()
                tablesQuery.textFields["City"].typeText("Testville")
            }
            
            if tablesQuery.textFields["Postcode"].exists {
                tablesQuery.textFields["Postcode"].tap()
                tablesQuery.textFields["Postcode"].typeText("12345")
            }
            
            if tablesQuery.textFields["Phone"].exists {
                tablesQuery.textFields["Phone"].tap()
                tablesQuery.textFields["Phone"].typeText("5551234567")
            }
            
            if tablesQuery.textFields["Email address"].exists {
                tablesQuery.textFields["Email address"].tap()
                tablesQuery.textFields["Email address"].typeText("test@example.com")
            }
            
            if app.buttons["Place order"].exists {
                app.buttons["Place order"].tap()
            }
        }
    }
    
    // MARK: - Scenario 4: Image Loading Stress Test (Cache)
    
    func testScenario4_ImageLoadingStressTest() {
        measure(metrics: [
            XCTCPUMetric(),
            XCTMemoryMetric(),
            XCTClockMetric()
        ]) {
            navigateToCatalog()
            
            let collectionView = app.collectionViews.firstMatch
            waitForElement(collectionView)
            
            // Stress scroll up and down through the catalog to exercise image loading.
            for _ in 0..<5 {
                scroll(element: collectionView, times: 4)
                collectionView.swipeDown()
            }
        }
    }
    
    // MARK: - Scenario 5: Cold Start Performance
    
    func testScenario5_ColdStartPerformance() {
        // Terminate and relaunch to simulate cold start.
        app.terminate()
        
        measure(metrics: [
            XCTApplicationLaunchMetric(),
            XCTCPUMetric(),
            XCTMemoryMetric()
        ]) {
            let app = XCUIApplication()
            app.launchArguments.append(contentsOf: [
                "-UITest_PerformanceMode",
                "YES"
            ])
            app.launch()
            
            navigateToCatalog()
        }
    }
}
