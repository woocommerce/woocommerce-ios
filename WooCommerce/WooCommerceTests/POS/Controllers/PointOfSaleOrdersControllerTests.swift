import Testing
import Foundation
@testable import WooCommerce
import enum Yosemite.PointOfSaleOrderServiceError
import struct NetworkingCore.Order
import Observation

final class PointOfSaleOrdersControllerTests {
    @Test func loadOrders_requests_first_page_after_loading_two_pages() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        try #require(sut.ordersViewState.containerState == .loading)
        orderProvider.shouldSimulateTwoPages = true
        await sut.loadOrders()

        await sut.loadNextOrders()
        try #require(orderProvider.spyLastRequestedPageNumber == 2)

        await sut.loadOrders()

        #expect(orderProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func loadOrders_results_in_loaded_state() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        let expectedOrders = MockPointOfSaleOrderService.makeInitialOrders()
        orderProvider.orderPages = [expectedOrders]
        try #require(sut.ordersViewState.containerState == .loading)

        await sut.loadOrders()

        #expect(sut.ordersViewState == OrdersViewState(containerState: .content,
                                                      ordersState: .loaded(expectedOrders, hasMoreItems: false)))
    }

    @Test func loadOrders_with_more_pages_sets_hasMoreItems() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        let expectedOrders = MockPointOfSaleOrderService.makeInitialOrders()
        try #require(sut.ordersViewState.containerState == .loading)
        orderProvider.shouldSimulateTwoPages = true

        await sut.loadOrders()

        #expect(sut.ordersViewState == OrdersViewState(containerState: .content,
                                                      ordersState: .loaded(expectedOrders, hasMoreItems: true)))
    }

    @Test func loadOrders_when_called_multiple_times_then_orders_are_not_duplicated() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        try #require(sut.ordersViewState.containerState == .loading)
        let expectedOrders = MockPointOfSaleOrderService.makeInitialOrders()
        orderProvider.orderPages = [expectedOrders]

        await sut.loadOrders()
        await sut.loadOrders()
        await sut.loadOrders()

        guard case .loaded(let orders, _) = sut.ordersViewState.ordersState else {
            Issue.record("Expected loaded OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders.count == expectedOrders.count)
    }

    @Test func container_state_starts_as_loading() {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        #expect(sut.ordersViewState.containerState == .loading)
    }

    @Test func loadNextOrders_when_initial_orders_empty_then_container_state_is_content_and_orders_state_is_empty() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        orderProvider.shouldReturnZeroOrders = true

        try #require(sut.ordersViewState.containerState == .loading)

        await sut.loadNextOrders()

        #expect(sut.ordersViewState.containerState == .content)
        #expect(sut.ordersViewState.ordersState == .empty)
    }

    @Test func loadOrders_when_initial_orders_has_orders_but_no_more_pages_then_state_is_loaded_with_initial_orders() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        let initialOrders = MockPointOfSaleOrderService.makeInitialOrders()
        orderProvider.orderPages = [initialOrders]

        try #require(sut.ordersViewState.containerState == .loading)

        await sut.loadNextOrders()

        #expect(sut.ordersViewState == OrdersViewState(containerState: .content,
                                                      ordersState: .loaded(initialOrders, hasMoreItems: false)))
    }

    @Test func loadNextOrders_when_simulateFetchNextPage_then_state_is_loaded_with_expected_orders() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        orderProvider.shouldSimulateTwoPages = true
        await sut.loadOrders()

        await sut.loadNextOrders()

        guard case .loaded(let orders, _) = sut.ordersViewState.ordersState else {
            Issue.record("Expected loaded OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders.count == 4)
    }

    @Test func loadNextOrders_requests_second_page() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        try #require(sut.ordersViewState.containerState == .loading)
        orderProvider.shouldSimulateTwoPages = true
        await sut.loadOrders()

        await sut.loadNextOrders()

        #expect(orderProvider.spyLastRequestedPageNumber == 2)
    }

    @Test func loadNextOrders_when_simulateFetchNextPage_then_state_is_loaded_with_hasMoreItems() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        orderProvider.shouldSimulateTwoPages = true
        orderProvider.shouldSimulateThreePages = true
        await sut.loadOrders()

        await sut.loadNextOrders()

        guard case .loaded(let orders, let hasMoreItems) = sut.ordersViewState.ordersState else {
            Issue.record("Expected loaded OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders.count == 4)
        #expect(hasMoreItems == true)
    }

    @Test func loadNextOrders_when_hasNextPage_is_false_then_does_not_fetch_next_page() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        let expectedOrders = MockPointOfSaleOrderService.makeInitialOrders()
        orderProvider.orderPages = [expectedOrders]
        await sut.loadOrders()

        let spyCallCountBeforeLoadNext = orderProvider.spyCallCount
        await sut.loadNextOrders()

        #expect(orderProvider.spyCallCount == spyCallCountBeforeLoadNext)
    }

    @Test func refreshOrders_requests_first_page() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        orderProvider.shouldSimulateTwoPages = true
        await sut.loadOrders()
        await sut.loadNextOrders()

        try #require(orderProvider.spyLastRequestedPageNumber == 2)

        await sut.refreshOrders()

        #expect(orderProvider.spyLastRequestedPageNumber == 1)
    }

    @Test func loadOrders_when_error_occurs_then_shows_error_state() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        orderProvider.shouldThrowError = true

        await sut.loadOrders()

        guard case .error = sut.ordersViewState.ordersState else {
            Issue.record("Expected error OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(sut.ordersViewState.containerState == .content)
    }

    @Test func loadOrders_when_error_occurs_with_existing_orders_then_shows_inline_error() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        let initialOrders = MockPointOfSaleOrderService.makeInitialOrders()
        orderProvider.orderPages = [initialOrders]
        await sut.loadOrders()

        orderProvider.shouldThrowError = true
        await sut.refreshOrders()

        guard case .inlineError(let orders, _, let context) = sut.ordersViewState.ordersState else {
            Issue.record("Expected inlineError OrderList state, but got \(sut.ordersViewState)")
            return
        }
        #expect(orders == initialOrders)
        #expect(context == .refresh)
    }

    @Test func loadOrders_when_cached_data_available_then_shows_cached_data_with_loading_state() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        let initialOrders = MockPointOfSaleOrderService.makeInitialOrders()
        orderProvider.orderPages = [initialOrders]

        // First load - should cache the data
        await sut.loadOrders()

        guard case .loaded(let firstLoadOrders, _) = sut.ordersViewState.ordersState else {
            Issue.record("Expected loaded state after first load, but got \(sut.ordersViewState.ordersState)")
            return
        }
        #expect(firstLoadOrders == initialOrders)

        // Second load - should show cached data immediately with loading state
        await sut.loadOrders()

        // Should show cached data in loading state, then switch to loaded
        guard case .loaded(let cachedOrders, _) = sut.ordersViewState.ordersState else {
            Issue.record("Expected loaded state with cached data, but got \(sut.ordersViewState.ordersState)")
            return
        }
        #expect(cachedOrders == initialOrders)
    }

    @Test func loadOrders_when_no_cached_data_then_starts_with_empty_loading_state() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        let initialOrders = MockPointOfSaleOrderService.makeInitialOrders()
        orderProvider.orderPages = [initialOrders]

        // Initial state should be loading with empty orders
        try #require(sut.ordersViewState.containerState == .loading)
        guard case .loading(let orders) = sut.ordersViewState.ordersState else {
            Issue.record("Expected loading state with empty orders, but got \(sut.ordersViewState.ordersState)")
            return
        }
        #expect(orders.isEmpty)

        await sut.loadOrders()

        // Should end up in loaded state
        guard case .loaded(let loadedOrders, _) = sut.ordersViewState.ordersState else {
            Issue.record("Expected loaded state, but got \(sut.ordersViewState.ordersState)")
            return
        }
        #expect(loadedOrders == initialOrders)
    }

    @Test func loadOrders_cached_data_is_replaced_with_fresh_data() async throws {
        let orderProvider = MockPointOfSaleOrderService()
        let sut = PointOfSaleOrdersController(orderProvider: orderProvider)

        let initialOrders = MockPointOfSaleOrderService.makeInitialOrders()
        let freshOrders = MockPointOfSaleOrderService.makeSecondPageOrders()

        // First load
        orderProvider.orderPages = [initialOrders]
        await sut.loadOrders()

        guard case .loaded(let firstLoadOrders, _) = sut.ordersViewState.ordersState else {
            Issue.record("Expected loaded state after first load, but got \(sut.ordersViewState.ordersState)")
            return
        }
        #expect(firstLoadOrders == initialOrders)

        // Second load with different data
        orderProvider.orderPages = [freshOrders]
        await sut.loadOrders()

        // Should end up showing fresh data, not cached data
        guard case .loaded(let finalOrders, _) = sut.ordersViewState.ordersState else {
            Issue.record("Expected loaded state with fresh data, but got \(sut.ordersViewState.ordersState)")
            return
        }
        #expect(finalOrders == freshOrders)
    }
}
