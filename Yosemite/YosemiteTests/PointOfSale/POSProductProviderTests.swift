import XCTest
import WooFoundation
@testable import Networking
@testable import Yosemite

final class PointOfSaleProductServiceTests: XCTestCase {
    private var currencySettings: CurrencySettings!
    private var itemProvider: PointOfSaleItemServiceProtocol!
    private var network: MockNetwork!
    private let siteID: Int64 = 123

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        currencySettings = CurrencySettings()
        itemProvider = PointOfSaleProductService(siteID: siteID,
                                                 currencySettings: currencySettings,
                                                 network: network,
                                                 isVariableProductsFeatureEnabled: false)
    }

    override func tearDown() {
        currencySettings = nil
        itemProvider = nil
        super.tearDown()
    }

    func test_PointOfSaleItemServiceProtocol_when_fails_request_with_requestFailed_then_throws_error() async throws {
        // Given
        let expectedError = PointOfSaleProductServiceError.requestFailed
        network.simulateError(requestUrlSuffix: "products", error: expectedError)

        // When
        do {
            _ = try await itemProvider.providePointOfSaleItems()
            XCTFail("Expected an error, but got success.")
        } catch {
            // Then
            XCTAssertEqual(error as? PointOfSaleProductServiceError, expectedError)
        }
    }

    func test_PointOfSaleItemServiceProtocol_when_fails_request_with_pageOutOfRange_then_throws_error() async throws {
        let expectedError = PointOfSaleProductServiceError.pageOutOfRange
        network.simulateError(requestUrlSuffix: "products", error: expectedError)

        // When
        do {
            _ = try await itemProvider.providePointOfSaleItems()
            XCTFail("Expected an error, but got success.")
        } catch {
            // Then
            XCTAssertEqual(error as? PointOfSaleProductServiceError, expectedError)
        }
    }

    func test_PointOfSaleItemServiceProtocol_provides_no_items_when_store_has_no_products() async throws {
        // Given/When
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")
        let expectedItems = try await itemProvider.providePointOfSaleItems()

        // Then
        XCTAssertTrue(expectedItems.isEmpty)
    }

    func test_PointOfSaleItemServiceProtocol_provides_items_when_store_has_eligible_products() async throws {
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
        guard let item = expectedItems.first else {
            return XCTFail("No eligible products")
        }
        XCTAssertEqual(expectedItems.count, expectedNumberOfEligibleProducts)
        XCTAssertEqual(item.name, expectedProductName)
        XCTAssertEqual(item.formattedPrice, expectedFormattedPrice)

        guard let product = item as? POSProduct else {
            return XCTFail("Expected a POSProduct")
        }
        XCTAssertEqual(product.price, expectedProductPrice)
        XCTAssertEqual(product.productID, expectedProductID)
    }

    func test_PointOfSaleItemServiceProtocol_when_eligibility_criteria_applies_then_returns_correct_number_of_items() async throws {
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

    // MARK: - Query Parameters

    func test_providePointOfSaleItems_sets_types_parameters_to_simple_only() async throws {
        // Given
        let itemProvider = PointOfSaleProductService(siteID: siteID,
                                                     currencySettings: currencySettings,
                                                     network: network,
                                                     isVariableProductsFeatureEnabled: false)

        // When
        _ = try? await itemProvider.providePointOfSaleItems()

        // Then
        XCTAssertEqual(network.queryParametersDictionary?["include_types"] as? String, "simple")
    }

    func test_providePointOfSaleItems_sets_types_parameters_correctly_when_variable_products_feature_is_enabled() async throws {
        // Given
        let itemProvider = PointOfSaleProductService(siteID: siteID,
                                                     currencySettings: currencySettings,
                                                     network: network,
                                                     isVariableProductsFeatureEnabled: true)

        // When
        _ = try? await itemProvider.providePointOfSaleItems()

        // Then
        XCTAssertEqual(network.queryParametersDictionary?["include_types"] as? String, "simple,variable")
    }
}
