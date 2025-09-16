import Testing
import Foundation
@testable import WooCommerce
import enum Yosemite.POSOrderListServiceError
import struct NetworkingCore.Order
import Observation
import struct Yosemite.POSOrder

final class POSOrderListControllerTests {
    private let orderListService = MockPOSOrderListService()
    private lazy var fetchStrategyFactory = MockPOSOrderListFetchStrategyFactory(orderService: orderListService)
    private lazy var sut = POSOrderListController(orderListFetchStrategyFactory: fetchStrategyFactory)

    @Test func loadOrders_requests_first_page_after_loading_two_pages() async throws {
        try #require(sut.ordersViewState.isLoading)
        orderListService.shouldSimulateTwoPages = true
        await sut.loadOrders()

        await sut.loadNextOrders()
        try #require(orderListService.spyLastRequestedPageNumber == 2)

        await sut.loadOrders()

        #expect(orderListService.spyLastRequestedPageNumber == 1)
    }

    @Test func loadOrders_results_in_loaded_state() async throws {
        let expectedOrders = MockPOSOrderListService.makeInitialOrders()
        orderListService.orderPages = [expectedOrders]
        try #require(sut.ordersViewState.isLoading)

        await sut.loadOrders()

        #expect(sut.ordersViewState == .loaded(expectedOrders, hasMoreItems: false))
    }

    @Test func loadOrders_with_more_pages_sets_hasMoreItems() async throws {
        let expectedOrders = MockPOSOrderListService.makeInitialOrders()
        try #require(sut.ordersViewState.isLoading)
        orderListService.shouldSimulateTwoPages = true

        await sut.loadOrders()

        #expect(sut.ordersViewState == .loaded(expectedOrders, hasMoreItems: true))
    }

    @Test func loadOrders_when_called_multiple_times_then_orders_are_not_duplicated() async throws {
        try #require(sut.ordersViewState.isLoading)
        let expectedOrders = MockPOSOrderListService.makeInitialOrders()
        orderListService.orderPages = [expectedOrders]

        await sut.loadOrders()
        await sut.loadOrders()
        await sut.loadOrders()

        guard case .loaded(let orders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders.count == expectedOrders.count)
    }

    @Test func container_state_starts_as_loading() {
        #expect(sut.ordersViewState.isLoading)
    }

    @Test func loadNextOrders_when_initial_orders_empty_then_container_state_is_content_and_orders_state_is_empty() async throws {
        orderListService.shouldReturnZeroOrders = true

        try #require(sut.ordersViewState.isLoading)

        await sut.loadNextOrders()

        #expect(!sut.ordersViewState.isLoading)
        #expect(sut.ordersViewState == .empty)
    }

    @Test func loadOrders_when_initial_orders_has_orders_but_no_more_pages_then_state_is_loaded_with_initial_orders() async throws {
        let initialOrders = MockPOSOrderListService.makeInitialOrders()
        orderListService.orderPages = [initialOrders]

        try #require(sut.ordersViewState.isLoading)

        await sut.loadNextOrders()

        #expect(sut.ordersViewState == .loaded(initialOrders, hasMoreItems: false))
    }

    @Test func loadNextOrders_when_simulateFetchNextPage_then_state_is_loaded_with_expected_orders() async throws {
        orderListService.shouldSimulateTwoPages = true
        await sut.loadOrders()

        await sut.loadNextOrders()

        guard case .loaded(let orders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders.count == 4)
    }

    @Test func loadNextOrders_requests_second_page() async throws {
        try #require(sut.ordersViewState.isLoading)
        orderListService.shouldSimulateTwoPages = true
        await sut.loadOrders()

        await sut.loadNextOrders()

        #expect(orderListService.spyLastRequestedPageNumber == 2)
    }

