import Foundation
import Testing
import Networking
@testable import Storage
@testable import Yosemite

@Suite("SearchDebounceStrategy Tests")
struct SearchDebounceStrategyTests {

    // MARK: - Equatable Tests

    @Test("Smart strategies with same duration are equal")
    func test_smart_strategies_with_same_duration_are_equal() {
        let strategy1: SearchDebounceStrategy = .smart(duration: 500 * NSEC_PER_MSEC)
        let strategy2: SearchDebounceStrategy = .smart(duration: 500 * NSEC_PER_MSEC)

        #expect(strategy1 == strategy2)
    }

    @Test("Smart strategies with different durations are not equal")
    func test_smart_strategies_with_different_durations_are_not_equal() {
        let strategy1: SearchDebounceStrategy = .smart(duration: 500 * NSEC_PER_MSEC)
        let strategy2: SearchDebounceStrategy = .smart(duration: 300 * NSEC_PER_MSEC)

        #expect(strategy1 != strategy2)
    }

    @Test("Simple strategies with same duration and no threshold are equal")
    func test_simple_strategies_with_same_duration_and_no_threshold_are_equal() {
        let strategy1: SearchDebounceStrategy = .simple(duration: 150 * NSEC_PER_MSEC)
        let strategy2: SearchDebounceStrategy = .simple(duration: 150 * NSEC_PER_MSEC)

        #expect(strategy1 == strategy2)
    }

    @Test("Simple strategies with same duration and same threshold are equal")
    func test_simple_strategies_with_same_duration_and_threshold_are_equal() {
        let strategy1: SearchDebounceStrategy = .simple(duration: 150 * NSEC_PER_MSEC, loadingDelayThreshold: 300 * NSEC_PER_MSEC)
        let strategy2: SearchDebounceStrategy = .simple(duration: 150 * NSEC_PER_MSEC, loadingDelayThreshold: 300 * NSEC_PER_MSEC)

        #expect(strategy1 == strategy2)
    }

    @Test("Simple strategies with different durations are not equal")
    func test_simple_strategies_with_different_durations_are_not_equal() {
        let strategy1: SearchDebounceStrategy = .simple(duration: 150 * NSEC_PER_MSEC, loadingDelayThreshold: 300 * NSEC_PER_MSEC)
        let strategy2: SearchDebounceStrategy = .simple(duration: 200 * NSEC_PER_MSEC, loadingDelayThreshold: 300 * NSEC_PER_MSEC)

        #expect(strategy1 != strategy2)
    }

    @Test("Simple strategies with different thresholds are not equal")
    func test_simple_strategies_with_different_thresholds_are_not_equal() {
        let strategy1: SearchDebounceStrategy = .simple(duration: 150 * NSEC_PER_MSEC, loadingDelayThreshold: 300 * NSEC_PER_MSEC)
        let strategy2: SearchDebounceStrategy = .simple(duration: 150 * NSEC_PER_MSEC, loadingDelayThreshold: 400 * NSEC_PER_MSEC)

        #expect(strategy1 != strategy2)
    }

    @Test("Immediate strategies are equal")
    func test_immediate_strategies_are_equal() {
        let strategy1: SearchDebounceStrategy = .immediate
        let strategy2: SearchDebounceStrategy = .immediate

        #expect(strategy1 == strategy2)
    }

    @Test("Different strategy types are not equal")
    func test_different_strategy_types_are_not_equal() {
        let smartStrategy: SearchDebounceStrategy = .smart(duration: 500 * NSEC_PER_MSEC)
        let simpleStrategy: SearchDebounceStrategy = .simple(duration: 150 * NSEC_PER_MSEC)
        let immediateStrategy: SearchDebounceStrategy = .immediate

        #expect(smartStrategy != simpleStrategy)
        #expect(smartStrategy != immediateStrategy)
        #expect(simpleStrategy != immediateStrategy)
    }
}

@Suite("Fetch Strategy Debouncing Tests")
struct FetchStrategyDebouncingTests {
    private let siteID: Int64 = 123
    private let mockAnalytics = MockPOSItemFetchAnalyticsTracking()

    // MARK: - Local Search Strategy Tests

    @Test("Local search strategy returns simple debouncing with loading delay threshold")
    func test_local_search_strategy_returns_simple_debouncing_with_threshold() async throws {
        let grdbManager = try GRDBManager()

        // Initialize site
        try await grdbManager.databaseConnection.write { db in
            try PersistedSite(id: siteID).insert(db)
        }

        let strategy = PointOfSaleLocalSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: "test",
            grdbManager: grdbManager,
            variationsRemote: MockProductVariationsRemote(),
            analytics: mockAnalytics
        )

