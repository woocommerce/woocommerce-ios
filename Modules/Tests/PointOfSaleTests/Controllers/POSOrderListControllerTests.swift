import Testing
import TestKit
import Foundation
@testable import PointOfSale
import enum Yosemite.POSOrderListServiceError
import struct NetworkingCore.Order
import Observation
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import typealias Yosemite.OrderItemAttribute
@testable import struct Yosemite.POSRefund
@testable import struct Yosemite.POSRefundItem
@testable import struct Yosemite.POSRefundsResult
@testable import struct Yosemite.POSRefundableItem
import class WooFoundation.CurrencySettings
import class WooFoundation.CurrencyFormatter

final class POSOrderListControllerTests {
    private let orderListService = MockPOSOrderListService()
    private let refundsService = MockPOSRefundsService()
    private lazy var fetchStrategyFactory = MockPOSOrderListFetchStrategyFactory(orderService: orderListService)
    private lazy var featureFlags = MockFeatureFlagService()
    private lazy var currencySettingsProvider = MockCurrencySettingsProvider()
    private lazy var currencyFormatter = CurrencyFormatter(currencySettings: currencySettingsProvider.currencySettings)
    private lazy var sut = POSOrderListController(orderListFetchStrategyFactory: fetchStrategyFactory,
                                                   refundsService: refundsService,
                                                   featureFlags: featureFlags,
                                                   currencySettingsProvider: currencySettingsProvider,
                                                   currencyFormatter: currencyFormatter)

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

    @Test func selectOrder_then_calls_refunds_service_for_selected_order() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        let order = MockPOSOrderListService.makeInitialOrders()[0]

        async let calledOrder = refundsService.awaitProvidePointOfSaleRefundsCall()

        // When
        await sut.selectOrder(order)

