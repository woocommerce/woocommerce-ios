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
        let firstProductName = products.response.jsonBody.data[0].name
        let firstProductPrice = products.response.jsonBody.data[0].regular_price
        let firstProductStatus = products.response.jsonBody.data[0].stock_status
        let numberOfProducts = products.response.jsonBody.data.count

        _ = try TabNavComponent()
            .gotoProductsScreen()
            .verifyProductScreenLoaded()
            .verifyProductOnProductsScreen(count: numberOfProducts, name: firstProductName, status: firstProductStatus)
            .selectProduct(atIndex: 0)
            .verifyProductOnSingleProductScreen(name: firstProductName, status: firstProductStatus, price: firstProductPrice)
            .goBackToProductList()
            .verifyProductScreenLoaded()
    }
}
