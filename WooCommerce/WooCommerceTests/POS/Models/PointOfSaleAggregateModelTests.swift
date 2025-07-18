import Testing
import Foundation
@testable import WooCommerce
import protocol WooFoundation.Analytics
import protocol Yosemite.PointOfSaleBarcodeScanServiceProtocol
import protocol Yosemite.POSOrderableItem
import enum Yosemite.POSItem
@testable import struct Yosemite.POSSimpleProduct
import struct Yosemite.Order
import protocol Yosemite.POSSearchHistoryProviding
import enum Yosemite.POSItemType
import Combine

struct PointOfSaleAggregateModelTests {
    struct OrderStageTests {
        @available(iOS 17.0, *)
        @Test func inits_with_building_order_stage() async throws {
            // Given
            let sut = makePointOfSaleAggregateModel()
            // Then
            #expect(sut.orderStage == .building)
        }

        @available(iOS 17.0, *)
        @Test func startNewCart_removes_all_items_from_cart_and_moves_back_to_building() async throws {
            // Given
            let sut = makePointOfSaleAggregateModel()
            sut.addToCart(makePurchasableItem())
            await sut.checkOut()
            try #require(sut.orderStage == .finalizing)
            try #require(!sut.cart.isEmpty)

            // When
            sut.startNewCart()

            // Then
            #expect(sut.orderStage == .building)
            #expect(sut.cart.isEmpty)
        }

        @available(iOS 17.0, *)
        @Test func checkOut_moves_to_finalizing_order_stage() async throws {
            // Given
            let sut = makePointOfSaleAggregateModel()
            sut.addToCart(makePurchasableItem())

            // When
            await sut.checkOut()

            // Then
            #expect(sut.orderStage == .finalizing)
        }

        @available(iOS 17.0, *)
        @Test func addMoreToCart_moves_to_building_order_stage() async throws {
            // Given
            let sut = makePointOfSaleAggregateModel()
            sut.addToCart(makePurchasableItem())
            await sut.checkOut()
            try #require(sut.orderStage == .finalizing)

            // When
            sut.addMoreToCart()

            // Then
            #expect(sut.orderStage == .building)
        }
    }

    struct CartTests {
        private let analytics: WooAnalytics!
        private let analyticsProvider: MockAnalyticsProvider!

        init() {
            analyticsProvider = MockAnalyticsProvider()
            analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        }

        @available(iOS 17.0, *)
        @Test func addLoadingItem_adds_loading_item_to_cart() async throws {
            // Given
            var cart = Cart()
            try #require(cart.purchasableItems.isEmpty)

            // When
            let loadingItem = cart.addLoadingItem()

            // Then
            #expect(cart.purchasableItems.count == 1)
            let item = try #require(cart.purchasableItems.first)
            #expect(item.id == loadingItem.id)
            guard case .loading = item.state else {
                throw CartTestError.unexpectedItemStateInCart
            }
        }

        @available(iOS 17.0, *)
        @Test func updateLoadingItem_updates_loading_item_with_simple_product() async throws {
            // Given
            var cart = Cart()
            let loadingItem = cart.addLoadingItem()
            let purchasableItem = makePurchasableItem(name: "Test Product")

            // When
            cart.updateLoadingItem(id: loadingItem.id, with: purchasableItem)

            // Then
            #expect(cart.purchasableItems.count == 1)
            let item = try #require(cart.purchasableItems.first)
            guard case .loaded(let loadedItem) = item.state else {
                throw CartTestError.unexpectedItemStateInCart
            }
            #expect(loadedItem.name == "Test Product")
        }

        @available(iOS 17.0, *)
        @Test func addItem_results_in_a_non_empty_cart() async throws {
            // Given
            let sut = makePointOfSaleAggregateModel(analytics: analytics)
            try #require(sut.cart.isEmpty)
            let item = makePurchasableItem()

            // When
            sut.addToCart(item)

            // Then
            #expect(!sut.cart.isEmpty)
        }

