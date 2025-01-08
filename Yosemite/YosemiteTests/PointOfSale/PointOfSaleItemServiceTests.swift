import XCTest
import WooFoundation
@testable import Networking
@testable import Yosemite

final class PointOfSaleItemServiceTests: XCTestCase {
    private var currencySettings: CurrencySettings!
    private var itemProvider: PointOfSaleItemServiceProtocol!
    private var network: MockNetwork!
    private let siteID: Int64 = 123

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        currencySettings = CurrencySettings()
        itemProvider = PointOfSaleItemService(siteID: siteID,
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
        let expectedError = PointOfSaleItemServiceError.requestFailed
        network.simulateError(requestUrlSuffix: "products", error: expectedError)

        // When
        do {
            _ = try await itemProvider.providePointOfSaleItems()
            XCTFail("Expected an error, but got success.")
        } catch {
            // Then
            XCTAssertEqual(error as? PointOfSaleItemServiceError, expectedError)
        }
    }

    func test_PointOfSaleItemServiceProtocol_when_empty_data_for_non_first_page_then_returns_empty_items_and_no_next_page() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")

        // When
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: 2)

        // Then
        XCTAssertTrue(pagedItems.items.isEmpty)
        XCTAssertFalse(pagedItems.hasMorePages)
    }

    func test_PointOfSaleItemServiceProtocol_provides_no_items_when_store_has_no_products() async throws {
        // Given/When
        network.simulateResponse(requestUrlSuffix: "products", filename: "empty-data-array")
        let pagedItems = try await itemProvider.providePointOfSaleItems()

        // Then
        XCTAssertTrue(pagedItems.items.isEmpty)
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
        let pagedItems = try await itemProvider.providePointOfSaleItems()

        // Then
        let expectedItems = pagedItems.items
        guard let item = expectedItems.first,
            case .simpleProduct(let simpleProduct) = item else {
            return XCTFail("No eligible products")
        }
        XCTAssertEqual(expectedItems.count, expectedNumberOfEligibleProducts)
        XCTAssertEqual(simpleProduct.name, expectedProductName)
        XCTAssertEqual(simpleProduct.formattedPrice, expectedFormattedPrice)
        XCTAssertEqual(simpleProduct.price, expectedProductPrice)
        XCTAssertEqual(simpleProduct.productID, expectedProductID)
    }

    func test_PointOfSaleItemServiceProtocol_when_eligibility_criteria_applies_then_returns_correct_number_of_items() async throws {
        // Given
        let expectedNumberOfItems = 2
        let expectedItemNames = ["Dymo LabelWriter 4XL", "Private Hoodie"]

        // When
        network.simulateResponse(requestUrlSuffix: "products", filename: "products-load-all-for-eligibility-criteria")
        let pagedItems = try await itemProvider.providePointOfSaleItems()

        // Then
        let expectedItems = pagedItems.items
        XCTAssertEqual(expectedItems.count, expectedNumberOfItems)

        guard case .simpleProduct(let firstEligibleSimpleProduct) = expectedItems.first,
              case .simpleProduct(let secondEligibleSimpleProduct) = expectedItems.last else {
            return XCTFail("Expected \(expectedNumberOfItems) eligible items. Got \(expectedItems.count) instead.")
        }
        XCTAssertEqual(firstEligibleSimpleProduct.name, expectedItemNames.first)
        XCTAssertEqual(secondEligibleSimpleProduct.name, expectedItemNames.last)
    }

    // MARK: - Query Parameters

    func test_providePointOfSaleItems_sets_types_parameters_to_simple_only() async throws {
        // Given
        let itemProvider = PointOfSaleItemService(siteID: siteID,
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
        let itemProvider = PointOfSaleItemService(siteID: siteID,
                                                     currencySettings: currencySettings,
                                                     network: network,
                                                     isVariableProductsFeatureEnabled: true)

        // When
        _ = try? await itemProvider.providePointOfSaleItems()

        // Then
        XCTAssertEqual(network.queryParametersDictionary?["include_types"] as? String, "simple,variable")
    }

    func test_providePointOfSaleVariationItems_returns_variations_when_load_succeeds() async throws {
        // Given
        let itemProvider = PointOfSaleItemService(siteID: siteID,
                                                  currencySettings: currencySettings,
                                                  network: network,
                                                  isVariableProductsFeatureEnabled: true)
        let parentProductID: Int64 = 123

        // When
        network.simulateResponse(requestUrlSuffix: "products/\(parentProductID)/variations", filename: "product-variations-load-all")
        let pagedVariations = try await itemProvider.providePointOfSaleVariationItems(
            for: .init(
                id: .init(),
                name: "Tea",
                productImageSource: nil,
                productID: parentProductID,
                type: .variable(
                    .init(allAttributes: [
                        .init(
                            siteID: siteID,
                            attributeID: 0,
                            name: "Shape",
                            position: 1,
                            visible: true,
                            variation: true,
                            options: ["Marble", "Heart"]
                        ),
                        .init(
                            siteID: siteID,
                            attributeID: 0,
                            name: "Flavor",
                            position: 2,
                            visible: true,
                            variation: true,
                            options: ["fruity", "nuts"]
                        ),
                        .init(
                            siteID: siteID,
                            attributeID: 0,
                            name: "Darkness",
                            position: 3,
                            visible: true,
                            variation: true,
                            options: ["99%", "87%"]
                        ),
                        .init(
                            siteID: siteID,
                            attributeID: 0,
                            name: "Size",
                            position: 4,
                            visible: true,
                            variation: true,
                            options: ["6 piece"]
                        )
                    ]
                ))
            ),
            pageNumber: 1
        )

        // Then
        let variations = pagedVariations.items

        XCTAssertFalse(variations.isEmpty)
        let firstVariation = try XCTUnwrap(variations.first)
        guard case let .variation(firstVariation) = firstVariation else {
            return XCTFail("Variation is expected.")
        }
        XCTAssertEqual(
            firstVariation.name,
            "marble - nuts - 99% - \(String.localizedStringWithFormat(VariationAttributeViewModel.Localization.anyAttributeFormat, "Size"))"
        )
        XCTAssertEqual(firstVariation.formattedPrice, "$12.00")
    }

    func test_providePointOfSaleVariationItems_throws_error_when_variations_load_fails() async throws {
        // Given
        let itemProvider = PointOfSaleItemService(siteID: siteID,
                                            currencySettings: currencySettings,
                                            network: network,
                                            isVariableProductsFeatureEnabled: true)
        let parentProductID: Int64 = 123
        let expectedError = PointOfSaleItemServiceError.requestFailed

        // When
        network.simulateError(requestUrlSuffix: "products/\(parentProductID)/variations", error: expectedError)

        // Then
        do {
            _ = try await itemProvider.providePointOfSaleVariationItems(
                for: .init(
                    id: .init(),
                    name: "Tea",
                    productImageSource: nil,
                    productID: parentProductID,
                    type: .variable(.init(allAttributes: []))
                ),
                pageNumber: 1
            )
            XCTFail("An error is expected.")
        } catch {
            XCTAssertEqual(error as? PointOfSaleItemServiceError, expectedError)
        }
    }
}
