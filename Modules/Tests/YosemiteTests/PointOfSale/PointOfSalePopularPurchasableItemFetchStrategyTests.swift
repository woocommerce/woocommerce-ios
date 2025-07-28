import Testing
@testable import Yosemite
@testable import Networking

struct PointOfSalePopularPurchasableItemFetchStrategyTests {
    private let siteID: Int64 = 123
    private let pageSize = 10

    private var productsRemote: MockProductsRemote!
    private var variationsRemote: MockProductVariationsRemote!
    private var sut: PointOfSalePopularPurchasableItemFetchStrategy!

    init() {
        productsRemote = MockProductsRemote()
        variationsRemote = MockProductVariationsRemote()
        sut = PointOfSalePopularPurchasableItemFetchStrategy(
            siteID: siteID,
            pageSize: pageSize,
            productsRemote: productsRemote,
            variationsRemote: variationsRemote
        )
    }

    @Test("fetchProducts always returns hasMorePages false so we only show the first page")
    func test_fetchProducts_always_returns_hasMorePages_false() async throws {
        // Given
        let products = [
            POSProduct.fake().copy(siteID: siteID, productID: 1),
            POSProduct.fake().copy(siteID: siteID, productID: 2)
        ]
        let pagedProducts = PagedItems(items: products, hasMorePages: true, totalItems: 10)
        productsRemote.whenLoadingPopularProductsForPointOfSale(siteID: siteID, thenReturn: .success(pagedProducts))

        // When
        let result = try await sut.fetchProducts(pageNumber: 1)

        // Then
        #expect(result.hasMorePages == false)
        #expect(result.items.count == 2)
        #expect(result.items[0].productID == 1)
        #expect(result.items[1].productID == 2)
    }

    @Test("fetchProducts uses provided page size")
    func test_fetchProducts_uses_provided_page_size() async throws {
        // Given
        let products = [
            POSProduct.fake().copy(siteID: siteID, productID: 1),
            POSProduct.fake().copy(siteID: siteID, productID: 2)
        ]
        let pagedProducts = PagedItems(items: products, hasMorePages: true, totalItems: 10)
        productsRemote.whenLoadingPopularProductsForPointOfSale(siteID: siteID, thenReturn: .success(pagedProducts))

        // When
        _ = try await sut.fetchProducts(pageNumber: 1)

        // Then
        #expect(productsRemote.lastRequestedPageSize == pageSize)
    }

    @Test("fetchVariations loads all variations so popular variable parent products can be opened")
    func test_fetchVariations_loads_variations_for_variable_product() async throws {
        // Given
        let parentProductID: Int64 = 1
        let variations = [
            POSProductVariation.fake().copy(siteID: siteID, productID: parentProductID, productVariationID: 1),
            POSProductVariation.fake().copy(siteID: siteID, productID: parentProductID, productVariationID: 2)
        ]
        variationsRemote.whenLoadingVariationsForPointOfSale(siteID: siteID, parentProductID: parentProductID, thenReturn: .success(variations))

        // When
        let result = try await sut.fetchVariations(parentProductID: parentProductID, pageNumber: 1)

        // Then
        #expect(result.items.count == 2)
        #expect(result.items[0].productVariationID == 1)
        #expect(result.items[1].productVariationID == 2)
    }

    @Test("fetchVariations propagates errors")
    func test_fetchVariations_propagates_errors() async throws {
        // Given
        let parentProductID: Int64 = 1
        let error = NetworkError.notFound()
        variationsRemote.whenLoadingVariationsForPointOfSale(siteID: siteID, parentProductID: parentProductID, thenReturn: .failure(error))

        // When/Then
        await #expect(throws: error) {
            _ = try await sut.fetchVariations(parentProductID: parentProductID, pageNumber: 1)
        }
    }
}
