import Testing
@testable import PointOfSale
import enum Yosemite.POSItem
import struct Yosemite.POSItemIdentifier
@testable import struct Yosemite.POSSimpleProduct
import struct Yosemite.Order
import struct Yosemite.OrderItem

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct PointOfSaleCheckoutNavigationTests {
    private let orderService = MockPOSOrderService()
    private let cardPresentPaymentService = MockCardPresentPaymentService()
    private let analyticsTracker = MockPOSCollectOrderPaymentAnalyticsTracker()
    private let orderController: PointOfSaleOrderController
    private let reader = CardPresentPaymentCardReader(name: "Reader", batteryLevel: 0.5)

    init() {
        orderController = PointOfSaleOrderController(orderService: orderService,
                                                     receiptSender: MockPOSReceiptSender(),
                                                     currencySettingsProvider: MockCurrencySettingsProvider(),
                                                     analytics: MockPOSAnalytics())
        cardPresentPaymentService.collectPaymentOverride = { .cancellation }
    }

    @Test func test_checkOut_when_cart_is_edited_while_previous_order_syncs_then_collects_payment_for_new_order() async throws {
        // Given
        let staleOrder = makeOrder(orderID: 1)
        let currentOrder = makeOrder(orderID: 2)
        let sut = makeSUT()
        sut.addToCart(makeItem(productID: 1))
        orderService.onSyncOrderCalled = { [orderService] in
            guard orderService.syncOrderCallCount == 1 else {
                orderService.orderToReturn = currentOrder
                return
            }
            sut.addMoreToCart()
            sut.addToCart(makeItem(productID: 2))
            await sut.checkOut()
            orderService.orderToReturn = staleOrder
        }

        // When
        await sut.checkOut()
        await fireOnce { fire in
            cardPresentPaymentService.onCollectPaymentCalled = { fire() }
            cardPresentPaymentService.connectedReader = reader
        }

        // Then
        #expect(orderService.syncOrderCallCount == 2)
        #expect(cardPresentPaymentService.spyCollectPaymentOrders.map(\.orderID) == [currentOrder.orderID])
        #expect(orderController.orderState.order?.orderID == currentOrder.orderID)
    }

    @Test func test_checkOut_when_same_cart_is_checked_out_again_while_order_syncs_then_creates_one_order_and_collects_it() async throws {
        // Given
        let order = makeOrder(orderID: 1)
        let sut = makeSUT()
        sut.addToCart(makeItem(productID: 1))
        orderService.orderToReturn = order
        var repeatedCheckout: Task<Void, Never>?
        orderService.onSyncOrderCalled = { [orderService] in
            orderService.onSyncOrderCalled = nil
            sut.addMoreToCart()
            repeatedCheckout = Task { await sut.checkOut() }
            await Task.yield()
        }

        // When
        await sut.checkOut()
        await repeatedCheckout?.value
        await fireOnce { fire in
            cardPresentPaymentService.onCollectPaymentCalled = { fire() }
            cardPresentPaymentService.connectedReader = reader
        }

        // Then
        #expect(orderService.syncOrderCallCount == 1)
        #expect(cardPresentPaymentService.spyCollectPaymentOrders.map(\.orderID) == [order.orderID])
        #expect(sut.orderStage == .finalizing)
    }

    @Test func test_addMoreToCart_when_order_is_syncing_then_does_not_start_payment_after_sync() async throws {
        // Given
        let sut = makeSUT()
        sut.addToCart(makeItem(productID: 1))
        orderService.orderToReturn = makeOrder(orderID: 1)
        cardPresentPaymentService.connectedReader = reader
        orderService.onSyncOrderCalled = {
            sut.addMoreToCart()
        }

        // When
        await sut.checkOut()

        // Then
        #expect(sut.orderStage == .building)
        #expect(cardPresentPaymentService.collectPaymentWasCalled == false)
        #expect(sut.paymentState.card == .idle)
    }

    @Test func test_pointOfSaleClosed_when_order_is_syncing_then_does_not_start_payment_after_sync() async throws {
        // Given
        let sut = makeSUT()
        sut.addToCart(makeItem(productID: 1))
        orderService.orderToReturn = makeOrder(orderID: 1)
        cardPresentPaymentService.connectedReader = reader
        orderService.onSyncOrderCalled = {
            sut.pointOfSaleClosed()
        }

        // When
        await sut.checkOut()

        // Then
        #expect(cardPresentPaymentService.collectPaymentWasCalled == false)
        #expect(sut.paymentModel.isActive == false)
        #expect(orderController.orderState == .idle)
    }

    @Test func test_addMoreToCart_when_stale_payment_is_being_cancelled_before_collection_then_does_not_collect() async throws {
        // Given
        let sut = makeSUT()
        sut.addToCart(makeItem(productID: 1))
        orderService.orderToReturn = makeOrder(orderID: 1)
        cardPresentPaymentService.connectedReader = reader
        cardPresentPaymentService.onCancelPaymentCalled = { [cardPresentPaymentService] in
            cardPresentPaymentService.onCancelPaymentCalled = nil
            sut.addMoreToCart()
        }

        // When
        await sut.checkOut()

        // Then
        #expect(sut.orderStage == .building)
        #expect(cardPresentPaymentService.collectPaymentWasCalled == false)
    }

    @Test(arguments: CheckoutNavigationPaymentStep.allCases)
    func test_addMoreToCart_when_payment_is_being_prepared_then_cancels_it_and_ignores_its_late_events(
        _ step: CheckoutNavigationPaymentStep
    ) async throws {
        // Given
        let sut = makeSUT()
        sut.addToCart(makeItem(productID: 1))
        orderService.orderToReturn = makeOrder(orderID: 1)
        cardPresentPaymentService.connectedReader = reader
        await sut.checkOut()
        cardPresentPaymentService.paymentEvent = .show(eventDetails: step.event)
        try #require(sut.paymentState.card == step.cardPaymentState)
        let cancelCountBeforeBack = cardPresentPaymentService.cancelPaymentCallCount

        // When
        sut.addMoreToCart()
        cardPresentPaymentService.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(inputMethods: [], cancelPayment: {}))
        cardPresentPaymentService.paymentEvent = .show(eventDetails: .paymentError(error: TestError(),
                                                                                    retryApproach: .dontRetry,
                                                                                    cancelPayment: {}))

        // Then
        #expect(cardPresentPaymentService.cancelPaymentCallCount > cancelCountBeforeBack)
        #expect(sut.orderStage == .building)
        #expect(sut.paymentState.card == .idle)
        #expect(sut.cardPresentPaymentInlineMessage == nil)
        #expect(analyticsTracker.trackCardReaderReadyCallCount == 0)
    }

    @Test func test_checkOut_when_merchant_goes_back_repeatedly_during_payment_preparation_then_last_checkout_owns_payment() async throws {
        // Given
        let iterations = 25
        let sut = makeSUT()
        sut.addToCart(makeItem(productID: 1))
        orderService.orderToReturn = makeOrder(orderID: 1)
        cardPresentPaymentService.connectedReader = reader

        // When
        for iteration in 0..<iterations {
            await sut.checkOut()
            let step: CheckoutNavigationPaymentStep = iteration.isMultiple(of: 2) ? .validatingOrder : .preparingReader
            cardPresentPaymentService.paymentEvent = .show(eventDetails: step.event)
            sut.addMoreToCart()
        }
        await sut.checkOut()
        cardPresentPaymentService.paymentEvent = .show(eventDetails: .tapSwipeOrInsertCard(inputMethods: [], cancelPayment: {}))

        // Then
        #expect(cardPresentPaymentService.spyCollectPaymentOrders.count == iterations + 1)
        #expect(cardPresentPaymentService.cancelPaymentCallCount >= iterations)
        #expect(sut.orderStage == .finalizing)
        #expect(sut.paymentState.card == .acceptingCard)
        #expect(analyticsTracker.trackCardReaderReadyCallCount == 1)
    }

    @Test func test_checkOut_when_merchant_goes_back_repeatedly_during_order_sync_then_syncs_each_cart_and_pays_latest() async throws {
        // Given
        let iterations = 10
        let sut = makeSUT()
        sut.addToCart(makeItem(productID: 1))
        orderService.onSyncOrderCalled = { [orderService] in
            let syncNumber = orderService.syncOrderCallCount
            orderService.orderToReturn = makeOrder(orderID: Int64(syncNumber))
            guard syncNumber <= iterations else {
                return
            }
            sut.addMoreToCart()
            sut.addToCart(makeItem(productID: Int64(syncNumber + 1)))
            await sut.checkOut()
            orderService.orderToReturn = makeOrder(orderID: Int64(syncNumber))
        }

        // When
        await sut.checkOut()
        await fireOnce { fire in
            cardPresentPaymentService.onCollectPaymentCalled = { fire() }
            cardPresentPaymentService.connectedReader = reader
        }

        // Then
        let latestOrderID = Int64(iterations + 1)
        #expect(orderService.syncOrderCallCount == iterations + 1)
        #expect(cardPresentPaymentService.spyCollectPaymentOrders.map(\.orderID) == [latestOrderID])
        #expect(orderController.orderState.order?.orderID == latestOrderID)
        #expect(sut.cart.purchasableItems.count == iterations + 1)
    }
}

