import Testing
@testable import WooCommerce
@testable import Yosemite

final class PointOfSalePopularItemsControllerTests {
    @available(iOS 17.0, *)
    @Test("Load popular items for product successfully")
    func testLoadPopularItemsForProduct() async {
        // Given
        let mockItemProvider = MockPointOfSalePopularItemService()
        let expectedItems = [POSItem.simpleProduct(.fake().copy(name: "Product 1")), POSItem.simpleProduct(.fake().copy(name: "Product 2"))]
        mockItemProvider.mockPagedItems = PagedItems(items: expectedItems, hasMorePages: false)
        let fetchStrategy = MockPointOfSalePopularPurchasableItemFetchStrategy()
        let sut = PointOfSalePopularItemsController(itemProvider: mockItemProvider, fetchStrategy: fetchStrategy)

        // When
        await sut.loadPopularItems(for: .product)

        // Then
        #expect(sut.itemsByType[.product] == expectedItems)
        #expect(!sut.isLoading)
    }

    @available(iOS 17.0, *)
    @Test("Handle error when loading popular items for product")
    func testLoadPopularItemsForProductError() async {
        // Given
        let mockItemProvider = MockPointOfSalePopularItemService()
        mockItemProvider.shouldFail = true
        let fetchStrategy = MockPointOfSalePopularPurchasableItemFetchStrategy()
        let sut = PointOfSalePopularItemsController(itemProvider: mockItemProvider, fetchStrategy: fetchStrategy)

        // When
        await sut.loadPopularItems(for: .product)

        // Then
        #expect(sut.itemsByType[.product] == [])
        #expect(!sut.isLoading)
    }

    @available(iOS 17.0, *)
    @Test("Set empty array for coupon type")
    func testLoadPopularItemsForCoupon() async {
        // Given
        let mockItemProvider = MockPointOfSalePopularItemService()
        let fetchStrategy = MockPointOfSalePopularPurchasableItemFetchStrategy()
        let sut = PointOfSalePopularItemsController(itemProvider: mockItemProvider, fetchStrategy: fetchStrategy)

        // When
        await sut.loadPopularItems(for: .coupon)

        // Then
        #expect(sut.itemsByType[.coupon] == [])
        #expect(!sut.isLoading)
        #expect(!mockItemProvider.providePointOfSaleItemsCalled)
    }

    @available(iOS 17.0, *)
    @Test("Set empty array for variation type")
    func testLoadPopularItemsForVariation() async {
        // Given
        let mockItemProvider = MockPointOfSalePopularItemService()
        let fetchStrategy = MockPointOfSalePopularPurchasableItemFetchStrategy()
        let sut = PointOfSalePopularItemsController(itemProvider: mockItemProvider, fetchStrategy: fetchStrategy)

        // When
        await sut.loadPopularItems(for: .variation)

        // Then
        #expect(sut.itemsByType[.variation] == [])
        #expect(!sut.isLoading)
        #expect(!mockItemProvider.providePointOfSaleItemsCalled)
    }

    @available(iOS 17.0, *)
    @Test("Loading state is set correctly")
    func testLoadingState() async {
        // Given
        let mockItemProvider = MockPointOfSalePopularItemService()
        mockItemProvider.mockPagedItems = PagedItems(items: [], hasMorePages: false)
        let fetchStrategy = MockPointOfSalePopularPurchasableItemFetchStrategy()
        let sut = PointOfSalePopularItemsController(itemProvider: mockItemProvider, fetchStrategy: fetchStrategy)

        // When
        #expect(sut.isLoading == false)
        await sut.loadPopularItems(for: .product)
        #expect(sut.isLoading == false)
    }
}

// MARK: - Mock PointOfSaleItemService

private final class MockPointOfSalePopularItemService: PointOfSaleItemServiceProtocol {
    var mockPagedItems: PagedItems<POSItem>?
    var shouldFail = false
    private(set) var providePointOfSaleItemsCalled = false

    func providePointOfSaleItems(pageNumber: Int, fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        providePointOfSaleItemsCalled = true

        if shouldFail {
            throw NSError(domain: "test", code: -1)
        }

        return mockPagedItems ?? PagedItems(items: [], hasMorePages: false)
    }

    func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct,
                                          pageNumber: Int,
                                          fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem> {
        PagedItems(items: [], hasMorePages: false)
    }
}

// MARK: - Mock Fetch Strategy
// This isn't actually used; we ignore it in our mock item service above.
private final class MockPointOfSalePopularPurchasableItemFetchStrategy: PointOfSalePurchasableItemFetchStrategy {
    func fetchProducts(pageNumber: Int) async throws -> PagedItems<POSProduct> {
        PagedItems(items: [], hasMorePages: false)
    }

    func fetchVariations(parentProductID: Int64, pageNumber: Int) async throws -> PagedItems<ProductVariation> {
        PagedItems(items: [], hasMorePages: false)
    }
}