        // Then
        #expect(await calledOrder == order)
    }

    @Test func selectOrder_then_updates_refunds_state_with_loading() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        let order = MockPOSOrderListService.makeInitialOrders()[0]

        // When
        await sut.selectOrder(order)

        // Then
        let didBecomeLoading = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loading = sut.selectedOrderRefundsState { return true }
            return false
        }

        #expect(
            didBecomeLoading,
            "Expected selectedOrderRefundsState to become .loading before timeout"
        )
    }

    @Test func selectOrder_when_provides_refunds_then_updates_refunds_state_with_results() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        let order = MockPOSOrderListService.makeInitialOrders()[0]

        let expectedResult = POSRefundsResult(refunds: [POSRefund(items: [])], isFullyRefunded: false, supportsAutomaticRefund: true)
        refundsService.providePointOfSaleRefundsResultToReturn = expectedResult

        // When
        await sut.selectOrder(order)

        // Then
        let didLoad = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }

        #expect(
            didLoad,
            "Expected selectedOrderRefundsState to become .loaded before timeout"
        )

        guard case .loaded(let loadedResult) = sut.selectedOrderRefundsState else {
            #expect(Bool(false), "Expected .loaded state")
            return
        }

        #expect(loadedResult.isFullyRefunded == expectedResult.isFullyRefunded)
    }

    @Test func selectOrder_when_refunds_service_errors_then_failed_contains_same_error_type() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        let order = MockPOSOrderListService.makeInitialOrders()[0]

        struct TestError: Error {}
        refundsService.errorToThrow = TestError()

        // When
        await sut.selectOrder(order)

        // Then
        let didFail = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .failed = sut.selectedOrderRefundsState { return true }
            return false
        }

        #expect(
            didFail,
            "Expected selectedOrderRefundsState to become .failed before timeout"
        )

        guard case .failed(let error) = sut.selectedOrderRefundsState else {
            #expect(Bool(false), "Expected .failed state")
            return
        }

        #expect(error is TestError)
    }

    @Test func refundActionAvailability_when_feature_flag_disabled_then_unavailable() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = false
        let order = MockPOSOrderListService.makeInitialOrders()[0]

        // When
        await sut.selectOrder(order)

        // Then
        let availability = await MainActor.run { sut.refundActionAvailability }
        #expect(availability == .unavailable)
    }

    @Test func refundActionAvailability_when_no_selected_order_then_unavailable() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true

        // When / Then
        let availability = await MainActor.run { sut.refundActionAvailability }
        #expect(availability == .unavailable)
    }

    @Test func refundActionAvailability_when_refunds_loading_then_unknown() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        let order = MockPOSOrderListService.makeInitialOrders()[0]
        refundsService.shouldSuspendProvidePointOfSaleRefunds = true

        // When
        await MainActor.run {
            sut.selectOrder(order)
            #expect(sut.refundActionAvailability == .unknown)
        }

        // Then
        refundsService.resumeProvidePointOfSaleRefunds()
    }

    @Test func refundActionAvailability_when_refunds_failed_then_unavailable() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        let order = MockPOSOrderListService.makeInitialOrders()[0]

        struct TestError: Error {}
        refundsService.errorToThrow = TestError()

        // When
        await sut.selectOrder(order)

        // Then
        let didFail = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .failed = sut.selectedOrderRefundsState { return true }
            return false
        }
        #expect(didFail)

        let availability = await MainActor.run { sut.refundActionAvailability }
        #expect(availability == .unavailable)
    }

    @Test func refundActionAvailability_when_refunds_loaded_and_not_fully_refunded_then_available() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true

        let order = makeOrder(id: 1)

        // Service returns isFullyRefunded = false (not fully refunded)
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        // When
        await sut.selectOrder(order)

        // Then
        let didLoad = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        #expect(didLoad)

        let availability = await MainActor.run { sut.refundActionAvailability }
        #expect(availability == .available)
    }

    @Test func refundActionAvailability_when_refunds_loaded_and_fully_refunded_then_unavailable() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true

        let order = makeOrder(id: 1)

        // Service returns isFullyRefunded = true (fully refunded)
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: true,
            supportsAutomaticRefund: true
        )

        // When
        await sut.selectOrder(order)

        // Then
        let didLoad = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        #expect(didLoad)

        let availability = await MainActor.run { sut.refundActionAvailability }
        #expect(availability == .unavailable)
    }

    // MARK: - Refund Item Selection Tests

    @Test func startRefundFlow_when_product_has_multiple_quantities_then_creates_one_row_per_unit() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, name: "Item A", quantity: 3, formattedPrice: "$10.00", formattedTotal: "$30.00"),
            makePOSOrderItem(itemID: 2, name: "Item B", quantity: 1, formattedPrice: "$5.00")
        ])

        // When
        let itemCount = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.refundSelectableItems.count
        }

        // Then
        #expect(itemCount == 4)
    }

    @Test func startRefundFlow_then_all_items_are_selected_by_default() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        // When
        let items = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.refundSelectableItems
        }

        // Then
        #expect(items.count == 2)
        for item in items {
            #expect(item.isSelected)
        }
    }

    @Test func startRefundFlow_when_no_selected_order_then_items_remain_empty() async throws {
        // When
        let items = await MainActor.run {
            sut.startRefundFlow()
            return sut.refundSelectableItems
        }

        // Then
        #expect(items.isEmpty)
    }

    @Test func toggleRefundItemSelection_then_toggles_item_at_index() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
        }

        // When
        let isSelectedAfterToggle = await MainActor.run {
            sut.toggleRefundItemSelection(at: 0)
            return sut.refundSelectableItems[0].isSelected
        }

        // Then
        #expect(isSelectedAfterToggle == false)
    }

    @Test func toggleRefundItemSelection_when_index_out_of_bounds_then_does_not_crash() async throws {
        // When
        let items = await MainActor.run {
            sut.toggleRefundItemSelection(at: 999)
            return sut.refundSelectableItems
        }

        // Then
        #expect(items.isEmpty)
    }

    @Test func clearRefundSelection_then_removes_all_items() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        let initialCount = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.refundSelectableItems.count
        }
        try #require(initialCount == 2)

        // When
        let finalCount = await MainActor.run {
            sut.clearRefundSelection()
            return sut.refundSelectableItems.count
        }

        // Then
        #expect(finalCount == 0)
    }

    @Test func toggleAllRefundItemsSelection_when_all_selected_then_deselects_all() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
        }

        // When
        let items = await MainActor.run {
            sut.toggleAllRefundItemsSelection()
            return sut.refundSelectableItems
        }

        // Then
        for item in items {
            #expect(item.isSelected == false)
        }
    }

    @Test func toggleAllRefundItemsSelection_when_some_deselected_then_selects_all() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            sut.toggleRefundItemSelection(at: 0) // Deselect first item
        }

        // When
        let items = await MainActor.run {
            sut.toggleAllRefundItemsSelection()
            return sut.refundSelectableItems
        }

        // Then
        for item in items {
            #expect(item.isSelected == true)
        }
    }

    @Test func toggleAllRefundItemsSelection_when_none_selected_then_selects_all() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, formattedPrice: "$10.00", formattedTotal: "$20.00")
        ])

        await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            sut.toggleAllRefundItemsSelection() // Deselect all
        }

        // When
        let items = await MainActor.run {
            sut.toggleAllRefundItemsSelection() // Should select all
            return sut.refundSelectableItems
        }

        // Then
        for item in items {
            #expect(item.isSelected == true)
        }
    }

    // MARK: - Prepare Refund Review Data Tests

    @Test func preparePOSRefundReviewData_when_no_selected_order_then_returns_nil() async throws {
        // When
        let reviewData = await MainActor.run {
            sut.startRefundFlow()
            return sut.preparePOSRefundReviewData()
        }

        // Then
        #expect(reviewData == nil)
    }

    @Test func preparePOSRefundReviewData_when_no_items_selected_then_returns_nil() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        let reviewData = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            sut.toggleAllRefundItemsSelection() // Deselect all
            return sut.preparePOSRefundReviewData()
        }

        // Then
        #expect(reviewData == nil)
    }

    @Test func preparePOSRefundReviewData_then_returns_correct_items_count() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 3, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        let reviewData = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.preparePOSRefundReviewData()
        }

        // Then
        #expect(reviewData?.itemsCount == 3)
    }

    @Test func preparePOSRefundReviewData_then_returns_correct_subtotal() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00"),
            makePOSOrderItem(itemID: 2, quantity: 1, price: 5.50, formattedPrice: "$5.50")
        ])

        // When
        let reviewData = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.preparePOSRefundReviewData()
        }

        // Then
        // 2 × $10.00 + 1 × $5.50 = $25.50
        #expect(reviewData?.formattedItemsSubtotal == "$25.50")
    }

    @Test func preparePOSRefundReviewData_when_full_refund_then_uses_original_tax() async throws {
        // Given - item with quantity 2 and totalTax of $1.50 (for both units)
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, totalTax: 1.50, formattedPrice: "$10.00")
        ])

        // When - all items selected (full refund)
        let reviewData = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.preparePOSRefundReviewData()
        }

        // Then - should use original totalTax directly ($1.50)
        #expect(reviewData?.formattedTax == "$1.50")
    }

    @Test func preparePOSRefundReviewData_when_partial_refund_then_calculates_proportional_tax() async throws {
        // Given - item with quantity 2 and totalTax of $1.50 (for both units)
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, totalTax: 1.50, formattedPrice: "$10.00")
        ])

        // When - only 1 of 2 items selected (partial refund)
        let reviewData = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            sut.toggleRefundItemSelection(at: 0) // Deselect first item, leaving 1 selected
            return sut.preparePOSRefundReviewData()
        }

        // Then - should calculate proportionally: $1.50 / 2 × 1 = $0.75
        #expect(reviewData?.formattedTax == "$0.75")
    }

    @Test func preparePOSRefundReviewData_then_returns_correct_total() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, totalTax: 1.00, formattedPrice: "$10.00")
        ])

        // When
        let reviewData = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.preparePOSRefundReviewData()
        }

        // Then - $10.00 + $1.00 = $11.00
        #expect(reviewData?.formattedRefundTotal == "$11.00")
    }

    @Test func preparePOSRefundReviewData_then_returns_via_payment_method_title() async throws {
        // Given
        let order = makeOrder(paymentMethodTitle: "WooCommerce In-Person Payments", lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        let reviewData = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.preparePOSRefundReviewData()
        }

        // Then
        #expect(reviewData?.paymentMethodDescription == "Via WooCommerce In-Person Payments")
    }

    @Test func preparePOSRefundReviewData_then_refund_reason_is_nil_by_default() async throws {
        // Given
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        // When
        let reviewData = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.preparePOSRefundReviewData()
        }

        // Then
        #expect(reviewData?.refundReason == nil)
    }

    // MARK: - Currency Formatting Tests

    @Test func preparePOSRefundReviewData_with_EUR_currency_then_formats_with_comma_decimal_separator() async throws {
        // Given - EUR with comma decimal separator and dot thousand separator
        let eurSettings = CurrencySettings(
            currencyCode: .EUR,
            currencyPosition: .rightSpace,
            thousandSeparator: ".",
            decimalSeparator: ",",
            numberOfDecimals: 2
        )
        let controller = makeController(currencySettings: eurSettings)

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 1172.02, totalTax: 234.40, formattedPrice: "1.172,02 €")
        ])

        // When
        let reviewData = await MainActor.run {
            controller.selectOrder(order)
            controller.startRefundFlow()
            return controller.preparePOSRefundReviewData()
        }

        // Then - 2 × €1,172.02 = €2,344.04, tax = €234.40, total = €2,578.44
        // Note: CurrencyFormatter uses non-breaking space (\u{00A0}) before currency symbol
        #expect(reviewData?.formattedItemsSubtotal == "2.344,04\u{00A0}€")
        #expect(reviewData?.formattedTax == "234,40\u{00A0}€")
        #expect(reviewData?.formattedRefundTotal == "2.578,44\u{00A0}€")
    }

    @Test func preparePOSRefundReviewData_with_JPY_currency_then_formats_without_decimals() async throws {
        // Given - JPY with no decimals
        let jpySettings = CurrencySettings(
            currencyCode: .JPY,
            currencyPosition: .left,
            thousandSeparator: ",",
            decimalSeparator: ".",
            numberOfDecimals: 0
        )
        let controller = makeController(currencySettings: jpySettings)

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 2344, totalTax: 234, formattedPrice: "¥2,344")
        ])

        // When
        let reviewData = await MainActor.run {
            controller.selectOrder(order)
            controller.startRefundFlow()
            return controller.preparePOSRefundReviewData()
        }

        // Then
        #expect(reviewData?.formattedItemsSubtotal == "¥2,344")
        #expect(reviewData?.formattedTax == "¥234")
        #expect(reviewData?.formattedRefundTotal == "¥2,578")
    }

    @Test func preparePOSRefundReviewData_with_GBP_and_large_values_then_formats_correctly() async throws {
        // Given - GBP with large values
        let gbpSettings = CurrencySettings(
            currencyCode: .GBP,
            currencyPosition: .left,
            thousandSeparator: ",",
            decimalSeparator: ".",
            numberOfDecimals: 2
        )
        let controller = makeController(currencySettings: gbpSettings)

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 12345.67, totalTax: 2469.13, formattedPrice: "£12,345.67")
        ])

        // When
        let reviewData = await MainActor.run {
            controller.selectOrder(order)
            controller.startRefundFlow()
            return controller.preparePOSRefundReviewData()
        }

        // Then
        #expect(reviewData?.formattedItemsSubtotal == "£12,345.67")
        #expect(reviewData?.formattedTax == "£2,469.13")
        #expect(reviewData?.formattedRefundTotal == "£14,814.80")
    }

    @Test func preparePOSRefundReviewData_with_USD_and_large_value_from_screenshot_then_formats_correctly() async throws {
        // Given - USD with value from screenshot: $2,344.04
        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 2344.04, totalTax: 234.40, formattedPrice: "$2,344.04")
        ])

        // When
        let reviewData = await MainActor.run {
            sut.selectOrder(order)
            sut.startRefundFlow()
            return sut.preparePOSRefundReviewData()
        }

        // Then
        #expect(reviewData?.formattedItemsSubtotal == "$2,344.04")
        #expect(reviewData?.formattedTax == "$234.40")
        #expect(reviewData?.formattedRefundTotal == "$2,578.44")
    }

    // MARK: - Process Refund Tests

    @MainActor
    @Test func processRefund_then_calls_service_with_correct_order_id() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(id: 123, lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        sut.selectOrder(order)
        _ = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        sut.startRefundFlow()

        // When
        try await sut.processRefund(reason: .none)

        // Then
        #expect(refundsService.createRefundCalled == true)
        #expect(refundsService.spyCreateRefundOrderID == 123)
    }

    @MainActor
    @Test func processRefund_then_calls_service_with_selected_items() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00"),
            makePOSOrderItem(itemID: 2, quantity: 1, price: 5.00, formattedPrice: "$5.00")
        ])

        sut.selectOrder(order)
        _ = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        sut.startRefundFlow()
        sut.toggleRefundItemSelection(at: 0) // Deselect first item of itemID 1

        // When
        try await sut.processRefund(reason: .none)

        // Then
        let items = try #require(refundsService.spyCreateRefundItems)
        #expect(items.count == 2)
        #expect(items.contains(where: { $0.itemID == 1 }))
        #expect(items.contains(where: { $0.itemID == 2 }))
    }

    @MainActor
    @Test func processRefund_then_calls_service_with_reason() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        sut.selectOrder(order)
        _ = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        sut.startRefundFlow()

        // When
        try await sut.processRefund(reason: "Customer changed their mind")

        // Then
        #expect(refundsService.spyCreateRefundReason == "Customer changed their mind")
    }

    @MainActor
    @Test func processRefund_when_successful_then_clears_selection() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 2, price: 10.00, formattedPrice: "$10.00")
        ])

        sut.selectOrder(order)
        _ = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        sut.startRefundFlow()
        let initialCount = sut.refundSelectableItems.count
        try #require(initialCount == 2)

        // When
        try await sut.processRefund(reason: .none)

        // Then
        #expect(sut.refundSelectableItems.count == 0)
    }

    @MainActor
    @Test func processRefund_when_service_throws_then_propagates_error() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        sut.selectOrder(order)
        _ = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        sut.startRefundFlow()

        struct TestError: Error {}
        refundsService.createRefundErrorToThrow = TestError()

        // When / Then
        var thrownError: Error?
        do {
            try await sut.processRefund(reason: .none)
        } catch {
            thrownError = error
        }

        #expect(thrownError is TestError)
    }

    @MainActor
    @Test func processRefund_then_converts_items_with_correct_properties() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 42, quantity: 3, price: 15.50, totalTax: 1.55, formattedPrice: "$15.50")
        ])

        sut.selectOrder(order)
        _ = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        sut.startRefundFlow()

        // When
        try await sut.processRefund(reason: .none)

        // Then
        let items = try #require(refundsService.spyCreateRefundItems)
        #expect(items.count == 3)

        let firstItem = items[0]
        #expect(firstItem.itemID == 42)
        #expect(firstItem.lineItemTotal == 46.50)
        #expect(firstItem.totalTax == 1.55)
        #expect(firstItem.originalQuantity == 3)
    }

    @MainActor
    @Test func processRefund_when_supportsAutomaticRefund_is_true_then_calls_service_with_automatic_refund_true() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        sut.selectOrder(order)
        _ = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        sut.startRefundFlow()

        // When
        try await sut.processRefund(reason: .none)

        // Then
        #expect(refundsService.spyCreateRefundAutomaticRefund == true)
    }

    @MainActor
    @Test func processRefund_when_supportsAutomaticRefund_is_false_then_calls_service_with_automatic_refund_false() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: false
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])

        sut.selectOrder(order)
        _ = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        sut.startRefundFlow()

        // When
        try await sut.processRefund(reason: .none)

        // Then
        #expect(refundsService.spyCreateRefundAutomaticRefund == false)
    }

    @MainActor
    @Test func processRefund_when_successful_then_updates_order() async throws {
        // Given
        featureFlags.isPointOfSaleRefundsi1Enabled = true
        refundsService.providePointOfSaleRefundsResultToReturn = POSRefundsResult(
            refunds: [],
            isFullyRefunded: false,
            supportsAutomaticRefund: true
        )

        let order = makeOrder(lineItems: [
            makePOSOrderItem(itemID: 1, quantity: 1, price: 10.00, formattedPrice: "$10.00")
        ])
        orderListService.orderPages = [[order]]
        orderListService.loadOrderResult = order

        await sut.loadOrders()

        sut.selectOrder(order)
        _ = await waitForCondition { [weak self] in
            guard let sut = self?.sut else { return false }
            if case .loaded = sut.selectedOrderRefundsState { return true }
            return false
        }
        sut.startRefundFlow()

        // When
        try await sut.processRefund(reason: .none)

        // Then
        #expect(orderListService.loadOrderWasCalled == true)
        #expect(orderListService.lastLoadOrderID == order.id)
    }
}