enum CheckoutNavigationPaymentStep: CaseIterable, Sendable {
    case validatingOrder
    case preparingReader

    var event: CardPresentPaymentEventDetails {
        switch self {
        case .validatingOrder:
            return .validatingOrder(cancelPayment: {})
        case .preparingReader:
            return .preparingForPayment(cancelPayment: {})
        }
    }

    var cardPaymentState: PointOfSaleCardPaymentState {
        switch self {
        case .validatingOrder:
            return .validatingOrder
        case .preparingReader:
            return .preparingReader
        }
    }
}

private extension PointOfSaleCheckoutNavigationTests {
    struct TestError: Error {}

    func makeSUT() -> PointOfSaleAggregateModel {
        PointOfSaleAggregateModel(
            entryPointController: POSEntryPointController(eligibilityChecker: MockPOSEligibilityChecker()),
            itemsController: MockPointOfSaleItemsController(),
            purchasableItemsSearchController: MockPointOfSalePurchasableItemsSearchController(),
            couponsController: MockPointOfSaleCouponsController(),
            couponsSearchController: MockPointOfSaleCouponsController(),
            cardPresentPaymentService: cardPresentPaymentService,
            orderController: orderController,
            settingsController: MockPOSSettingsController(),
            analytics: MockPOSAnalytics(),
            collectOrderPaymentAnalyticsTracker: analyticsTracker,
            searchHistoryService: MockPOSSearchHistoryService(),
            popularPurchasableItemsController: MockPointOfSaleItemsController(),
            barcodeScanService: MockPointOfSaleBarcodeScanService(),
            receiptSender: MockPOSReceiptSender(),
            soundPlayer: MockPointOfSaleSoundPlayer(),
            siteID: 123
        )
    }
}

private func makeItem(productID: Int64) -> POSItem {
    .simpleProduct(POSSimpleProduct(id: POSItemIdentifier(underlyingType: .product, itemID: productID),
                                    name: "Product \(productID)",
                                    formattedPrice: "$10.00",
                                    productID: productID,
                                    price: "10.00",
                                    manageStock: false,
                                    stockQuantity: nil,
                                    stockStatusKey: ""))
}

private func makeOrder(orderID: Int64) -> Order {
    Order.fake().copy(orderID: orderID,
                      total: "10.00",
                      items: [OrderItem.fake().copy(itemID: orderID, quantity: 1, subtotal: "10.00", total: "10.00")])
}
