import Testing
import Foundation
@testable import WooCommerce
import protocol Yosemite.POSOrderableItem
@testable import struct Yosemite.POSSimpleProduct
import struct Yosemite.Order
import Combine

struct PointOfSaleAggregateModelTests {
    struct OrderStageTests {
        private let sut: PointOfSaleAggregateModel

        init() {
            self.sut = PointOfSaleAggregateModel(itemsController: MockPointOfSaleItemsController(),
                                                 cardPresentPaymentService: MockCardPresentPaymentService(),
                                                 orderController: MockPointOfSaleOrderController())
        }

        @Test func inits_with_building_order_stage() async throws {
            #expect(sut.orderStage == .building)
        }

        @Test func startNewCart_removes_all_items_from_cart_and_moves_back_to_building() async throws {
            // Given
            sut.addToCart(makeItem())
            await sut.checkOut()
            try #require(sut.orderStage == .finalizing)
            try #require(sut.cart.isNotEmpty)

            // When
            sut.startNewCart()

            // Then
            #expect(sut.orderStage == .building)
            #expect(sut.cart.isEmpty)
        }

        @Test func checkOut_moves_to_finalizing_order_stage() async throws {
            // Given
            sut.addToCart(makeItem())

            // When
            await sut.checkOut()

            // Then
            #expect(sut.orderStage == .finalizing)
        }

        @Test func addMoreToCart_moves_to_building_order_stage() async throws {
            // Given
            sut.addToCart(makeItem())
            await sut.checkOut()
            try #require(sut.orderStage == .finalizing)

            // When
            sut.addMoreToCart()

            // Then
            #expect(sut.orderStage == .building)
        }

    }

    struct CartTests {
        let sut: PointOfSaleAggregateModel
        private let analytics: WooAnalytics!
        private let analyticsProvider: MockAnalyticsProvider!

        init() {
            analyticsProvider = MockAnalyticsProvider()
            analytics = WooAnalytics(analyticsProvider: analyticsProvider)
            sut = PointOfSaleAggregateModel(itemsController: MockPointOfSaleItemsController(),
                                            cardPresentPaymentService: MockCardPresentPaymentService(),
                                            orderController: MockPointOfSaleOrderController(),
                                            analytics: analytics)
        }

        @Test func addItem_results_in_a_non_empty_cart() async throws {
            // Given
            try #require(sut.cart.isEmpty)
            let item = makeItem()

            // When
            sut.addToCart(item)

            // Then
            #expect(sut.cart.isNotEmpty)
        }

        @Test func addItem_puts_new_items_first_in_the_cart() async throws {
            // Given
            let items = [makeItem(), makeItem(), makeItem()]

            // When
            items.forEach(sut.addToCart(_:))

            // Then
            #expect(sut.cart.map(\.item.id) == items.reversed().map(\.id))
        }

        @Test func removeItem_after_adding_two_items_removes_item_correctly() async throws {
            // Given
            let item = makeItem(name: "Item 1")
            let anotherItem = makeItem(name: "Item 2")

            sut.addToCart(item)
            sut.addToCart(anotherItem)
            try #require(sut.cart.count == 2)

            // When
            let firstItem = try #require(sut.cart.first)
            sut.remove(cartItem: firstItem)

            // Then
            #expect(sut.cart.count == 1)
            #expect(sut.cart.first?.item.name == item.name)
        }

        @Test func removeAllItemsFromCart_removes_everything() async throws {
            // Given
            let item = makeItem(name: "Item 1")
            let anotherItem = makeItem(name: "Item 2")

            sut.addToCart(item)
            sut.addToCart(anotherItem)
            try #require(sut.cart.count == 2)

            // When
            sut.removeAllItemsFromCart()

            // Then
            #expect(sut.cart.isEmpty)
        }

        @Test(.disabled(
            """
            This test doesn't currently work; analytics extensions are not thread-safe,
            and using the MainActor means the assert happens too early. I don't think
            we want the addToCart to be async, but that would be one way to fix it.
            """))
        func addToCart_tracks_analytics_event() async throws {
            // Given
            let item = makeItem()

            // When
            sut.addToCart(item)

            // Then
            let event = try #require(analyticsProvider.receivedEvents.first)
            #expect(event == "pos_item_added_to_cart")
        }
    }

    struct OrderTests {
        private let cardPresentPaymentService = MockCardPresentPaymentService()
        private let itemsController = MockPointOfSaleItemsController()
        private let orderController = MockPointOfSaleOrderController()
        private let sut: PointOfSaleAggregateModel

        init() {
            orderController.orderStateToReturn = makeLoadedOrderState(cartTotal: "$0.00")
            sut = PointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            sut.addToCart(makeItem())
        }

        @Test func startNewCart_calls_clearOrder() async throws {
            // Given

            // When
            sut.startNewCart()

            // Then
            #expect(orderController.clearOrderWasCalled == true)
        }

