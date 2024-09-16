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

    func test_POSItemProvider_when_fails_request_then_throws_error() async throws {
        // Given
        let expectedError = POSProductProvider.POSProductProviderError.requestFailed
        network.simulateError(requestUrlSuffix: "products", error: expectedError)

        // When
        do {
            _ = try await itemProvider.providePointOfSaleItems()
            XCTFail("Expected an error, but got success.")
        } catch {
            // Then
            XCTAssertEqual(error as? POSProductProvider.POSProductProviderError, expectedError)
        }
    }

    func test_POSItemProvider_provides_no_items_when_store_has_no_products() async throws {
        // Given/When
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")
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
        let expectedNumberOfEligibleProducts = 6

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-type-simple")
        let expectedItems = try await itemProvider.providePointOfSaleItems()

        // Then
        guard let product = expectedItems.first else {
            return XCTFail("No eligible products")
        }
        XCTAssertEqual(expectedItems.count, expectedNumberOfEligibleProducts)
        XCTAssertEqual(product.name, expectedProductName)
        XCTAssertEqual(product.productID, expectedProductID)
        XCTAssertEqual(product.price, expectedProductPrice)
        XCTAssertEqual(product.formattedPrice, expectedFormattedPrice)
    }

    func test_POSItemProvider_when_eligibility_criteria_applies_then_returns_correct_number_of_items() async throws {
        // Given
        let expectedNumberOfItems = 2
        let expectedItemNames = ["Dymo LabelWriter 4XL", "Private Hoodie"]

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-for-eligibility-criteria")
        let expectedItems = try await itemProvider.providePointOfSaleItems()

        // Then
        XCTAssertEqual(expectedItems.count, expectedNumberOfItems)

        guard let firstEligibleItem = expectedItems.first,
              let secondEligibleItem = expectedItems.last else {
            return XCTFail("Expected \(expectedNumberOfItems) eligible items. Got \(expectedItems.count) instead.")
        }
        XCTAssertEqual(firstEligibleItem.name, expectedItemNames.first)
        XCTAssertEqual(secondEligibleItem.name, expectedItemNames.last)
    }
}