    @Test func loadNextOrders_when_simulateFetchNextPage_then_state_is_loaded_with_hasMoreItems() async throws {
        orderListService.shouldSimulateTwoPages = true
        orderListService.shouldSimulateThreePages = true
        await sut.loadOrders()

        await sut.loadNextOrders()

        guard case .loaded(let orders, let hasMoreItems) = sut.ordersViewState else {
            Issue.record("Expected loaded OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders.count == 4)
        #expect(hasMoreItems == true)
    }

    @Test func loadNextOrders_when_hasNextPage_is_false_then_does_not_fetch_next_page() async throws {
        let expectedOrders = MockPOSOrderListService.makeInitialOrders()
        orderListService.orderPages = [expectedOrders]
        await sut.loadOrders()

        let spyCallCountBeforeLoadNext = orderListService.spyCallCount
        await sut.loadNextOrders()

        #expect(orderListService.spyCallCount == spyCallCountBeforeLoadNext)
    }

    @Test func refreshOrders_requests_first_page() async throws {
        orderListService.shouldSimulateTwoPages = true
        await sut.loadOrders()
        await sut.loadNextOrders()

        try #require(orderListService.spyLastRequestedPageNumber == 2)

        await sut.refreshOrders()

        #expect(orderListService.spyLastRequestedPageNumber == 1)
    }

    @Test func loadOrders_when_error_occurs_then_shows_error_state() async throws {
        orderListService.shouldThrowError = true

        await sut.loadOrders()

        guard case .error = sut.ordersViewState else {
            Issue.record("Expected error OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(!sut.ordersViewState.isLoading)
    }

    @Test func loadOrders_when_error_occurs_with_existing_orders_then_shows_inline_error() async throws {
        let initialOrders = MockPOSOrderListService.makeInitialOrders()
        orderListService.orderPages = [initialOrders]
        await sut.loadOrders()

        orderListService.shouldThrowError = true
        await sut.refreshOrders()

        guard case .inlineError(let orders, _, let context) = sut.ordersViewState else {
            Issue.record("Expected inlineError OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders == initialOrders)
        #expect(context == .refresh)
    }

    @Test func loadOrders_when_cached_data_available_then_shows_cached_data_with_loading_state() async throws {
        let initialOrders = MockPOSOrderListService.makeInitialOrders()
        orderListService.orderPages = [initialOrders]

        // First load - should cache the data
        await sut.loadOrders()

        guard case .loaded(let firstLoadOrders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state after first load, but got \(sut.ordersViewState)")
            return
        }
        #expect(firstLoadOrders == initialOrders)

        // Second load - should show cached data immediately with loading state
        await sut.loadOrders()

        // Should show cached data in loading state, then switch to loaded
        guard case .loaded(let cachedOrders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state with cached data, but got \(sut.ordersViewState)")
            return
        }
        #expect(cachedOrders == initialOrders)
    }

    @Test func loadOrders_when_no_cached_data_then_starts_with_empty_loading_state() async throws {
        let initialOrders = MockPOSOrderListService.makeInitialOrders()
        orderListService.orderPages = [initialOrders]

        // Initial state should be loading with empty orders
        try #require(sut.ordersViewState.isLoading)
        guard case .loading(let orders) = sut.ordersViewState else {
            Issue.record("Expected loading state with empty orders, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders.isEmpty)

        await sut.loadOrders()

        // Should end up in loaded state
        guard case .loaded(let loadedOrders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state, but got \(sut.ordersViewState)")
            return
        }
        #expect(loadedOrders == initialOrders)
    }

    @Test func loadOrders_cached_data_is_replaced_with_fresh_data() async throws {
        let initialOrders = MockPOSOrderListService.makeInitialOrders()
        let freshOrders = MockPOSOrderListService.makeSecondPageOrders()

        // First load
        orderListService.orderPages = [initialOrders]
        await sut.loadOrders()

        guard case .loaded(let firstLoadOrders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state after first load, but got \(sut.ordersViewState)")
            return
        }
        #expect(firstLoadOrders == initialOrders)

        // Second load with different data
        orderListService.orderPages = [freshOrders]
        await sut.loadOrders()

        // Should end up showing fresh data, not cached data
        guard case .loaded(let finalOrders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state with fresh data, but got \(sut.ordersViewState)")
            return
        }
        #expect(finalOrders == freshOrders)
    }

    @Test func clearSearchOrders_immediately_shows_cached_orders() async throws {
        // Given
        let initialOrders = MockPOSOrderListService.makeInitialOrders()
        let searchOrders = MockPOSOrderListService.makeSearchOrders()
        orderListService.orderPages = [initialOrders]
        orderListService.searchOrderPages = [searchOrders]

        await sut.loadOrders()

        guard case .loaded(let cachedOrders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state after first load, but got \(sut.ordersViewState)")
            return
        }
        #expect(cachedOrders == initialOrders)

        await sut.searchOrders(searchTerm: "test")

        // Verify search changed the state to different orders
        guard case .loaded(let searchResults, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state after search, but got \(sut.ordersViewState)")
            return
        }
        #expect(searchResults == searchOrders)
        #expect(searchResults != initialOrders, "Search should show different orders than initial cached orders")

        // When
        await sut.clearSearchOrders()

        // Then
        guard case .loaded(let restoredOrders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state with cached orders after clearing search, but got \(sut.ordersViewState)")
            return
        }
        #expect(restoredOrders == initialOrders, "Should restore original cached orders")
        #expect(restoredOrders != searchResults, "Restored orders should be different from search results")
    }

    @Test func clearSearchOrders_when_no_cache_then_shows_loading_state() async throws {
        // Given
        try #require(sut.ordersViewState.isLoading)
        await sut.searchOrders(searchTerm: "test")

        // When
        await sut.clearSearchOrders()

        // Then
        guard case .loading(let orders) = sut.ordersViewState else {
            Issue.record("Expected loading state when no cache exists, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders.isEmpty, "Should show empty loading state when no cache exists")
    }

    @Test func searchOrders_uses_search_strategy() async throws {
        // Given
        let searchOrders = MockPOSOrderListService.makeSearchOrders()
        orderListService.searchOrderPages = [searchOrders]

        // When
        await sut.searchOrders(searchTerm: "test")

        // Then
        guard case .loaded(let orders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state after search, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders == searchOrders)
        #expect(orderListService.lastSearchTerm == "test")
    }

    @Test func updateOrder_when_order_loaded_from_API_then_order_list_updates() async throws {
        // Given - load initial orders
        let initialOrders = MockPOSOrderListService.makeInitialOrders()
        orderListService.orderPages = [initialOrders]
        await sut.loadOrders()

        // Setup updated order
        let orderToUpdate = initialOrders[0]
        let updatedOrder = orderToUpdate.copy(customerEmail: .some("updated@example.com"))
        orderListService.loadOrderResult = updatedOrder

        // When
        try await sut.updateOrder(orderID: orderToUpdate.id)

        // Then
        guard case .loaded(let orders, _) = sut.ordersViewState else {
            Issue.record("Expected loaded state after update, but got \(sut.ordersViewState)")
            return
        }

        let foundOrder = orders.first { $0.id == orderToUpdate.id }
        #expect(foundOrder != nil)
        #expect(foundOrder?.customerEmail == "updated@example.com")
        #expect(orderListService.loadOrderWasCalled)
        #expect(orderListService.lastLoadOrderID == orderToUpdate.id)
    }

    @Test func updateOrder_when_order_loaded_from_API_then_selected_order_updates() async throws {
        // Given
        let initialOrders = MockPOSOrderListService.makeInitialOrders()
        orderListService.orderPages = [initialOrders]
        await sut.loadOrders()

        let orderToUpdate = initialOrders[0]
        await sut.selectOrder(orderToUpdate)
        #expect(sut.selectedOrder?.id == orderToUpdate.id)

        // Setup updated order
        let updatedOrder = orderToUpdate.copy(customerEmail: .some("selected-updated@example.com"))
        orderListService.loadOrderResult = updatedOrder

        // When
        try await sut.updateOrder(orderID: orderToUpdate.id)

        // Then
        #expect(sut.selectedOrder?.customerEmail == "selected-updated@example.com")
    }
}
