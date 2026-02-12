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
    private let mockProductsRemote = MockProductsRemote()
    private let mockVariationsRemote = MockProductVariationsRemote()
    private let mockCouponStoreMethods = MockCouponStoreMethods()
    private let mockItemMapper = MockPointOfSaleItemMapper()

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
            variationsRemote: mockVariationsRemote,
            itemMapper: mockItemMapper,
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
            productsRemote: mockProductsRemote,
            variationsRemote: mockVariationsRemote,
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
            productsRemote: mockProductsRemote,
            variationsRemote: mockVariationsRemote,
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