        @available(iOS 17.0, *)
        @Test func addItem_puts_new_items_first_in_the_cart() async throws {
            // Given
            let sut = makePointOfSaleAggregateModel(analytics: analytics)
            let items = [makePurchasableItem(), makePurchasableItem(), makePurchasableItem()]

            // When
            items.forEach(sut.addToCart(_:))

            // Then
            let cartItemIDs = try sut.cart.purchasableItems.map { purchasableItem in
                guard case let .loaded(item) = purchasableItem.state else {
                    throw CartTestError.unexpectedItemStateInCart
                }
                return item.id
            }
            #expect(cartItemIDs == items.reversed().map(\.id))
        }

        @available(iOS 17.0, *)
        @Test func removeItem_after_adding_two_items_removes_item_correctly() async throws {
            // Given
            let sut = makePointOfSaleAggregateModel(analytics: analytics)
            let item = makePurchasableItem(name: "Item 1")
            let anotherItem = makePurchasableItem(name: "Item 2")

            sut.addToCart(item)
            sut.addToCart(anotherItem)
            try #require(sut.cart.purchasableItems.count == 2)

            // When
            let firstItem = try #require(sut.cart.purchasableItems.first)
            sut.remove(cartItem: firstItem)

            // Then
            #expect(sut.cart.purchasableItems.count == 1)
            #expect(sut.cart.purchasableItems.first?.title == "Item 1")
        }

        @available(iOS 17.0, *)
        @Test func removeAllItemsFromCart_removes_everything() async throws {
            // Given
            let sut = makePointOfSaleAggregateModel(analytics: analytics)
            let item = makePurchasableItem(name: "Item 1")
            let anotherItem = makePurchasableItem(name: "Item 2")

            sut.addToCart(item)
            sut.addToCart(anotherItem)
            try #require(sut.cart.purchasableItems.count == 2)

            // When
            sut.removeAllItemsFromCart()

            // Then
            #expect(sut.cart.isEmpty)
        }

        @available(iOS 17.0, *)
        @Test func removeAllItemsFromCartOfCouponType_removes_coupons() async throws {
            // Given
            let sut = makePointOfSaleAggregateModel(analytics: analytics)
            let item = makePurchasableItem(name: "Item 1")
            let anotherItem = makePurchasableItem(name: "Item 2")
            let couponItem = makeCouponItem(code: "VALID")
            sut.addToCart(item)
            sut.addToCart(anotherItem)
            sut.addToCart(couponItem)
            try #require(sut.cart.purchasableItems.count == 2)
            try #require(sut.cart.coupons.count == 1)

            // When
            sut.removeAllItemsFromCart(types: [.coupon])

            // Then
            #expect(sut.cart.purchasableItems.count == 2)
            #expect(sut.cart.coupons.count == 0)
        }

        enum CartTestError: Error {
            case unexpectedItemStateInCart
        }
    }

    struct OrderTests {
        private let cardPresentPaymentService = MockCardPresentPaymentService()
        private let orderController = MockPointOfSaleOrderController()

        init() {
            orderController.orderStateToReturn = makeLoadedOrderState(cartTotal: "$0.00")
        }

        @available(iOS 17.0, *)
        @Test func startNewCart_calls_clearOrder() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
            )

            sut.addToCart(makePurchasableItem())

            // When
            sut.startNewCart()

