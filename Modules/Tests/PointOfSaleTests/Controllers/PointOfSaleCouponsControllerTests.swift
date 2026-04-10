@testable import PointOfSale
import Testing
import Foundation
import class WooFoundation.CurrencySettings
import Yosemite

struct PointOfSaleCouponsControllerTests {
    private let fetchStrategyFactory: MockPointOfSaleCouponFetchStrategyFactory

    init() {
        fetchStrategyFactory = MockPointOfSaleCouponFetchStrategyFactory()
    }

    @Test func loadItems_when_empty_coupons_then_results_in_empty_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .empty, itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadItems_when_some_coupons_then_results_in_coupons_loaded_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let expectedCoupons = MockPointOfSaleCouponService.makeInitialCoupons()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .loaded(expectedCoupons, hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func refreshItems_when_empty_coupons_then_results_in_empty_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider, fetchStrategyFactory: fetchStrategyFactory, analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .empty, itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.refreshItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func refreshItems_when_some_coupons_then_results_in_coupons_loaded_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let expectedCoupons = MockPointOfSaleCouponService.makeInitialCoupons()

        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .loaded(expectedCoupons, hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.refreshItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadNextItems_when_empty_coupons_then_results_in_empty_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .empty, itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadNextItems_when_some_coupons_then_results_in_coupons_loaded_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let expectedCoupons = MockPointOfSaleCouponService.makeInitialCoupons()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .loaded(expectedCoupons, hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadItems_when_retrieving_settings_fails_then_results_in_error_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let error = NSError(domain: "test", code: 0)
        couponProvider.errorToThrow = .couponsLoadingError(underlyingError: error)
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .error(.errorOnLoadingCoupons()), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func enableCoupons_sets_error_state_when_fails() async throws {
        // Given
        struct MockError: Error {}
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.errorToThrow = .couponsEnablingError(underlyingError: MockError())
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        // When
        await sut.enableCoupons()

        // Then
        guard case .error = sut.itemsViewState.itemsStack.root else {
            Issue.record("Expected error state")
            return
        }
    }

    @Test func enableCoupons_loads_items_when_successful() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())
        let expectedCoupons = MockPointOfSaleCouponService.makeInitialCoupons()
        let expectedItemStackState = ItemsStackState(root: .loaded(expectedCoupons, hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        _ = await sut.enableCoupons()

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadItems_when_fails_then_sets_inlineError_state_and_preserves_items() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())
        await sut.loadItems(base: .root)
        let currentItems = sut.itemsViewState.itemsStack.root.items
        let error = NSError(domain: "test", code: 0)
        couponProvider.errorToThrow = .couponsLoadingError(underlyingError: error)

        // When
        await sut.loadItems(base: .root)

        // Then
        let expectedItemStackState = ItemsStackState(root: .inlineError(currentItems, error: .errorOnRefreshingCoupons(), context: .refresh), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadNextItems_when_loadNextItems_fails_then_sets_inlineError_state_and_preserves_items() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())
        couponProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)
        let currentItems = sut.itemsViewState.itemsStack.root.items
        let error = NSError(domain: "test", code: 0)
        couponProvider.errorToThrow = .couponsLoadingError(underlyingError: error)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        let expectedItemStackState = ItemsStackState(root: .inlineError(currentItems,
                                                                        error: .errorOnLoadingCouponsNextPage(),
                                                                        context: .pagination),
                                                     itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadNextItems_when_loadNextItems_then_loads_second_page() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())
        couponProvider.shouldSimulateTwoPages = true
        await sut.loadItems(base: .root)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        let expectedItems = MockPointOfSaleCouponService.makeSecondPageCoupons()
        let expectedItemStackState = ItemsStackState(root: .loaded(expectedItems, hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadNextItems_when_loadNextItems_with_more_items_then_sets_hasMoreItems() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())
        couponProvider.shouldSimulateTwoPages = true
        couponProvider.shouldSimulateMorePages = true
        await sut.loadItems(base: .root)

        // When
        await sut.loadNextItems(base: .root)

        // Then
        let expectedItems = MockPointOfSaleCouponService.makeSecondPageCoupons()
        let expectedItemStackState = ItemsStackState(root: .loaded(expectedItems, hasMoreItems: true), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func searchItems_when_empty_coupons_then_results_in_empty_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .empty, itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.searchItems(searchTerm: "test", baseItem: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func searchItems_when_some_coupons_then_results_in_coupons_loaded_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let expectedCoupons = MockPointOfSaleCouponService.makeInitialCoupons()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .loaded(expectedCoupons, hasMoreItems: false), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.searchItems(searchTerm: "test", baseItem: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func searchItems_when_fails_then_sets_error_state() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let error = NSError(domain: "test", code: 0)
        couponProvider.errorToThrow = .couponsLoadingError(underlyingError: error)
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .error(.errorOnLoadingCoupons()), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.searchItems(searchTerm: "test", baseItem: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadItems_when_local_fetch_fails_with_loading_error_then_still_loads_remotely() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.localErrorToThrow = .couponsLoadingError(underlyingError: NSError(domain: "test", code: 0))
        couponProvider.shouldReturnZeroItems = true
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .empty, itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func loadItems_when_local_fetch_fails_with_couponsDisabled_then_shows_disabled_error() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        couponProvider.localErrorToThrow = .couponsDisabled
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())

        let expectedItemStackState = ItemsStackState(root: .error(.errorCouponsDisabled), itemStates: [:])
        let expectedViewState = ItemsViewState(containerState: .content, itemsStack: expectedItemStackState)

        // When
        await sut.loadItems(base: .root)

        // Then
        #expect(sut.itemsViewState == expectedViewState)
    }

    @Test func searchItems_when_requestCancelled_then_state_unchanged() async throws {
        // Given
        let couponProvider = MockPointOfSaleCouponService()
        let sut = PointOfSaleCouponsController(itemProvider: couponProvider,
                                               fetchStrategyFactory: fetchStrategyFactory,
                                               analyticsProvider: MockPOSAnalytics())
        await sut.loadItems(base: .root)
        let initialState = sut.itemsViewState
        couponProvider.errorToThrow = .requestCancelled

        // When
        await sut.searchItems(searchTerm: "test", baseItem: .root)

        // Then
        #expect(sut.itemsViewState == initialState)
    }
}

final class MockPointOfSaleCouponFetchStrategyFactory: PointOfSaleCouponFetchStrategyFactoryProtocol {
    let defaultStrategy: PointOfSaleCouponFetchStrategy = MockPointOfSaleCouponFetchStrategy()

    func searchStrategy(searchTerm: String, analytics: POSItemFetchAnalyticsTracking) -> PointOfSaleCouponFetchStrategy {
        PointOfSaleCouponFetchStrategyPreview()
    }
}

final class MockPointOfSaleCouponFetchStrategy: PointOfSaleCouponFetchStrategy {
    func fetchCoupons(pageNumber: Int) async throws -> PagedItems<POSItem> {
        .init(items: [], hasMorePages: false, totalItems: nil)
    }

    func fetchLocalCoupons() async throws -> [POSItem] {
        []
    }
}
