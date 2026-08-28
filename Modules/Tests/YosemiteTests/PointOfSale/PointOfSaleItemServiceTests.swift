import XCTest
import WooFoundation
@testable import Yosemite

final class PointOfSaleItemServiceTests: XCTestCase {
    private var currencySettings: CurrencySettings!
    private var itemProvider: PointOfSaleItemServiceProtocol!
    private var mockItemMapper: MockPointOfSaleItemMapper!
    private let siteID: Int64 = 13092

    override func setUp() {
        super.setUp()
        currencySettings = CurrencySettings()
        mockItemMapper = MockPointOfSaleItemMapper()
        itemProvider = PointOfSaleItemService(currencySettings: currencySettings, itemMapper: mockItemMapper)
    }

    override func tearDown() {
        currencySettings = nil
        itemProvider = nil
        mockItemMapper = nil
        super.tearDown()
    }

    func test_PointOfSaleItemServiceProtocol_when_fails_request_with_requestFailed_then_throws_error() async throws {
        // Given
        let expectedError = PointOfSaleItemServiceError.requestFailed
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedProductsResult = .failure(expectedError)

        // When
        do {
            _ = try await itemProvider.providePointOfSaleItems(pageNumber: 1, fetchStrategy: mockFetchStrategy)
            XCTFail("Expected an error, but got success.")
        } catch {
            // Then
            XCTAssertEqual(error as? PointOfSaleItemServiceError, expectedError)
        }
    }