        let expected: SearchDebounceStrategy = .simple(duration: 150 * NSEC_PER_MSEC, loadingDelayThreshold: 300 * NSEC_PER_MSEC)
        #expect(strategy.debounceStrategy == expected)
    }

    // MARK: - Remote Search Strategy Tests

    @Test("Remote search strategy returns smart debouncing")
    func test_remote_search_strategy_returns_smart_debouncing() {
        let strategy = PointOfSaleSearchPurchasableItemFetchStrategy(
            siteID: siteID,
            searchTerm: "test",
            productsRemote: MockProductsRemote(),
            variationsRemote: MockProductVariationsRemote(),
            analytics: mockAnalytics
        )

        let expected: SearchDebounceStrategy = .smart(duration: 500 * NSEC_PER_MSEC)
        #expect(strategy.debounceStrategy == expected)
    }

    // MARK: - Default Strategy Tests

    @Test("Default purchasable item strategy returns immediate debouncing")
    func test_default_purchasable_item_strategy_returns_immediate_debouncing() {
        let strategy = PointOfSaleDefaultPurchasableItemFetchStrategy(
            siteID: siteID,
            productsRemote: MockProductsRemote(),
            variationsRemote: MockProductVariationsRemote(),
            analytics: mockAnalytics
        )

        #expect(strategy.debounceStrategy == .immediate)
    }

    // MARK: - Coupon Strategy Tests

    @Test("Search coupon strategy returns smart debouncing")
    func test_search_coupon_strategy_returns_smart_debouncing() {
        let strategy = PointOfSaleSearchCouponFetchStrategy(
            siteID: siteID,
            currencySettings: .init(),
            storage: MockStorageManager(),
            couponStoreMethods: MockCouponStoreMethods(),
            searchTerm: "test",
            analytics: mockAnalytics
        )

        let expected: SearchDebounceStrategy = .smart(duration: 500 * NSEC_PER_MSEC)
        #expect(strategy.debounceStrategy == expected)
    }

    @Test("Default coupon strategy returns immediate debouncing")
    func test_default_coupon_strategy_returns_immediate_debouncing() {
        let strategy = PointOfSaleDefaultCouponFetchStrategy(
            siteID: siteID,
            currencySettings: .init(),
            storage: MockStorageManager(),
            couponStoreMethods: MockCouponStoreMethods()
        )

        #expect(strategy.debounceStrategy == .immediate)
    }
}

// MARK: - Mock Types

private final class MockProductsRemote: ProductsRemoteProtocol {
    func loadSimpleProducts(for siteID: Int64, pageNumber: Int, pageSize: Int) async throws -> (products: [Networking.Product], hasNextPage: Bool) {
        ([], false)
    }

    func loadAllProducts(for siteID: Int64,
                         context: String?,
                         pageNumber: Int,
                         pageSize: Int,
                         stockStatus: Networking.ProductStockStatus?,
                         productStatus: Networking.ProductStatus?,
                         productType: Networking.ProductType?,
                         productCategory: Networking.ProductCategoryID?,
                         orderBy: Networking.ProductsRemote.OrderKey,
                         order: Networking.ProductsRemote.Order,
                         excludedProductIDs: [Int64],
                         includedProductIDs: [Int64]) async throws -> (products: [Networking.Product], hasNextPage: Bool) {
        ([], false)
    }

    func loadAllProducts(for siteID: Int64,
                         context: String?,
                         pageNumber: Int,
                         pageSize: Int,
                         stockStatus: Networking.ProductStockStatus?,
                         productStatus: Networking.ProductStatus?,
                         productType: Networking.ProductType?,
                         productCategory: Networking.ProductCategoryID?,
                         orderBy: Networking.ProductsRemote.OrderKey,
                         order: Networking.ProductsRemote.Order,
                         excludedProductIDs: [Int64]) async throws -> (products: [Networking.Product], hasNextPage: Bool) {
        ([], false)
    }

    func searchProducts(for siteID: Int64,
                        keyword: String,
                        pageNumber: Int,
                        pageSize: Int,
                        stockStatus: Networking.ProductStockStatus?,
                        productStatus: Networking.ProductStatus?,
                        productType: Networking.ProductType?,
                        excludedProductIDs: [Int64]) async throws -> (products: [Networking.Product], hasNextPage: Bool) {
        ([], false)
    }