            // Then
            #expect(orderController.clearOrderWasCalled == true)
        }

        @available(iOS 17.0, *)
        @Test func checkout_with_items_calls_sync_order() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
            )

            sut.addToCart(makePurchasableItem())
            sut.addToCart(makePurchasableItem())
            let item = try #require(sut.cart.purchasableItems.first)

            // When
            await sut.checkOut()

            let passedItem = try #require(orderController.spyCartProducts?.first)
            #expect(passedItem.id == item.id)
        }

        // The UI prevents no-item checkouts, but it's the controller's responsibility to handle this.
        @available(iOS 17.0, *)
        @Test func checkOut_without_items_calls_sync_order() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
            )

            sut.addToCart(makePurchasableItem())
            sut.removeAllItemsFromCart()

            // When
            await sut.checkOut()

            // Then
            #expect(orderController.syncOrderWasCalled == true)
            #expect(orderController.spyCartProducts?.isEmpty == true)
        }

        @available(iOS 17.0, *)
        @Test func when_collectPayment_is_called_channel_is_set_to_pos() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            sut.addToCart(makePurchasableItem())
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)
            orderController.orderStateToReturn = makeLoadedOrderState(orderTotal: "$1.00", orderTotalDecimal: 1)

            // When
            await sut.checkOut()
            #expect(cardPresentPaymentService.collectPaymentWasCalled)

            // Then
            #expect(cardPresentPaymentService.collectPaymentChannel == .pos)
        }

        @available(iOS 17.0, *)
        @Test func sendReceipt_when_invoked_then_calls_controller() async throws {
            // Given
            let orderController = MockPointOfSaleOrderController()
            let sut = makePointOfSaleAggregateModel(orderController: orderController)

            // When
            try await sut.sendReceipt(to: "")

            // Then
            #expect(orderController.sendReceiptWasCalled == true)
        }

        @available(iOS 17.0, *)
        @Test func sendReceipt_when_invoked_with_error_then_returns_error() async throws {
            // Given
            let orderController = MockPointOfSaleOrderController()
            orderController.shouldThrowReceiptError = true
            let expectedError = NSError(domain: "some error", code: -1)

            let sut = makePointOfSaleAggregateModel(orderController: orderController)

            do {
                // When
                try await sut.sendReceipt(to: "")
            } catch {
                // Then
                let nsError = error as NSError
                #expect(nsError.domain == expectedError.domain)
                #expect(nsError.code == expectedError.code)
            }
        }

        @available(iOS 17.0, *)
        @Test func when_pointOfSaleClosed_then_order_is_cleared_up() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            sut.addToCart(makePurchasableItem())

            // When
            sut.pointOfSaleClosed()

            // Then
            #expect(orderController.clearOrderWasCalled == true)
            #expect(cardPresentPaymentService.cancelPaymentCalled == true)
        }
    }

    struct PaymentTests {
        private let cardPresentPaymentService = MockCardPresentPaymentService()
        private let orderController = MockPointOfSaleOrderController()

        @available(iOS 17.0, *)
        @Test func init_sets_card_paymentState_to_idle() async throws {
            // Given that we don't specify a payment state
            // When we init
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            // Then
            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .idle))
            #expect(sut.paymentState.activePaymentMethod == .card)
        }

        @available(iOS 17.0, *)
        @Test func activePaymentMethod_returns_card_when_cash_is_idle() async throws {
            // Given
            let paymentState = PointOfSalePaymentState(card: .acceptingCard, cash: .idle)

            // Then
            #expect(paymentState.activePaymentMethod == .card)
        }

        @available(iOS 17.0, *)
        @Test func activePaymentMethod_returns_cash_when_cash_is_not_idle() async throws {
            // Given
            let paymentState = PointOfSalePaymentState(card: .acceptingCard, cash: .collectingCash)

            // Then
            #expect(paymentState.activePaymentMethod == .cash)
        }

        @available(iOS 17.0, *)
        @Test func activePaymentMethod_returns_cash_when_cash_is_paymentSuccess() async throws {
            // Given
            let paymentState = PointOfSalePaymentState(card: .idle, cash: .paymentSuccess)

            // Then
            #expect(paymentState.activePaymentMethod == .cash)
        }

        @available(iOS 17.0, *)
        @Test func startNewCart_sets_card_payment_state_to_idle() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                paymentState: PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle))

            // When
            sut.startNewCart()

            // Then
            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .idle))
        }

        @available(iOS 17.0, *)
        @Test func startNewCart_sets_payment_message_to_nil() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            cardPresentPaymentService.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))
            try #require(sut.cardPresentPaymentInlineMessage != nil)

            // When
            sut.startNewCart()

            // Then
            #expect(sut.cardPresentPaymentInlineMessage == nil)
        }

        @available(iOS 17.0, *)
        @Test func addMoreToCart_sets_card_payment_state_to_idle() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                paymentState: PointOfSalePaymentState(card: .cardPaymentSuccessful, cash: .idle))

            // When
            sut.addMoreToCart()

            // Then
            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .idle))
        }

        @available(iOS 17.0, *)
        @Test func addMoreToCart_sets_payment_message_to_nil() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            cardPresentPaymentService.paymentEvent = .show(
                eventDetails: .tapSwipeOrInsertCard(
                    inputMethods: [.tap, .swipe, .insert],
                    cancelPayment: {})
            )
            try #require(sut.cardPresentPaymentInlineMessage != nil)

            // When
            sut.addMoreToCart()

            // Then
            #expect(sut.cardPresentPaymentInlineMessage == nil)
        }

        @available(iOS 17.0, *)
        @Test func startCashPayment_calls_for_ongoing_card_payment_cancellation() async {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            // When
            await sut.startCashPayment()

            // Then
            #expect(cardPresentPaymentService.cancelPaymentCalled == true)
            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .collectingCash))
        }

        @available(iOS 17.0, *)
        @Test func startCashPayment_sets_payment_state_to_collectingCash() async {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            // When
            await sut.startCashPayment()

            // Then
            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .collectingCash))
        }

        @available(iOS 17.0, *)
        @Test func cancelCashPayment_resets_payment_state_to_idle() async {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
            await sut.startCashPayment()
            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .collectingCash))

            // When
            await sut.cancelCashPayment()

            // Then
            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .idle))
        }

        @available(iOS 17.0, *)
        @Test func cancelCashPayment_maintains_order_stage_as_finalizing() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
            #expect(sut.orderStage == .building)

            await sut.checkOut()
            #expect(sut.orderStage == .finalizing)

            await sut.startCashPayment()
            #expect(sut.paymentState == PointOfSalePaymentState(card: .idle, cash: .collectingCash))

            // When
            await sut.cancelCashPayment()

            // Then
            #expect(sut.orderStage == .finalizing)
        }

        @available(iOS 17.0, *)
        @Test func cardPresentPaymentInlineMessage_when_paymentSuccess_then_total_set() async throws {
            // Given order totals:
            // Note that orderTotal is used, but the Order values are given for test robustness.
            orderController.orderState = makeLoadedOrderState(
                orderTotal: "$52.30",
                orderTotalDecimal: 52.3,
                order: Order.fake().copy(currency: "$", total: "52.30"))
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            // When
            cardPresentPaymentService.paymentEvent = .show(eventDetails: .paymentSuccess(done: {}))

            // Then
            guard case .paymentSuccess(let viewModel) = sut.cardPresentPaymentInlineMessage else {
                Issue.record("Expected cardPresentPaymentInlineMessage to be paymentSuccess")
                return
            }
            #expect(viewModel.message == "A card payment of $52.30 was successfully made.")
        }

        @available(iOS 17.0, *)
        @Test func paymentIntentCreationErrorMessage_when_paymentIntentCreationError_tryAgain_cancels_payment() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
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

        @available(iOS 17.0, *)
        @Test func paymentIntentCreationErrorMessage_when_paymentIntentCreationError_editOrder_moves_back_to_building() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
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

        @available(iOS 17.0, *)
        @Test func checkOut_when_reader_connects_collectPayment_called() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
            cardPresentPaymentService.connectedReader = nil

            orderController.orderStateToReturn = makeLoadedOrderState(orderTotal: "$1.00", orderTotalDecimal: 1)
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

        @available(iOS 17.0, *)
        @Test func checkOut_when_reader_is_already_connected_and_order_more_than_zero_collectPayment_called() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)
            orderController.orderStateToReturn = makeLoadedOrderState(orderTotal: "$0.01", orderTotalDecimal: 0.01)

            // When
            await sut.checkOut()

            // Then
            #expect(cardPresentPaymentService.collectPaymentWasCalled)
        }

        @available(iOS 17.0, *)
        @Test func checkOut_when_reader_is_already_connected_and_order_is_free_collectPayment_is_not_called() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
            cardPresentPaymentService.connectedReader = .init(name: "Test reader", batteryLevel: 0.7)
            orderController.orderStateToReturn = makeLoadedOrderState(orderTotal: "$0.00", orderTotalDecimal: 0.0)

            // When
            await sut.checkOut()

            // Then
            #expect(!cardPresentPaymentService.collectPaymentWasCalled)
        }

        @available(iOS 17.0, *)
        @Test func after_disconnection_when_reader_reconnects_collectPayment_called() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
            cardPresentPaymentService.connectedReader = CardPresentPaymentCardReader(name: "Test", batteryLevel: 0.5)

            orderController.orderStateToReturn = makeLoadedOrderState(orderTotal: "$1.00", orderTotalDecimal: 1)
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

        @available(iOS 17.0, *)
        @Test(.disabled()) func cancelThenCollectPayment_still_collects_payment_when_cancellation_fails() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
            orderController.orderStateToReturn = makeLoadedOrderState(cartTotal: "$1.00")
            await orderController.syncOrder(for: .init(), retryHandler: {})

            struct TestError: Error {}
            cardPresentPaymentService.onCancelPaymentCalled = {
                throw TestError()
            }

            // When
            await sut.cancelThenCollectPayment()

            // Then
            #expect(cardPresentPaymentService.collectPaymentWasCalled)
        }

        // MARK: Onboarding
        @available(iOS 17.0, *)
        @Test func cardPresentPaymentOnboardingViewModel_is_non_nil_when_onboarding_is_required() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)
            let onboardingViewModel = CardPresentPaymentsOnboardingViewModel(
                fixedState: .pluginNotActivated(plugin: .stripe),
                useCase: MockCardPresentPaymentsOnboardingUseCase(initial: .pluginNotActivated(plugin: .stripe))
            )
            cardPresentPaymentService.paymentEvent = .idle
            try #require(sut.cardPresentPaymentOnboardingViewModel == nil)

            // When
            cardPresentPaymentService.paymentEvent = .showOnboarding(onboardingViewModel: onboardingViewModel, onCancel: {})

            // Then
            #expect(sut.cardPresentPaymentOnboardingViewModel?.state == .pluginNotActivated(plugin: .stripe))
        }

        @available(iOS 17.0, *)
        @Test func connectionSuccessAlert_is_filtered_when_waiting_to_start_payment_on_card_reader_connection() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            // Add item to cart and checkout to trigger payment waiting state
            sut.addToCart(makePurchasableItem())
            await sut.checkOut()

            // Verify we're in finalizing stage and no alert is currently shown
            try #require(sut.orderStage == .finalizing)
            try #require(sut.cardPresentPaymentAlertViewModel == nil)

            // When
            // Simulate connection success event while waiting for payment
            cardPresentPaymentService.paymentEvent = .show(eventDetails: .connectionSuccess(done: {}))

            // Then
            // The connection success alert should be filtered out and not shown
            #expect(sut.cardPresentPaymentAlertViewModel == nil)
        }

        @available(iOS 17.0, *)
        @Test func connectionSuccessAlert_is_shown_when_not_waiting_to_start_payment() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController)

            // Verify we're in building stage and no alert is currently shown
            try #require(sut.orderStage == .building)
            try #require(sut.cardPresentPaymentAlertViewModel == nil)

            // When
            // Simulate connection success event when not waiting for payment
            cardPresentPaymentService.paymentEvent = .show(eventDetails: .connectionSuccess(done: {}))

            // Then
            // The connection success alert should be shown
            guard case .connectionSuccess = sut.cardPresentPaymentAlertViewModel else {
                Issue.record("Expected cardPresentPaymentAlertViewModel to be connectionSuccess")
                return
            }
        }
    }

    struct AnalyticsTests {
        private let analyticsProvider = MockAnalyticsProvider()
        private let analytics: WooAnalytics
        private let cardPresentPaymentService = MockCardPresentPaymentService()
        private let orderController = MockPointOfSaleOrderController()

        init() {
            analytics = WooAnalytics(analyticsProvider: analyticsProvider)
            orderController.orderState = makeLoadedOrderState()
        }

        @available(iOS 17.0, *)
        @Test func paymentsOnboardingDismissed_event_is_tracked_with_state_when_cancelOnboarding_is_invoked() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                analytics: analytics)

            sut.addToCart(makePurchasableItem())

            let onboardingViewModel = CardPresentPaymentsOnboardingViewModel(
                fixedState: .noConnectionError,
                useCase: MockCardPresentPaymentsOnboardingUseCase(initial: .noConnectionError)
            )
            cardPresentPaymentService.paymentEvent = .showOnboarding(onboardingViewModel: onboardingViewModel, onCancel: {})

            // When
            sut.cancelCardPaymentsOnboarding()

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "payments_onboarding_dismissed" }) != nil)
            let eventProperties = try #require(analyticsProvider.receivedProperties.first(where: { $0.keys.contains("onboarding_state")
            }))
            #expect(eventProperties["onboarding_state"] as? String == "no_connection_error")
        }

        @available(iOS 17.0, *)
        @Test func pointOfSalePaymentsOnboardingShown_event_is_tracked_when_trackOnboardingShown_is_invoked() async throws {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                analytics: analytics)

            sut.addToCart(makePurchasableItem())

            // When
            sut.trackCardPaymentsOnboardingShown()

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "payments_onboarding_shown" }) != nil)
        }

        @available(iOS 17.0, *)
        @Test func connectCardReader_when_tapped_then_tracks_event() {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                analytics: analytics)

            //When
            sut.connectCardReader()

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "card_reader_connection_tapped" }) != nil)
        }

        @available(iOS 17.0, *)
        @Test func disconnectCardReader_when_tapped_then_tracks_event() {
            // Given
            let itemsController = MockPointOfSaleItemsController()
            let sut = makePointOfSaleAggregateModel(
                itemsController: itemsController,
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                analytics: analytics)

            //When
            sut.disconnectCardReader()

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "card_reader_disconnect_tapped" }) != nil)
        }

        @available(iOS 17.0, *)
        @Test func checkout_when_invoked_then_tracks_trackCheckoutTapped() async throws {
            // Given
            let analyticsTracker = MockPOSCollectOrderPaymentAnalyticsTracker()
            let sut = makePointOfSaleAggregateModel(
                cardPresentPaymentService: cardPresentPaymentService,
                orderController: orderController,
                collectOrderPaymentAnalyticsTracker: analyticsTracker)

            // When
            await sut.checkOut()

            // Then
            #expect(analyticsTracker.didCallTrackCheckoutTapped == true)
        }

        @available(iOS 17.0, *)
        @Test func cancelCashPayment_when_invoked_then_tracks_expected_event() async throws {
            // Given
            let analyticsTracker = MockPOSCollectOrderPaymentAnalyticsTracker()
            let sut = makePointOfSaleAggregateModel(
                analytics: analytics,
                collectOrderPaymentAnalyticsTracker: analyticsTracker)
            // When
            await sut.cancelCashPayment()

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "back_to_checkout_from_cash" }) != nil)
        }

        @available(iOS 17.0, *)
        @Test func startCashPayment_when_invoked_tracks_expected_event() async throws {
            // Given
            let mockAnalyticsProvider = MockAnalyticsProvider()
            let mockAnalytics = WooAnalytics(analyticsProvider: mockAnalyticsProvider)
            let sut = makePointOfSaleAggregateModel(analytics: mockAnalytics)

            // When
            await sut.startCashPayment()

            // Then
            #expect(mockAnalyticsProvider.receivedEvents.first(where: { $0 == "cash_payment_tapped" }) != nil)
        }
    }

    struct BarcodeTests {
        @available(iOS 17.0, *)
        @Test func barcodeScanned_when_fails_then_plays_sound() async {
            // Given
            let soundPlayer = MockPointOfSaleSoundPlayer()
            let barcodeScanService = MockPointOfSaleBarcodeScanService()
            let sut = makePointOfSaleAggregateModel(
                barcodeScanService: barcodeScanService,
                soundPlayer: soundPlayer)
            barcodeScanService.errorToThrow = .notFound(scannedCode: "123456")

            // When & Then
            await withCheckedContinuation { continuation in
                soundPlayer.onPlaySound = { sound in
                    #expect(sound == .barcodeScanFailure)
                    continuation.resume()
                }
                sut.barcodeScanned(.success("123456"))
            }
        }
    }
}