    func test_PointOfSaleItemServiceProtocol_when_empty_data_for_non_first_page_of_products_then_returns_empty_items_and_no_next_page() async throws {
        // Given
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedProductsResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))

        // When
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: 2, fetchStrategy: mockFetchStrategy)

        // Then
        XCTAssertTrue(pagedItems.items.isEmpty)
        XCTAssertFalse(pagedItems.hasMorePages)
    }

    func test_PointOfSaleItemServiceProtocol_provides_no_items_when_store_has_no_products() async throws {
        // Given
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedProductsResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        mockItemMapper.mockMappedProducts = []

        // When
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: 1, fetchStrategy: mockFetchStrategy)

        // Then
        XCTAssertTrue(pagedItems.items.isEmpty)
        XCTAssertTrue(mockItemMapper.mapProductsToPOSItemsCalled)
        XCTAssertEqual(mockItemMapper.mockProducts.count, 0)
    }

    func test_PointOfSaleItemServiceProtocol_provides_items_when_store_has_eligible_products() async throws {
        // Given
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        let mockProduct = POSProduct.fake().copy(
            productID: 208,
            name: "Dymo LabelWriter 4XL",
            price: "216"
        )
        mockFetchStrategy.mockPagedProductsResult = .success(PagedItems(items: [mockProduct],
                                                                        hasMorePages: false,
                                                                        totalItems: 1))

        let expectedItem = POSItem.simpleProduct(POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 208),
            name: "Dymo LabelWriter 4XL",
            formattedPrice: "$216.00",
            productID: 208,
            price: "216",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: ""
        ))
        mockItemMapper.mockMappedProducts = [expectedItem]

        // When
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: 1, fetchStrategy: mockFetchStrategy)

        // Then
        XCTAssertEqual(pagedItems.items.count, 1)
        XCTAssertTrue(mockItemMapper.mapProductsToPOSItemsCalled)
        XCTAssertEqual(mockItemMapper.mockProducts.count, 1)
        XCTAssertEqual(mockItemMapper.mockProducts.first?.productID, 208)
        XCTAssertEqual(pagedItems.items.first, expectedItem)
    }

    func test_PointOfSaleItemServiceProtocol_when_eligibility_criteria_applies_then_returns_correct_number_of_items() async throws {
        // Given
        let expectedItemNames = ["Dymo LabelWriter 4XL", "Virtual Polo", "Private Hoodie", "Hoodie with Zipper without price"]
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()

        let mockProducts = [
            POSProduct.fake().copy(name: "Dymo LabelWriter 4XL", productTypeKey: "simple"),
            POSProduct.fake().copy(name: "Virtual Polo", productTypeKey: "simple"),
            POSProduct.fake().copy(name: "Private Hoodie", productTypeKey: "simple"),
            POSProduct.fake().copy(name: "Hoodie with Zipper without price", productTypeKey: "simple")
        ]
        mockFetchStrategy.mockPagedProductsResult = .success(PagedItems(items: mockProducts,
                                                                        hasMorePages: false,
                                                                        totalItems: mockProducts.count))

        let mockMappedProducts = mockProducts.map { product in
            POSItem.simpleProduct(POSSimpleProduct(
                id: POSItemIdentifier(underlyingType: .product, itemID: product.productID),
                name: product.name,
                formattedPrice: "$0.00",
                productID: product.productID,
                price: "",
                manageStock: false,
                stockQuantity: nil,
                stockStatusKey: ""
            ))
        }
        mockItemMapper.mockMappedProducts = mockMappedProducts

        // When
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: 1, fetchStrategy: mockFetchStrategy)

        // Then
        let items = pagedItems.items
        XCTAssertEqual(items.count, expectedItemNames.count)

        let itemNames: [String] = items.compactMap {
            guard case let .simpleProduct(simpleProduct) = $0 else {
                XCTFail("Expected simple product.")
                return nil
            }
            return simpleProduct.name
        }
        XCTAssertEqual(itemNames, expectedItemNames)
    }

    // MARK: - Query Parameters

    func test_providePointOfSaleItems_uses_mapper_correctly() async throws {
        // Given
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        let mockProduct = POSProduct.fake().copy(
            productID: 123,
            name: "Test Product",
            price: "10.00",
            manageStock: true,
            stockQuantity: 5,
            stockStatusKey: "instock"
        )
        mockFetchStrategy.mockPagedProductsResult = .success(PagedItems(items: [mockProduct],
                                                                        hasMorePages: false,
                                                                        totalItems: 1))

        // When
        _ = try await itemProvider.providePointOfSaleItems(pageNumber: 1, fetchStrategy: mockFetchStrategy)

        // Then
        XCTAssertTrue(mockItemMapper.mapProductsToPOSItemsCalled)
        XCTAssertEqual(mockItemMapper.mockProducts, [mockProduct])
    }

    func test_providePointOfSaleVariationItems_returns_variations_with_non_downloadable_filter_when_load_succeeds() async throws {
        // Given
        let parentProductID: Int64 = 123
        let parentProduct = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: parentProductID),
            name: "Tea",
            productImageSource: nil,
            productID: parentProductID,
            allAttributes: teaAttributes
        )

        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        let mockVariation = POSProductVariation.fake().copy(
            productID: parentProductID,
            productVariationID: 1274,
            image: .fake().copy(src: "https://example.com/variation.jpg"),
            price: "",
            downloadable: false
        )
        mockFetchStrategy.mockPagedVariationsResult = .success(PagedItems(items: [mockVariation],
                                                                          hasMorePages: false,
                                                                          totalItems: 1))

        let expectedVariation = POSItem.variation(POSVariation(
            id: POSItemIdentifier(underlyingType: .variation, itemID: 1274),
            name: "Shape: brick, Flavor: nuts, Darkness: 99%, Size: Any",
            formattedPrice: "$0.00",
            price: "",
            productImageSource: "https://example.com/variation.jpg",
            productID: parentProductID,
            variationID: 1274,
            parentProductName: "Tea"
        ))
        mockItemMapper.mockMappedVariations = [expectedVariation]

        // When
        let pagedVariations = try await itemProvider.providePointOfSaleVariationItems(
            for: parentProduct,
            pageNumber: 1,
            fetchStrategy: mockFetchStrategy
        )

        // Then
        XCTAssertEqual(pagedVariations.items.count, 1)
        XCTAssertTrue(mockItemMapper.mapVariationsToPOSItemsCalled)
        XCTAssertEqual(mockItemMapper.mockVariations.count, 1)
        XCTAssertEqual(mockItemMapper.mockParentProduct?.productID, parentProductID)
        XCTAssertEqual(pagedVariations.items.first, expectedVariation)
    }

    func test_providePointOfSaleVariationItems_returns_variation_page_details_when_load_succeeds() async throws {
        // Given
        let parentProductID: Int64 = 123
        let parentProduct = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: parentProductID),
            name: "Tea",
            productImageSource: nil,
            productID: parentProductID,
            allAttributes: [
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
        )

        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedVariationsResult = .success(PagedItems(items: [], hasMorePages: true, totalItems: 0))
        mockItemMapper.mockMappedVariations = []

        // When
        let pagedVariations = try await itemProvider.providePointOfSaleVariationItems(
            for: parentProduct,
            pageNumber: 1,
            fetchStrategy: mockFetchStrategy
        )

        // Then
        XCTAssertTrue(pagedVariations.hasMorePages)
        XCTAssertTrue(mockItemMapper.mapVariationsToPOSItemsCalled)
    }

    func test_providePointOfSaleVariationItems_throws_error_when_variations_load_fails() async throws {
        // Given
        let parentProductID: Int64 = 123
        let expectedError = PointOfSaleItemServiceError.requestFailed
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedVariationsResult = .failure(expectedError)

        // When
        do {
            _ = try await itemProvider.providePointOfSaleVariationItems(
                for: .init(
                    id: POSItemIdentifier(underlyingType: .product, itemID: parentProductID),
                    name: "Tea",
                    productImageSource: nil,
                    productID: parentProductID,
                    allAttributes: []
                ),
                pageNumber: 1,
                fetchStrategy: mockFetchStrategy
            )
            XCTFail("An error is expected.")
        } catch {
            XCTAssertEqual(error as? PointOfSaleItemServiceError, expectedError)
        }
    }

    func test_providePointOfSaleVariationItems_formats_empty_prices_as_zero() async throws {
        // Given
        let parentProductID: Int64 = 123
        let parentProduct = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: parentProductID),
            name: "Tea",
            productImageSource: nil,
            productID: parentProductID,
            allAttributes: teaAttributes
        )

        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedVariationsResult = .success(PagedItems(items: [POSProductVariation.fake()],
                                                                          hasMorePages: false,
                                                                          totalItems: 1))

        let expectedVariation = POSItem.variation(POSVariation(
            id: POSItemIdentifier(underlyingType: .variation, itemID: 1274),
            name: "Shape: brick, Flavor: nuts, Darkness: 99%, Size: Any",
            formattedPrice: "$0.00",
            price: "",
            productImageSource: nil,
            productID: parentProductID,
            variationID: 1274,
            parentProductName: "Tea"
        ))
        mockItemMapper.mockMappedVariations = [expectedVariation]

        // When
        let pagedVariations = try await itemProvider.providePointOfSaleVariationItems(
            for: parentProduct,
            pageNumber: 1,
            fetchStrategy: mockFetchStrategy
        )

        // Then
        XCTAssertEqual(pagedVariations.items.count, 1)
        XCTAssertTrue(mockItemMapper.mapVariationsToPOSItemsCalled)
        XCTAssertEqual(mockItemMapper.mockVariations.count, 1)
        XCTAssertEqual(pagedVariations.items.first, expectedVariation)
    }

    func test_providePointOfSaleItems_uses_passed_fetch_strategy() async throws {
        // Given
        let fetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()

        // When
        _ = try await itemProvider.providePointOfSaleItems(pageNumber: 5, fetchStrategy: fetchStrategy)

        // Then
        XCTAssertTrue(fetchStrategy.fetchProductsCalled)
        XCTAssertEqual(fetchStrategy.spyFetchProductsPageNumber, 5)
    }

    func test_providePointOfSaleSimpleProductItems_returns_expected_items() async throws {
        // Given
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedProductsResult = .success(PagedItems(items: [POSProduct.fake()],
                                                                        hasMorePages: false,
                                                                        totalItems: 1))

        let expectedItem = POSItem.simpleProduct(POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Test Product",
            formattedPrice: "$10.00",
            productID: 1,
            price: "10.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: ""
        ))
        mockItemMapper.mockMappedProducts = [expectedItem]

        // When
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: 1, fetchStrategy: mockFetchStrategy)

        // Then
        XCTAssertEqual(pagedItems.items.count, 1)
        XCTAssertTrue(mockItemMapper.mapProductsToPOSItemsCalled)
        XCTAssertEqual(mockItemMapper.mockProducts.count, 1)
        XCTAssertEqual(pagedItems.items.first, expectedItem)
    }

    func test_providePointOfSaleVariationItems_returns_expected_items() async throws {
        // Given
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedVariationsResult = .success(PagedItems(items: [POSProductVariation.fake()],
                                                                          hasMorePages: false,
                                                                          totalItems: 1))

        let expectedItem = POSItem.variation(POSVariation(
            id: POSItemIdentifier(underlyingType: .variation, itemID: 10),
            name: "Test Variation",
            formattedPrice: "$20.00",
            price: "20.00",
            productID: 1,
            variationID: 10,
            parentProductName: "Test Variable Product"
        ))
        mockItemMapper.mockMappedVariations = [expectedItem]

        let parentProduct = POSVariableParentProduct(id: POSItemIdentifier(underlyingType: .product, itemID: 1),
                                                          name: "Test Variable Product",
                                                          productImageSource: nil,
                                                          productID: 1)


        // When
        let pagedItems = try await itemProvider.providePointOfSaleVariationItems(for: parentProduct,
                                                                                 pageNumber: 1,
                                                                                 fetchStrategy: mockFetchStrategy)

        // Then
        XCTAssertEqual(pagedItems.items.count, 1)
        XCTAssertTrue(mockItemMapper.mapVariationsToPOSItemsCalled)
        XCTAssertEqual(mockItemMapper.mockVariations.count, 1)
        XCTAssertEqual(pagedItems.items.first, expectedItem)
    }

    func test_providePointOfSaleItems_handles_fetch_error() async {
        // Given
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedProductsResult = .failure(TestError.expectedError)

        // When/Then
        do {
            _ = try await itemProvider.providePointOfSaleItems(pageNumber: 1, fetchStrategy: mockFetchStrategy)
            XCTFail("Expected error to be thrown")
        } catch TestError.expectedError {
            // No-op – this should happen!
        } catch {
            XCTFail("An unexpected error occurred: \(error)")
        }
    }

    func test_providePointOfSaleItems_handles_empty_results() async throws {
        // Given
        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        mockFetchStrategy.mockPagedProductsResult = .success(PagedItems(items: [], hasMorePages: false, totalItems: 0))
        mockItemMapper.mockMappedProducts = []

        // When
        let pagedItems = try await itemProvider.providePointOfSaleItems(pageNumber: 1, fetchStrategy: mockFetchStrategy)

        // Then
        XCTAssertEqual(pagedItems.items.count, 0)
        XCTAssertTrue(mockItemMapper.mapProductsToPOSItemsCalled)
        XCTAssertEqual(mockItemMapper.mockProducts.count, 0)
    }

    func test_providePointOfSaleVariationItems_passes_correct_data_to_mapper() async throws {
        // Given
        let parentProductID: Int64 = 123
        let parentProduct = POSVariableParentProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: parentProductID),
            name: "Test Variable Product",
            productImageSource: nil,
            productID: parentProductID,
            allAttributes: []
        )

        let mockFetchStrategy = MockPointOfSalePurchasableItemFetchStrategy()
        let mockVariation = POSProductVariation.fake().copy(
            productID: parentProductID,
            productVariationID: 456,
            price: "20.00",
            manageStock: true,
            stockQuantity: 10,
            stockStatusKey: "instock"
        )
        mockFetchStrategy.mockPagedVariationsResult = .success(PagedItems(items: [mockVariation],
                                                                          hasMorePages: false,
                                                                          totalItems: 1))

        // When
        _ = try await itemProvider.providePointOfSaleVariationItems(
            for: parentProduct,
            pageNumber: 1,
            fetchStrategy: mockFetchStrategy
        )

        // Then
        XCTAssertTrue(mockItemMapper.mapVariationsToPOSItemsCalled)
        XCTAssertEqual(mockItemMapper.mockVariations, [mockVariation])
        XCTAssertEqual(mockItemMapper.mockParentProduct, parentProduct)
    }
}

private extension PointOfSaleItemServiceTests {
    var teaAttributes: [ProductAttribute] {
        [
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
    }

    enum TestError: Error {
        case expectedError
    }
}