    func searchProducts(for siteID: Int64,
                        keyword: String,
                        pageNumber: Int,
                        pageSize: Int,
                        excludeTypes: [String]) async throws -> (products: [Networking.Product], hasNextPage: Bool) {
        ([], false)
    }

    func searchSku(for siteID: Int64, sku: String, pageNumber: Int, pageSize: Int) async throws -> (products: [Networking.Product], hasNextPage: Bool) {
        ([], false)
    }

    func loadProduct(for siteID: Int64, productID: Int64) async throws -> Networking.Product {
        throw NSError(domain: "test", code: 0)
    }

    func updateProducts(_ products: [Networking.Product]) async throws -> [Networking.Product] {
        []
    }

    func deleteProduct(for siteID: Int64, productID: Int64, forceDelete: Bool) async throws -> Networking.Product {
        throw NSError(domain: "test", code: 0)
    }

    func retrieveProductShippingClass(for siteID: Int64, remoteID: Int64) async throws -> Networking.ProductShippingClass {
        throw NSError(domain: "test", code: 0)
    }

    func addProduct(product: Networking.Product) async throws -> Networking.Product {
        throw NSError(domain: "test", code: 0)
    }

    func searchProductsForPointOfSale(for siteID: Int64,
                                      keyword: String,
                                      pageNumber: Int,
                                      pageSize: Int,
                                      stockStatus: Networking.ProductStockStatus?) async throws
    -> Networking.PagedItems<Networking.POSProduct> {
        .init(items: [], hasMorePages: false, totalItems: nil)
    }

    func loadProductsForPointOfSale(for siteID: Int64,
                                    pageNumber: Int,
                                    pageSize: Int,
                                    stockStatus: Networking.ProductStockStatus?) async throws
    -> Networking.PagedItems<Networking.POSProduct> {
        .init(items: [], hasMorePages: false, totalItems: nil)
    }

    func loadPopularProductsForPointOfSale(for siteID: Int64) async throws -> [Networking.POSProduct] {
        []
    }
}

private final class MockProductVariationsRemote: ProductVariationsRemoteProtocol {
    func loadVariationsForPointOfSale(for siteID: Int64,
                                      parentProductID: Int64,
                                      pageNumber: Int) async throws
    -> Networking.PagedItems<Networking.POSProductVariation> {
        .init(items: [], hasMorePages: false, totalItems: nil)
    }

    func loadAllVariations(for siteID: Int64, productID: Int64, context: String?) async throws -> [Networking.ProductVariation] {
        []
    }

    func loadVariation(for siteID: Int64, productID: Int64, variationID: Int64) async throws -> Networking.ProductVariation {
        throw NSError(domain: "test", code: 0)
    }

    func updateVariation(_ variation: Networking.ProductVariation) async throws -> Networking.ProductVariation {
        throw NSError(domain: "test", code: 0)
    }

    func createVariation(_ variation: Networking.ProductVariation) async throws -> Networking.ProductVariation {
        throw NSError(domain: "test", code: 0)
    }

    func deleteVariation(siteID: Int64, productID: Int64, variationID: Int64) async throws -> Networking.ProductVariation {
        throw NSError(domain: "test", code: 0)
    }
}

private final class MockCouponStoreMethods: CouponStoreMethodsProtocol {
    func synchronizeCoupons(siteID: Int64, pageNumber: Int, pageSize: Int) async throws -> Bool {
        false
    }

    func searchCoupons(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int) async throws {
    }
}

private final class MockPOSItemFetchAnalyticsTracking: POSItemFetchAnalyticsTracking {
    var spyLocalSearchMilliseconds: Int?
    var spyLocalSearchTotalItems: Int?
    var spyRemoteSearchMilliseconds: Int?
    var spyRemoteSearchTotalItems: Int?

    func trackSearchLocalResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int) {
        spyLocalSearchMilliseconds = millisecondsSinceRequestSent
        spyLocalSearchTotalItems = totalItems
    }

    func trackSearchRemoteResultsFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int) {
        spyRemoteSearchMilliseconds = millisecondsSinceRequestSent
        spyRemoteSearchTotalItems = totalItems
    }

    func trackFetchComplete(millisecondsSinceRequestSent: Int, totalItems: Int) {
    }
}
