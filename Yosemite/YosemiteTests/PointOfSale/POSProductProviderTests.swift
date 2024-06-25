import XCTest
import WooFoundation
@testable import Networking
@testable import Yosemite

final class POSProductProviderTests: XCTestCase {
    private var currencySettings: CurrencySettings!
    private var itemProvider: POSItemProvider!
    private var network: MockNetwork!
    private let siteID: Int64 = 123

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        currencySettings = CurrencySettings()
        itemProvider = POSProductProvider(siteID: siteID,
                                          currencySettings: currencySettings,
                                          network: network)
    }

    override func tearDown() {
        currencySettings = nil
        itemProvider = nil
        super.tearDown()
    }

    func test_POSItemProvider_provides_no_items_when_store_has_no_products() async throws {
        // Given/When
        let expectedItems = try await itemProvider.providePointOfSaleItems()

        // Then
        XCTAssertTrue(expectedItems.isEmpty)
    }

    func test_POSItemProvider_provides_items_when_store_has_eligible_products() async throws {
        // Given
        let expectedProductName = "Dymo LabelWriter 4XL"
        let expectedProductID: Int64 = 208
        let expectedProductPrice = "216"
        let expectedFormattedPrice = "$216.00"

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-type-simple")
        let expectedItems = try await itemProvider.providePointOfSaleItems()

        // Then
        guard let product = expectedItems.first else {
            return XCTFail("No eligible products")
        }
        XCTAssertEqual(product.name, expectedProductName)
        XCTAssertEqual(product.productID, expectedProductID)
        XCTAssertEqual(product.price, expectedProductPrice)
        XCTAssertEqual(product.formattedPrice, expectedFormattedPrice)
    }
}