        @Test func checkout_with_items_calls_sync_order() async throws {
            // Given
            sut.addToCart(makeItem())
            let item = try #require(sut.cart.first)

            // When
            await sut.checkOut()

            let passedItem = try #require(orderController.spyCartProducts?.first)
            #expect(passedItem.id == item.id)
        }

        // The UI prevents no-item checkouts, but it's the controller's responsibility to handle this.
        @Test func checkOut_without_items_calls_sync_order() async throws {
            // Given
            sut.removeAllItemsFromCart()

            // When
            await sut.checkOut()

            // Then
            #expect(orderController.syncOrderWasCalled == true)
            #expect(orderController.spyCartProducts?.isEmpty == true)
        }

        @Test func when_collectPayment_is_called_channel_is_set_to_pos() async throws {
            // Given
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)
            orderController.orderStateToReturn = makeLoadedOrderState(cartTotal: "$0.00")

            // When
            await sut.checkOut()
            #expect(cardPresentPaymentService.collectPaymentWasCalled)

            // Then
            #expect(cardPresentPaymentService.collectPaymentChannel == .pos)
        }
    }

    struct PaymentTests {
        private let cardPresentPaymentService = MockCardPresentPaymentService()
        private let itemsController = MockPointOfSaleItemsController()
        private let orderController = MockPointOfSaleOrderController()
        private let sut: PointOfSaleAggregateModel

        init() {
            sut = PointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
        }

        @Test func init_sets_paymentState_to_idle() async throws {
            // Given that we don't specify a payment state
            // When we init
            let sut = PointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            // Then
            #expect(sut.paymentState == .card(.idle))
        }

        @Test func startNewCart_sets_payment_state_to_idle() async throws {
            // Given
            let sut = PointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                paymentState: .card(.cardPaymentSuccessful))

            // When
            sut.startNewCart()

            // Then
            #expect(sut.paymentState == .card(.idle))
        }

        @Test func startNewCart_sets_payment_message_to_nil() async throws {
            // Given
            cardPresentPaymentService.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))
            try #require(sut.cardPresentPaymentInlineMessage != nil)

            // When
            sut.startNewCart()

            // Then
            #expect(sut.cardPresentPaymentInlineMessage == nil)
        }

        @Test func addMoreToCart_sets_payment_state_to_idle() async throws {
            // Given
            let sut = PointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                paymentState: .card(.cardPaymentSuccessful))

            // When
            sut.addMoreToCart()

            // Then
            #expect(sut.paymentState == .card(.idle))
        }

        @Test func addMoreToCart_sets_payment_message_to_nil() async throws {
            // Given
            cardPresentPaymentService.paymentEvent = .show(
                eventDetails: .tapSwipeOrInsertCard(
                    inputMethods: [.tap, .swipe, .insert],
                    cancelPayment: {}))
            try #require(sut.cardPresentPaymentInlineMessage != nil)

            // When
            sut.addMoreToCart()

            // Then
            #expect(sut.cardPresentPaymentInlineMessage == nil)
        }

        @Test func cardPresentPaymentInlineMessage_when_paymentSuccess_then_total_set() async throws {
            // Given order totals:
            // Note that orderTotal is used, but the Order values are given for test robustness.
            orderController.orderState = makeLoadedOrderState(
                orderTotal: "$52.30",
                order: Order.fake().copy(currency: "$", total: "52.30"))

            // When
            cardPresentPaymentService.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

            // Then
            guard case .paymentSuccess(let viewModel) = sut.cardPresentPaymentInlineMessage else {
                Issue.record("Expected cardPresentPaymentInlineMessage to be paymentSuccess")
                return
            }
            #expect(viewModel.message == "A payment of $52.30 was successfully made")
        }

        @Test func paymentIntentCreationErrorMessage_when_paymentIntentCreationError_tryAgain_cancels_payment() async throws {
            // Given
            struct TestError: Error {}

            // When paymentIntentCreationError event is received
            cardPresentPaymentService.paymentEvent = .show(
                eventDetails: .paymentIntentCreationError(error: TestError(), cancelPayment: {})
            )

            // Then
            guard case .paymentIntentCreationError(let viewModel) = sut.cardPresentPaymentInlineMessage else {
                Issue.record("Expected cardPresentPaymentInlineMessage to be paymentIntentCreationError")
                return
            }
            let tryAgainAction = viewModel.tryAgainButtonViewModel.actionHandler

            tryAgainAction()
            #expect(cardPresentPaymentService.cancelPaymentCalled == true)
        }

        @Test func paymentIntentCreationErrorMessage_when_paymentIntentCreationError_editOrder_moves_back_to_building() async throws {
            // Given
            struct TestError: Error {}
            await sut.checkOut()

            // When paymentIntentCreationError event is received
            cardPresentPaymentService.paymentEvent = .show(
                eventDetails: .paymentIntentCreationError(error: TestError(), cancelPayment: {})
            )

            // Then
            guard case .paymentIntentCreationError(let viewModel) = sut.cardPresentPaymentInlineMessage,
                  let editOrderAction = viewModel.editOrderButtonViewModel?.actionHandler
            else {
                Issue.record("Expected cardPresentPaymentInlineMessage to be paymentIntentCreationError")
                return
            }

            try #require(sut.orderStage == .finalizing)
            editOrderAction()
            #expect(sut.orderStage == .building)
        }

        @Test func checkOut_when_reader_connects_collectPayment_called() async throws {
            // Given
            cardPresentPaymentService.connectedReader = nil

            orderController.orderStateToReturn = makeLoadedOrderState()
            await sut.checkOut()
            cardPresentPaymentService.collectPaymentWasCalled = false

            // When
            // `await confirmation` callback only waits until this completes, not until some timeout.
            // Since this is synchonous but triggers async combine behaviour, we can't use that approach.
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)

            // Then
            let timeout = ContinuousClock.now + .seconds(2)

            while cardPresentPaymentService.collectPaymentWasCalled != true {
                try await Task.sleep(for: .milliseconds(1))
                try #require(.now < timeout)
            }
        }

        @Test func checkOut_when_reader_is_already_connected_collectPayment_called() async throws {
            // Given
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)
            orderController.orderStateToReturn = makeLoadedOrderState()

            // When
            await sut.checkOut()

            // Then
            #expect(cardPresentPaymentService.collectPaymentWasCalled)
        }

        @Test func after_disconnection_when_reader_reconnects_collectPayment_called() async throws {
            // Given
            cardPresentPaymentService.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)

            orderController.orderStateToReturn = makeLoadedOrderState()
            await sut.checkOut()
            await cardPresentPaymentService.disconnectReader()
            cardPresentPaymentService.collectPaymentWasCalled = false

            // When
            // `await confirmation` callback only waits until this completes, not until some timeout.
            // Since this is synchonous but triggers async combine behaviour, we can't use that approach.
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)

            // Then
            let timeout = ContinuousClock.now + .seconds(1)

            while cardPresentPaymentService.collectPaymentWasCalled != true {
                try await Task.sleep(for: .milliseconds(1))
                try #require(.now < timeout)
            }
        }

        // MARK: Onboarding
        @Test func cardPresentPaymentOnboardingViewModel_is_non_nil_when_onboarding_is_required() async throws {
            // Given
            let onboardingViewModel = CardPresentPaymentsOnboardingViewModel(fixedState: .pluginNotActivated(plugin: .stripe))
            cardPresentPaymentService.paymentEvent = .idle
            try #require(sut.cardPresentPaymentOnboardingViewModel == nil)

            // When
            cardPresentPaymentService.paymentEvent = .showOnboarding(onboardingViewModel: onboardingViewModel, onCancel: {})

            // Then
            #expect(sut.cardPresentPaymentOnboardingViewModel?.state == .pluginNotActivated(plugin: .stripe))
        }
    }

    struct AnalyticsTests {
        private let analyticsProvider = MockAnalyticsProvider()
        private let analytics: WooAnalytics
        private let cardPresentPaymentService = MockCardPresentPaymentService()
        private let itemsController = MockPointOfSaleItemsController()
        private let orderController = MockPointOfSaleOrderController()
        private let sut: PointOfSaleAggregateModel

        init() {
            analytics = WooAnalytics(analyticsProvider: analyticsProvider)
            orderController.orderState = makeLoadedOrderState()

            sut = PointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                analytics: analytics)

            sut.addToCart(makeItem())
        }

        @Test func paymentsOnboardingDismissed_event_is_tracked_with_state_when_cancelOnboarding_is_invoked() async throws {
            // Given
            let onboardingViewModel = CardPresentPaymentsOnboardingViewModel(fixedState: .noConnectionError)
            cardPresentPaymentService.paymentEvent = .showOnboarding(onboardingViewModel: onboardingViewModel, onCancel: {})

            // When
            sut.cancelCardPaymentsOnboarding()

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "pos_payments_onboarding_dismissed" }) != nil)
            let eventProperties = try #require(analyticsProvider.receivedProperties.first(where: { $0.keys.contains("onboarding_state")
            }))
            #expect(eventProperties["onboarding_state"] as? String == "no_connection_error")
        }

        @Test func pointOfSalePaymentsOnboardingShown_event_is_tracked_when_trackOnboardingShown_is_invoked() async throws {
            // Given

            // When
            sut.trackCardPaymentsOnboardingShown()

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "pos_payments_onboarding_shown" }) != nil)
        }
    }
}

private func makeItem(name: String = "") -> POSOrderableItem {
    return MockPOSOrderableItem(name: name, formattedPrice: "")
}

private func makeLoadedOrderState(cartTotal: String = "",
                                  orderTotal: String = "",
                                  taxTotal: String = "",
                                  order: Order = .fake()) -> PointOfSaleInternalOrderState {
    PointOfSaleInternalOrderState.loaded(
        PointOfSaleOrderTotals(cartTotal: cartTotal, orderTotal: orderTotal, taxTotal: taxTotal),
        order
    )
}