private func makePurchasableItem(name: String = "") -> POSItem {
    return .simpleProduct(POSSimpleProduct(
        id: UUID(),
        name: name,
        formattedPrice: "",
        productID: 1,
        price: "",
        manageStock: false,
        stockQuantity: nil,
        stockStatusKey: ""))
}

private func makeCouponItem(code: String = "") -> POSItem {
    return .coupon(.init(id: UUID(), code: code))
}

private func makeLoadedOrderState(cartTotal: String = "",
                                  orderTotal: String = "",
                                  taxTotal: String = "",
                                  orderTotalDecimal: Decimal = 0,
                                  order: Order = .fake()) -> PointOfSaleInternalOrderState {
    PointOfSaleInternalOrderState.loaded(
        PointOfSaleOrderTotals(cartTotal: cartTotal, orderTotal: orderTotal, taxTotal: taxTotal, orderTotalDecimal: orderTotalDecimal),
        order
    )
}

@available(iOS 17.0, *)
private func makePointOfSaleAggregateModel(
    entryPointController: POSEntryPointController = POSEntryPointController(eligibilityChecker: MockPOSEligibilityChecker()),
    itemsController: PointOfSaleItemsControllerProtocol = MockPointOfSaleItemsController(),
    purchasableItemsSearchController: PointOfSaleSearchingItemsControllerProtocol = MockPointOfSalePurchasableItemsSearchController(),
    couponsController: PointOfSaleCouponsControllerProtocol = MockPointOfSaleCouponsController(),
    couponsSearchController: PointOfSaleSearchingItemsControllerProtocol = MockPointOfSaleCouponsController(),
    cardPresentPaymentService: CardPresentPaymentFacade = MockCardPresentPaymentService(),
    orderController: PointOfSaleOrderControllerProtocol = MockPointOfSaleOrderController(),
    analytics: Analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider()),
    collectOrderPaymentAnalyticsTracker: POSCollectOrderPaymentAnalyticsTracking = MockPOSCollectOrderPaymentAnalyticsTracker(),
    searchHistoryService: POSSearchHistoryProviding = MockPOSSearchHistoryService(),
    popularPurchasableItemsController: PointOfSaleItemsControllerProtocol = MockPointOfSaleItemsController(),
    barcodeScanService: PointOfSaleBarcodeScanServiceProtocol = MockPointOfSaleBarcodeScanService(),
    soundPlayer: PointOfSaleSoundPlayerProtocol = MockPointOfSaleSoundPlayer(),
    paymentState: PointOfSalePaymentState = .idle
) -> PointOfSaleAggregateModel {
    PointOfSaleAggregateModel(
        entryPointController: entryPointController,
        itemsController: itemsController,
        purchasableItemsSearchController: purchasableItemsSearchController,
        couponsController: couponsController,
        couponsSearchController: couponsSearchController,
        cardPresentPaymentService: cardPresentPaymentService,
        orderController: orderController,
        analytics: analytics,
        collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker,
        searchHistoryService: searchHistoryService,
        popularPurchasableItemsController: popularPurchasableItemsController,
        barcodeScanService: barcodeScanService,
        soundPlayer: soundPlayer,
        paymentState: paymentState
    )
}
