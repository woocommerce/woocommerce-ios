import XCTest
import WooFoundation
@testable import Yosemite

final class POSProductProviderTests: XCTestCase {

    func test_POSProductProvider_returns_no_products_when_store_has_no_products() {
        let storageManager = MockStorageManager()
        let siteID: Int64 = 123
        let currencySettings = CurrencySettings()

        let sut = POSProductProvider(storageManager: storageManager,
                                     siteID: siteID,
                                     currencySettings: currencySettings)

        let products = sut.providePointOfSaleItems()

        XCTAssertTrue(products.isEmpty)
    }

    func test_POSProductProvider_returns_correctly_formatted_product_when_store_has_eligible_products() {
        let storageManager = MockStorageManager()
        let siteID: Int64 = 123
        let currencySettings = CurrencySettings()

        let sampleProduct = Product.fake().copy(siteID: 123,
                                                productID: 789,
                                                name: "Choco",
                                                productTypeKey: "simple",
                                                price: "2",
                                                purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: sampleProduct)

        let sut = POSProductProvider(storageManager: storageManager,
                                     siteID: siteID,
                                     currencySettings: currencySettings)

        let products = sut.providePointOfSaleItems()

        guard let product = products.first else {
            return XCTFail("No eligible products")
        }
        XCTAssertEqual(product.name, "Choco")
        XCTAssertEqual(product.productID, 789)
        XCTAssertEqual(product.price, "$2.00")
    }
}
