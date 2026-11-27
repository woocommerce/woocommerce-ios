import UITestsFoundation
import XCTest

@MainActor
final class ProductsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        // XCTest runs synchronous setup on the main thread, where XCUI automation must stay.
        try MainActor.assumeIsolated {

            let app = XCUIApplication()
            app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
            if let designSystem = ProcessInfo.processInfo.environment["PRODUCTS_TEST_STORE_DESIGN_SYSTEM"] {
                app.launchArguments += ["-com.woocommerce.featureflag.override.storeDesignSystem", designSystem]
            }
            app.launch()
            try LoginFlow.login()
        }
    }

    func test_load_products_screen() throws {
        let products = try GetMocks.readProductsData()

        let productScreen = try TabNavComponent().goToProductsScreen()
            .verifyProductsScreenLoaded()
            .verifyProductList(products: products)
            .tapProduct(byName: products[0].name)
            .verifyProduct(product: products[0])

        if let designSystem = ProcessInfo.processInfo.environment["PRODUCTS_TEST_STORE_DESIGN_SYSTEM"] {
            XCTAssertEqual(XCUIApplication().scrollViews["product-form"].exists, designSystem == "YES")
        }

        try productScreen.goBackToProductList()
            .verifyProductsScreenLoaded()
    }

    func test_store_product_form_routes_to_child_editors() throws {
        try XCTSkipIf(ProcessInfo.processInfo.environment["PRODUCTS_TEST_STORE_DESIGN_SYSTEM"] == "NO")
        let products = try GetMocks.readProductsData()
        let app = XCUIApplication()

        _ = try TabNavComponent().goToProductsScreen().tapProduct(byName: products[0].name)
        XCTAssertTrue(app.scrollViews["product-form"].exists)

        app.buttons["Add more details"].tap()
        let shortDescription = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Short description")).firstMatch
        XCTAssertTrue(shortDescription.waitForExistence(timeout: 5))
        shortDescription.tap()
        let editorBar = app.navigationBars["Short description"]
        XCTAssertTrue(editorBar.waitForExistence(timeout: 5))
        editorBar.buttons.element(boundBy: 0).tap()

        app.buttons["edit-product-more-options-button"].tap()
        let productSettings = app.buttons["Product Settings"]
        XCTAssertTrue(productSettings.waitForExistence(timeout: 5))
        productSettings.tap()
        XCTAssertTrue(app.navigationBars["Product Settings"].waitForExistence(timeout: 5))
    }

    func test_add_simple_physical_product() throws {
        try ProductFlow.addAndVerifyNewProduct(productType: "physical")
    }

    func test_add_simple_virtual_product() throws {
        try ProductFlow.addAndVerifyNewProduct(productType: "virtual")
    }

    func test_add_variable_product() throws {
        try ProductFlow.addAndVerifyNewProduct(productType: "variable")
    }

    func test_add_grouped_product() throws {
        try ProductFlow.addAndVerifyNewProduct(productType: "grouped")
    }

    func test_add_external_product() throws {
        try ProductFlow.addAndVerifyNewProduct(productType: "external")
    }

    func test_search_product() throws {
        let products = try GetMocks.readProductsData()

        try TabNavComponent().goToProductsScreen()
            .tapSearchButton()
            .verifyNumberOfProductsInSearchResults(equals: products.count)
            .enterSearchCriteria(text: products[0].name)
            .verifyProductSearchResults(expectedProduct: products[0])
    }

    func test_filter_product() throws {
        let products = try GetMocks.readProductsData()

        try TabNavComponent().goToProductsScreen()
            .tapFilterButton()
            .setStockStatusFilterAs("outofstock")
            .verifyProductFilterResults(products: products, filter: "outofstock" )
    }
}
