import Testing
import Yosemite
import NetworkingCore
@testable import WooCommerce

@Suite
struct LastOrderDashboardRowViewModelTests {

    // MARK: - Fulfillment badge text

    @Test
    func test_fulfillmentBadgeText_when_fulfilled_then_returns_fulfilled_text() {
        // Given
        let order = Order.fake().copy(fulfillmentStatus: .fulfilled)

        // When
        let viewModel = LastOrderDashboardRowViewModel(order: order)

        // Then
        #expect(viewModel.fulfillmentBadgeText == "Fulfilled")
    }

    @Test
    func test_fulfillmentBadgeText_when_unfulfilled_then_returns_unfulfilled_text() {
        // Given
        let order = Order.fake().copy(fulfillmentStatus: .unfulfilled)

        // When
        let viewModel = LastOrderDashboardRowViewModel(order: order)

        // Then
        #expect(viewModel.fulfillmentBadgeText == "Unfulfilled")
    }

    @Test
    func test_fulfillmentBadgeText_when_unknown_then_returns_nil() {
        // Given
        let order = Order.fake().copy(fulfillmentStatus: .unknown)

        // When
        let viewModel = LastOrderDashboardRowViewModel(order: order)

        // Then
        #expect(viewModel.fulfillmentBadgeText == nil)
    }

    @Test
    func test_fulfillmentBadgeText_when_partiallyFulfilled_then_returns_nil() {
        // Given
        let order = Order.fake().copy(fulfillmentStatus: .partiallyFulfilled)

        // When
        let viewModel = LastOrderDashboardRowViewModel(order: order)

        // Then
        #expect(viewModel.fulfillmentBadgeText == nil)
    }

    @Test
    func test_fulfillmentBadgeText_when_noFulfillments_then_returns_nil() {
        // Given
        let order = Order.fake().copy(fulfillmentStatus: .noFulfillments)

        // When
        let viewModel = LastOrderDashboardRowViewModel(order: order)

        // Then
        #expect(viewModel.fulfillmentBadgeText == nil)
    }

    // MARK: - isFulfillmentStatusRequired

    @Test
    func test_isFulfillmentStatusRequired_when_CIAB_and_fulfilled_then_returns_true() {
        // Given
        let order = Order.fake().copy(fulfillmentStatus: .fulfilled)

        // When
        let viewModel = LastOrderDashboardRowViewModel(order: order, isCIAB: true)

        // Then
        #expect(viewModel.isFulfillmentStatusRequired == true)
    }

    @Test
    func test_isFulfillmentStatusRequired_when_CIAB_and_unfulfilled_then_returns_true() {
        // Given
        let order = Order.fake().copy(fulfillmentStatus: .unfulfilled)

        // When
        let viewModel = LastOrderDashboardRowViewModel(order: order, isCIAB: true)

        // Then
        #expect(viewModel.isFulfillmentStatusRequired == true)
    }

    @Test
    func test_isFulfillmentStatusRequired_when_CIAB_and_unknown_then_returns_false() {
        // Given
        let order = Order.fake().copy(fulfillmentStatus: .unknown)

        // When
        let viewModel = LastOrderDashboardRowViewModel(order: order, isCIAB: true)

        // Then
        #expect(viewModel.isFulfillmentStatusRequired == false)
    }

    @Test
    func test_isFulfillmentStatusRequired_when_not_CIAB_and_fulfilled_then_returns_false() {
        // Given
        let order = Order.fake().copy(fulfillmentStatus: .fulfilled)

        // When
        let viewModel = LastOrderDashboardRowViewModel(order: order, isCIAB: false)

        // Then
        #expect(viewModel.isFulfillmentStatusRequired == false)
    }
}
