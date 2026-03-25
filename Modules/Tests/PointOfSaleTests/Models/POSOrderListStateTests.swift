import Foundation
import Testing
@testable import PointOfSale
import struct Yosemite.POSOrder
import enum NetworkingCore.OrderStatusEnum

struct POSOrderListStateTests {
    @Test
    func updatingOrders_when_loaded_then_preserves_hasMoreItems_flag() {
        // Given
        let state = POSOrderListState.loaded(sampleOrders, hasMoreItems: true)
        let updatedOrders = [sampleOrders[0]]

        // When
        let newState = state.updatingOrders(with: updatedOrders)

        // Then
        if case .loaded(let orders, let hasMoreItems) = newState {
            #expect(orders.count == 1)
            #expect(orders[0].id == 1)
            #expect(hasMoreItems == true)
        } else {
            #expect(Bool(false), "Expected loaded state")
        }
    }

    @Test
    func updatingOrders_when_loading_then_preserves_loading_state() {
        // Given
        let state = POSOrderListState.loading(sampleOrders)
        let updatedOrders = [sampleOrders[1]]

        // When
        let newState = state.updatingOrders(with: updatedOrders)

        // Then
        if case .loading(let orders) = newState {
            #expect(orders.count == 1)
            #expect(orders[0].id == 2)
        } else {
            #expect(Bool(false), "Expected loading state")
        }
    }

    @Test
    func updatingOrders_when_inline_error_then_preserves_error_and_context() {
        // Given
        let errorState = PointOfSaleErrorState.errorOnLoadingOrders(error: NSError(domain: "test", code: 0))
        let state = POSOrderListState.inlineError(sampleOrders, error: errorState, context: .refresh)
        let updatedOrders = [sampleOrders[0]]

        // When
        let newState = state.updatingOrders(with: updatedOrders)

        // Then
        if case .inlineError(let orders, let error, let context) = newState {
            #expect(orders.count == 1)
            #expect(orders[0].id == 1)
            #expect(error == errorState)
            #expect(context == .refresh)
        } else {
            #expect(Bool(false), "Expected inlineError state")
        }
    }

    @Test
    func updatingOrders_when_empty_then_returns_unchanged() {
        // Given
        let state = POSOrderListState.empty
        let updatedOrders = sampleOrders

        // When
        let newState = state.updatingOrders(with: updatedOrders)

        // Then
        if case .empty = newState {
            // Expected - state should remain empty
        } else {
            #expect(Bool(false), "Expected empty state to remain unchanged")
        }
    }

    @Test
    func updatingOrders_when_error_then_returns_unchanged() {
        // Given
        let errorState = PointOfSaleErrorState.errorOnLoadingOrders(error: NSError(domain: "test", code: 0))
        let state = POSOrderListState.error(errorState)
        let updatedOrders = sampleOrders

        // When
        let newState = state.updatingOrders(with: updatedOrders)

        // Then
        if case .error(let error) = newState {
            #expect(error == errorState)
        } else {
            #expect(Bool(false), "Expected error state to remain unchanged")
        }
    }

    @Test
    func orders_when_various_states_then_returns_correct_orders() {
        // Given & When & Then
        let loadedState = POSOrderListState.loaded(sampleOrders, hasMoreItems: false)
        #expect(loadedState.orders.count == 2)

        let loadingState = POSOrderListState.loading(sampleOrders)
        #expect(loadingState.orders.count == 2)

        let errorState = PointOfSaleErrorState.errorOnLoadingOrders(error: NSError(domain: "test", code: 0))
        let inlineErrorState = POSOrderListState.inlineError(sampleOrders, error: errorState, context: .refresh)
        #expect(inlineErrorState.orders.count == 2)

        let emptyState = POSOrderListState.empty
        #expect(emptyState.orders.isEmpty)

        let fullErrorState = POSOrderListState.error(errorState)
        #expect(fullErrorState.orders.isEmpty)
    }
}

private extension POSOrderListStateTests {
    private var sampleOrders: [POSOrder] {
        [
            POSOrder(id: 1, number: "1001", dateCreated: Date(), status: .completed,
                     formattedTotal: "$10.00", formattedSubtotal: "$10.00", customerEmail: "test1@example.com",
                     paymentMethodID: "woocommerce_payments", paymentMethodTitle: "Credit Card", lineItems: [],
                     refunds: [], formattedDiscountTotal: nil, formattedTotalTax: "$0.00",
                     formattedPaymentTotal: "$10.00", formattedNetAmount: nil, datePaid: Date()),
            POSOrder(id: 2, number: "1002", dateCreated: Date(), status: .completed,
                     formattedTotal: "$20.00", formattedSubtotal: "$20.00", customerEmail: "test2@example.com",
                     paymentMethodID: "cod", paymentMethodTitle: "Cash", lineItems: [],
                     refunds: [], formattedDiscountTotal: nil, formattedTotalTax: "$0.00",
                     formattedPaymentTotal: "$20.00", formattedNetAmount: nil, datePaid: Date())
        ]
    }
}
