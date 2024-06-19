import XCTest
import WooFoundation
@testable import Yosemite

final class POSProductProviderTests: XCTestCase {

    private var storageManager: MockStorageManager!
    private var currencySettings: CurrencySettings!
    private var itemProvider: POSItemProvider!
    private let siteID: Int64 = 123

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        currencySettings = CurrencySettings()
    }

    override func tearDown() {
        storageManager = nil
        currencySettings = nil
        itemProvider = nil
        super.tearDown()
    }

    func test_POSItemProvider_provides_no_items_when_store_has_no_products() {
        // Given
        itemProvider = POSProductProvider(storageManager: storageManager,
                                     siteID: siteID,
                                     currencySettings: currencySettings)

        // When
        let items = itemProvider.providePointOfSaleItems()

        // Then
        XCTAssertTrue(items.isEmpty)
    }

    func test_POSItemProvider_provides_no_items_when_store_has_no_eligible_products() {
        // Given
        let nonEligibleProduct = Product.fake().copy(siteID: siteID,
                                                productID: 789,
                                                name: "Choco",
                                                productTypeKey: "not simple",
                                                price: "2",
                                                purchasable: true)

        storageManager.insertSampleProduct(readOnlyProduct: nonEligibleProduct)
        itemProvider = POSProductProvider(storageManager: storageManager,
                                     siteID: siteID,
                                     currencySettings: currencySettings)

        // When
        let items = itemProvider.providePointOfSaleItems()

        // Then
        XCTAssertTrue(items.isEmpty)
    }

    func test_POSItemProvider_when_store_has_eligible_products_then_provides_correctly_formatted_product() {
        // Given
        let productPrice = "2"
        let expectedFormattedPrice = "$2.00"
        let eligibleProduct = Product.fake().copy(siteID: siteID,
                                                productID: 789,
                                                name: "Choco",
                                                productTypeKey: "simple",
                                                price: productPrice,
                                                purchasable: true)

        storageManager.insertSampleProduct(readOnlyProduct: eligibleProduct)
        itemProvider = POSProductProvider(storageManager: storageManager,
                                     siteID: siteID,
                                     currencySettings: currencySettings)

        // When
        let items = itemProvider.providePointOfSaleItems()

        // Then
        guard let product = items.first else {
            return XCTFail("No eligible products")
        }
        XCTAssertEqual(product.name, "Choco")
        XCTAssertEqual(product.productID, 789)
        XCTAssertEqual(product.price, productPrice)
        XCTAssertEqual(product.formattedPrice, expectedFormattedPrice)
    }
}
