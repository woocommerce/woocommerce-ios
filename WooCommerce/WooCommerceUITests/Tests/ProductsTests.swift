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
        let products = try GetMocks.readProductsData()

        _ = try TabNavComponent()
            .gotoProductsScreen()
            .verifyProductScreenLoaded()
            .verifyProductListOnProductsScreen(count: products.count, name: products[0].name, status: products[0].stock_status)
            .selectProduct(byName: products[0].name)
            .verifyProductOnSingleProductScreen(name: products[0].name, price: products[0].regular_price, status: products[0].stock_status)
            .goBackToProductList()
            .verifyProductScreenLoaded()
    }
}
