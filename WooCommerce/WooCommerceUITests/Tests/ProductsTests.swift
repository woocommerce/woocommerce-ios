import UITestsFoundation
import XCTest

final class ProductsTests: XCTestCase {

    let productTypes = [
        "physical": "Simple physical product",
        "virtual": "Virtual physical product",
        "variable": "Variable product",
        "grouped": "Grouped product",
        "external": "External product"
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.logInWithWPcom()
    }

    func test_load_products_screen() throws {
        let products = try GetMocks.readProductsData()

        try TabNavComponent().goToProductsScreen()
            .verifyProductsScreenLoaded()
            .verifyProductList(products: products)
            .selectProduct(byName: products[0].name)
            .verifyProduct(product: products[0])
            .goBackToProductList()
            .verifyProductsScreenLoaded()
    }

    func test_add_simple_physical_product() throws {
        let product = try GetMocks.readNewProductData()

        try TabNavComponent().goToProductsScreen()
            .tapAddProduct()
            .selectProductType(productType: productTypes["physical"]!)
            .addProductTitle(productTitle: product.name)
            .publishProduct()
            .verifyNewProductScreenLoaded()
    }
}