private extension POSOrderListControllerTests {
    func makeController(currencySettings: CurrencySettings) -> POSOrderListController {
        let provider = MockCurrencySettingsProvider(currencySettings: currencySettings)
        let formatter = CurrencyFormatter(currencySettings: currencySettings)
        return POSOrderListController(
            orderListFetchStrategyFactory: fetchStrategyFactory,
            refundsService: refundsService,
            featureFlags: featureFlags,
            currencySettingsProvider: provider,
            currencyFormatter: formatter
        )
    }

    func makeOrder(id: Int64 = 1,
                   paymentMethodID: String = "woocommerce_payments",
                   paymentMethodTitle: String = "cod",
                   lineItems: [POSOrderItem] = []) -> POSOrder {
        POSOrder(
            id: id,
            number: "\(id)",
            dateCreated: Date(),
            status: .completed,
            formattedTotal: "$25.99",
            formattedSubtotal: "$25.99",
            customerEmail: "customer1@example.com",
            paymentMethodID: paymentMethodID,
            paymentMethodTitle: paymentMethodTitle,
            lineItems: lineItems,
            refunds: [],
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$25.99",
            formattedNetAmount: nil
        )
    }

    func makePOSOrderItem(
        itemID: Int64 = 1,
        name: String = "Test Item",
        quantity: Decimal = 1,
        price: Decimal = 10.00,
        total: Decimal? = nil,
        totalTax: Decimal = 0,
        formattedPrice: String = "$10.00",
        formattedTotal: String? = nil,
        imageSrc: String? = nil,
        attributes: [OrderItemAttribute] = []
    ) -> POSOrderItem {
        POSOrderItem(
            itemID: itemID,
            name: name,
            quantity: quantity,
            price: price,
            total: total ?? (price * quantity),
            totalTax: totalTax,
            formattedPrice: formattedPrice,
            formattedTotal: formattedTotal ?? formattedPrice,
            imageSrc: imageSrc,
            attributes: attributes
        )
    }
}
