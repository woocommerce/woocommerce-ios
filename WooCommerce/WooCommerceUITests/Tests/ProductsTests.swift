import UITestsFoundation
import XCTest

final class ProductsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.logInWithWPcom()
    }

    func testProductsScreenLoad() throws {
        try TabNavComponent().gotoProductsScreen()
        XCTAssert(try ProductsScreen().isLoaded)

        let products = try GetMocks.readProductsData()
        let firstProductName = products.response.jsonBody.data[0].name
        try ProductsScreen().verifyProductNameOnProductsScreen(name: firstProductName)

        try ProductsScreen().selectProduct(atIndex: 0)
        try SingleProductScreen().verifyProductNameOnSingleProductScreen(name: firstProductName)

        try SingleProductScreen().goBackToProductList()
        XCTAssert(try ProductsScreen().isLoaded)
    }
}
