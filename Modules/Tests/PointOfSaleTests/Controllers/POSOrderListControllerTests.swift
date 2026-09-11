import Testing
import TestKit
import Foundation
@testable import PointOfSale
import enum Yosemite.POSOrderListServiceError
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderCustomAmount
import enum Yosemite.OrderStatusEnum
@testable import struct Yosemite.POSRefundItem
import struct Yosemite.POSOrderRefund

@Suite(.timeLimit(.minutes(5)))
final class POSOrderListControllerTests {
    private let orderListService = MockPOSOrderListService()
    private let refundsService = MockPOSRefundsService()
    private lazy var fetchStrategyFactory = MockPOSOrderListFetchStrategyFactory(orderService: orderListService)
    private lazy var sut = POSOrderListController(orderListFetchStrategyFactory: fetchStrategyFactory,
                                                   refundsService: refundsService)

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


    @MainActor
    @Test func test_loadOrderRefunds_when_order_has_refunds_then_enriches_refunds_with_items() async throws {
        // Given
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$15.00", items: [
                POSRefundItem(refundedItemID: 1,
                              quantity: 1,
                              name: "Item A",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: "some image source"),
                POSRefundItem(refundedItemID: 2,
                              quantity: 1,
                              name: "Item B",
                              formattedPrice: "$5.00",
                              formattedTotal: "-$5.00",
                              imageSrc: "some image source")
            ])
        ]

        // When
        await sut.loadOrderRefunds()

        // Then
        let refundedItems = sut.selectedOrder?.refunds.flatMap { $0.items }
        #expect(refundedItems?.count == 2)
    }

    @MainActor
    @Test func test_orderDetailsItemsState_when_refunded_order_selected_then_starts_loading_before_request() async throws {
        // Given
        let items = [makePOSOrderItem(itemID: 1), makePOSOrderItem(itemID: 2)]
        let order = makeOrder(lineItems: items, refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])

        // When
        sut.selectOrder(order)

        // Then
        guard case .loading(let rowCount) = sut.orderDetailsItemsState else {
            Issue.record("Expected loading item state, but got \(sut.orderDetailsItemsState)")
            return
        }
        #expect(rowCount == 2)
        #expect(sut.isLoadingOrderRefunds)
    }

    @MainActor
    @Test func test_orderDetailsItemsState_when_refund_response_has_no_items_then_finishes_loading() async throws {
        // Given
        let items = [makePOSOrderItem(itemID: 1), makePOSOrderItem(itemID: 2)]
        let order = makeOrder(lineItems: items, refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [])
        ]

        // When
        await sut.loadOrderRefunds()

        // Then
        guard case .loaded(let lineItems, let customAmounts, let refundedItems) = sut.orderDetailsItemsState else {
            Issue.record("Expected loaded item state, but got \(sut.orderDetailsItemsState)")
            return
        }
        #expect(lineItems.count == 2)
        #expect(customAmounts.isEmpty)
        #expect(refundedItems.isEmpty)
        #expect(!sut.isLoadingOrderRefunds)
    }

    @MainActor
    @Test func test_orderDetailsItemsState_when_reselecting_loaded_refunded_order_then_uses_cached_refunds() async throws {
        // Given
        let order = makeOrder(
            lineItems: [makePOSOrderItem(itemID: 1), makePOSOrderItem(itemID: 2)],
            refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")]
        )
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [
                POSRefundItem(refundedItemID: 1,
                              quantity: -1,
                              name: "Item A",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: nil)
            ])
        ]
        await sut.loadOrderRefunds()

        // When
        sut.selectOrder(order)

        // Then
        guard case .loaded(_, _, let refundedItems) = sut.orderDetailsItemsState else {
            Issue.record("Expected loaded item state, but got \(sut.orderDetailsItemsState)")
            return
        }
        #expect(refundedItems.count == 1)
        #expect(!sut.isLoadingOrderRefunds)
    }

    @MainActor
    @Test func test_orderDetailsItemsState_when_refund_details_loaded_then_filters_refunded_line_items() async throws {
        // Given
        let order = makeOrder(
            lineItems: [makePOSOrderItem(itemID: 1), makePOSOrderItem(itemID: 2)],
            refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")]
        )
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [
                POSRefundItem(refundedItemID: 1,
                              quantity: -1,
                              name: "Item A",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: nil)
            ])
        ]

        // When
        await sut.loadOrderRefunds()

        // Then
        guard case .loaded(let lineItems, _, let refundedItems) = sut.orderDetailsItemsState else {
            Issue.record("Expected loaded item state, but got \(sut.orderDetailsItemsState)")
            return
        }
        #expect(lineItems.map(\.itemID) == [2])
        #expect(refundedItems.compactMap(\.refundedItemID) == [1])
    }

    @MainActor
    @Test func test_loadOrderRefunds_when_no_selected_order_then_selectedOrder_is_nil() async throws {
        // Given — no order selected

        // When
        await sut.loadOrderRefunds()

        // Then
        #expect(sut.selectedOrder == nil)
    }

    @MainActor
    @Test func test_loadOrderRefunds_when_order_has_no_refunds_then_refunds_unchanged() async throws {
        // Given
        let order = makeOrder(refunds: [])
        sut.selectOrder(order)

        // When
        await sut.loadOrderRefunds()

        // Then
        #expect(sut.selectedOrder?.refunds.flatMap { $0.items }.isEmpty == true)
    }

    @MainActor
    @Test func test_loadOrderRefunds_when_service_throws_then_refunds_unchanged() async throws {
        // Given
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)
        refundsService.loadOrderRefundsErrorToThrow = NSError(domain: "test", code: 1)

        // When
        await sut.loadOrderRefunds()

        // Then
        #expect(sut.selectedOrder?.refunds.first?.items.isEmpty == true)
    }

    @MainActor
    @Test func test_selectOrder_when_reselecting_after_failed_refund_load_then_retries_loading() async throws {
        // Given — a refund details fetch that failed
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)
        refundsService.loadOrderRefundsErrorToThrow = NSError(domain: "test", code: 1)
        await sut.loadOrderRefunds()
        try #require(!sut.isLoadingOrderRefunds)

        // When — the order is selected again after the failure
        refundsService.loadOrderRefundsErrorToThrow = nil
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [
                POSRefundItem(refundedItemID: 1,
                              quantity: -1,
                              name: "Item A",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: nil)
            ])
        ]
        sut.selectOrder(order)

        // Then — the failed state is cleared so the loading skeleton shows and a retry succeeds
        #expect(sut.isLoadingOrderRefunds)
        await sut.loadOrderRefunds()
        #expect(!sut.isLoadingOrderRefunds)
        #expect(sut.selectedOrder?.refunds.flatMap(\.items).count == 1)
    }

    @MainActor
    @Test func test_updateOrder_when_refund_details_cached_then_drops_cache_and_shows_loading() async throws {
        // Given — a selected refunded order with loaded refund details
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [
                POSRefundItem(refundedItemID: 1,
                              quantity: -1,
                              name: "Item A",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: nil)
            ])
        ]
        await sut.loadOrderRefunds()
        try #require(!sut.isLoadingOrderRefunds)

        // When — the order is refetched with an extra refund whose details are summary-only
        let refreshedOrder = order.copy(refunds: .some([
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00"),
            POSOrderRefund(refundID: 2, formattedTotal: "-$5.00")
        ]))
        orderListService.loadOrderResult = refreshedOrder
        try await sut.updateOrder(orderID: order.id)

        // Then — the cached details are dropped and the details section is loading again
        #expect(sut.isLoadingOrderRefunds)
        guard case .loading = sut.orderDetailsItemsState else {
            Issue.record("Expected loading item state, but got \(sut.orderDetailsItemsState)")
            return
        }
    }

    @MainActor
    @Test func test_selectOrder_when_payload_refunds_carry_items_then_caches_them_for_summary_reselection() async throws {
        // Given — an order whose payload refunds already include item details
        let orderWithItems = makeOrder(refunds: [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [
                POSRefundItem(refundedItemID: 1,
                              quantity: -1,
                              name: "Item A",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: nil)
            ])
        ])
        sut.selectOrder(orderWithItems)
        try #require(!sut.isLoadingOrderRefunds)

        // When — the same order is reselected from summary data, as a list refresh would provide
        let summaryOrder = orderWithItems.copy(refunds: .some([
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")
        ]))
        sut.selectOrder(summaryOrder)

        // Then — the cached details are reapplied without re-showing the loading skeleton
        #expect(!sut.isLoadingOrderRefunds)
        #expect(sut.selectedOrder?.refunds.flatMap(\.items).count == 1)
    }

    @MainActor
    @Test func test_selectOrder_then_new_order_has_no_refunded_items() async throws {
        // Given: Load some refunded products first
        let order = makeOrder(refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [
                POSRefundItem(refundedItemID: 1,
                              quantity: 1,
                              name: "Item A",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: "some image source")
            ])
        ]
        await sut.loadOrderRefunds()
        try #require(sut.selectedOrder?.refunds.flatMap { $0.items }.count == 1)

        // When
        sut.selectOrder(makeOrder(id: 2))

        // Then
        #expect(sut.selectedOrder?.refunds.flatMap { $0.items }.isEmpty == true)
    }

    @MainActor
    @Test func test_loadOrderRefunds_when_selected_order_changes_during_fetch_then_discards_stale_result() async throws {
        // Given
        let orderA = makeOrder(id: 1, refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        let orderB = makeOrder(id: 2, refunds: [POSOrderRefund(refundID: 2, formattedTotal: "-$5.00")])
        sut.selectOrder(orderA)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [
                POSRefundItem(refundedItemID: 1,
                              quantity: 1,
                              name: "Item A",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: nil)
            ])
        ]
        refundsService.onLoadOrderRefundsCalled = { [weak sut] _ in
            sut?.selectOrder(orderB)
        }

        // When
        await sut.loadOrderRefunds()

        // Then
        #expect(sut.selectedOrder?.id == 2)
        #expect(sut.selectedOrder?.refunds.flatMap { $0.items }.isEmpty == true)
    }

    @MainActor
    @Test func test_displayedLineItems_when_loading_refunds_then_returns_all_items() async throws {
        // Given
        let items = [makePOSOrderItem(itemID: 1), makePOSOrderItem(itemID: 2)]
        let order = makeOrder(lineItems: items, refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)

        var displayedLineItemsCountWhileLoading: Int?
        refundsService.onLoadOrderRefundsCalled = { [weak sut] _ in
            displayedLineItemsCountWhileLoading = sut?.displayedLineItems.count
        }

        // When
        await sut.loadOrderRefunds()

        // Then
        #expect(displayedLineItemsCountWhileLoading == 2)
    }

    @MainActor
    @Test func test_displayedLineItems_when_refunds_loaded_then_filters_fully_refunded_items() async throws {
        // Given
        let items = [makePOSOrderItem(itemID: 1, quantity: 2), makePOSOrderItem(itemID: 2, quantity: 1)]
        let order = makeOrder(lineItems: items, refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [
                POSRefundItem(refundedItemID: 2,
                              quantity: -1,
                              name: "Item B",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: nil)
            ])
        ]

        // When
        await sut.loadOrderRefunds()

        // Then — item 2 is fully refunded, only item 1 remains
        #expect(sut.displayedLineItems.count == 1)
        #expect(sut.displayedLineItems.first?.itemID == 1)
    }

    @MainActor
    @Test func test_displayedLineItems_when_partially_refunded_then_includes_item() async throws {
        // Given
        let items = [makePOSOrderItem(itemID: 1, quantity: 3)]
        let order = makeOrder(lineItems: items, refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$10.00", items: [
                POSRefundItem(refundedItemID: 1,
                              quantity: -1,
                              name: "Item A",
                              formattedPrice: "$10.00",
                              formattedTotal: "-$10.00",
                              imageSrc: nil)
            ])
        ]

        // When
        await sut.loadOrderRefunds()

        // Then — item 1 is only partially refunded, still displayed
        #expect(sut.displayedLineItems.count == 1)
        #expect(sut.displayedLineItems.first?.itemID == 1)
    }

    @MainActor
    @Test func test_displayedCustomAmounts_when_fee_fully_refunded_then_filters_it_out() async throws {
        // Given
        let customAmount = makePOSOrderCustomAmount(id: 777, name: "Discount Fee")
        let order = makeOrder(
            lineItems: [],
            customAmounts: [customAmount],
            refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$5.00")]
        )
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$5.00", items: [
                POSRefundItem(refundedItemID: 777,
                              quantity: 1,
                              name: "Discount Fee",
                              formattedPrice: "$5.00",
                              formattedTotal: "-$5.00",
                              imageSrc: nil,
                              isLumpSum: true)
            ])
        ]

        // When
        await sut.loadOrderRefunds()

        // Then
        #expect(sut.displayedCustomAmounts.isEmpty)
    }

    @MainActor
    @Test func test_displayedCustomAmounts_when_other_fee_unrefunded_then_keeps_it() async throws {
        // Given - one fee refunded, another not
        let order = makeOrder(
            lineItems: [],
            customAmounts: [
                makePOSOrderCustomAmount(id: 777, name: "Discount Fee"),
                makePOSOrderCustomAmount(id: 888, name: "Tip")
            ],
            refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$5.00")]
        )
        sut.selectOrder(order)
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$5.00", items: [
                POSRefundItem(refundedItemID: 777,
                              quantity: 1,
                              name: "Discount Fee",
                              formattedPrice: "$5.00",
                              formattedTotal: "-$5.00",
                              imageSrc: nil,
                              isLumpSum: true)
            ])
        ]

        // When
        await sut.loadOrderRefunds()

        // Then
        #expect(sut.displayedCustomAmounts.count == 1)
        #expect(sut.displayedCustomAmounts.first?.id == 888)
    }

    @MainActor
    @Test func test_displayedCustomAmounts_when_fee_lines_absent_from_refund_response_then_fee_remains_visible() async throws {
        // Given - simulates an older WooCommerce store whose refund response omits `fee_lines`,
        // so the loaded refund has no entry pointing back to the original fee id. The fee
        // can't be filtered out and stays visible (documented limitation).
        let customAmount = makePOSOrderCustomAmount(id: 777, name: "Discount Fee")
        let order = makeOrder(
            lineItems: [],
            customAmounts: [customAmount],
            refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$5.00")]
        )
        sut.selectOrder(order)
        // No POSRefundItem with refundedItemID = 777 is returned, mirroring an empty fee_lines
        // server response.
        refundsService.loadOrderRefundsResultToReturn = [
            POSOrderRefund(refundID: 1, formattedTotal: "-$5.00", items: [])
        ]

        // When
        await sut.loadOrderRefunds()

        // Then
        #expect(sut.displayedCustomAmounts.count == 1)
        #expect(sut.displayedCustomAmounts.first?.id == 777)
    }

    @MainActor
    @Test func test_displayedCustomAmounts_when_order_has_no_refunds_then_returns_all_custom_amounts() async throws {
        // Given
        let customAmount = makePOSOrderCustomAmount(id: 777, name: "Discount Fee")
        let order = makeOrder(lineItems: [], customAmounts: [customAmount])

        // When
        sut.selectOrder(order)

        // Then
        #expect(sut.displayedCustomAmounts.count == 1)
    }

    @MainActor
    @Test func test_displayedLineItems_when_no_items_refunded_then_returns_all_items() async throws {
        // Given
        let items = [makePOSOrderItem(itemID: 1), makePOSOrderItem(itemID: 2)]
        let order = makeOrder(lineItems: items, refunds: [POSOrderRefund(refundID: 1, formattedTotal: "-$10.00")])
        sut.selectOrder(order)

        // When/Then — all items returned regardless of refunds
        #expect(sut.displayedLineItems.count == 2)
    }
}
