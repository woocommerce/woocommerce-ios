import UITestsFoundation
import XCTest

final class ProductsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false

        let app = XCUIApplication()
        app.launchArguments = ["logout-at-launch", "disable-animations", "mocked-wpcom-api", "-ui_testing"]
        app.launch()
        try LoginFlow.login()
    }

    func test_load_products_screen() throws {
        let products = try GetMocks.readProductsData()

        try TabNavComponent().goToProductsScreen()
            .verifyProductsScreenLoaded()
            .verifyProductList(products: products)
            .tapProduct(byName: products[0].name)
            .verifyProduct(product: products[0])
            .goBackToProductList()
            .verifyProductsScreenLoaded()
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
            .setStockStatusFilterAs("Out of stock")
            .verifyProductFilterResults(products: products, filter: "Out of stock" )
    }
}
