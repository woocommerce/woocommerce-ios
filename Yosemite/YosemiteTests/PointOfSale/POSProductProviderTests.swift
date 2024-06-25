import XCTest
import WooFoundation
@testable import Yosemite

final class POSProductProviderTests: XCTestCase {
    private var storageManager: MockStorageManager!
    private var currencySettings: CurrencySettings!
    private var itemProvider: MockPOSItemProvider!
    private let siteID: Int64 = 123

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        itemProvider = MockPOSItemProvider()
        currencySettings = CurrencySettings()
    }

    override func tearDown() {
        storageManager = nil
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
        let productPrice = "2"
        let expectedFormattedPrice = "$2.00"
        let item = POSProduct(itemID: UUID(),
                              productID: 789,
                              name: "Choco",
                              price: productPrice,
                              formattedPrice: "$2.00",
                              itemCategories: [],
                              productImageSource: nil,
                              productType: .simple)

        // When
        itemProvider.simulate(items: [item])
        let expectedItems = try await itemProvider.providePointOfSaleItems()

        // Then
        guard let product = expectedItems.first else {
            return XCTFail("No eligible products")
        }
        XCTAssertEqual(product.name, "Choco")
        XCTAssertEqual(product.productID, 789)
        XCTAssertEqual(product.price, productPrice)
        XCTAssertEqual(product.formattedPrice, expectedFormattedPrice)
    }
}

private extension POSProductProviderTests {
    final class MockPOSItemProvider: POSItemProvider {
        var items: [POSItem] = []

        func providePointOfSaleItems() async throws -> [Yosemite.POSItem] {
            return items
        }

        func simulate(items: [POSItem]) {
            for item in items {
                self.items.append(item)
            }
        }
    }
}
