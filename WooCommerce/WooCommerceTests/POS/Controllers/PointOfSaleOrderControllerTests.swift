import Testing
import Observation
import Foundation

@testable import WooCommerce
import struct Yosemite.Order
import struct Yosemite.OrderItem
import enum Yosemite.OrderAction
import class WooFoundation.CurrencySettings
import protocol WooFoundation.Analytics

struct PointOfSaleOrderControllerTests {
    let mockOrderService = MockPOSOrderService()
    let mockReceiptService = MockReceiptService()

    @available(iOS 17.0, *)
    @Test func syncOrder_without_items_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)

        // When
        await sut.syncOrder(for: [], retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_cart_matching_order_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder
        await sut.syncOrder(for: [cartItem], retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When
        await sut.syncOrder(for: [cartItem], retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_already_syncing_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        mockOrderService.simulateSyncing = true
        Task {
            await sut.syncOrder(for: [makeItem(quantity: 1)], retryHandler: {})
        }
        try await Task.sleep(nanoseconds: UInt64(100 * Double(NSEC_PER_MSEC)))
        mockOrderService.syncOrderWasCalled = false

        // When
        await sut.syncOrder(for: [makeItem(quantity: 2),
                                  makeItem(quantity: 5)],
                            retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_no_previous_order_calls_orderService() async throws {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .AUD,
                                                currencyPosition: .left,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: currencySettings)

        // When
        await sut.syncOrder(for: [makeItem()], retryHandler: {})

        // Then
        #expect(mockOrderService.spySyncOrderCurrency == .AUD)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_changes_from_previous_order_calls_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let cartItem = makeItem(quantity: 1)
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        let futureOrderItem = OrderItem.fake().copy(quantity: 5)

        // When
        await sut.syncOrder(for: [cartItem,
                                  makeItem(quantity: 5, orderItemsToMatch: [futureOrderItem])],
                            retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_no_previous_order_sets_orderState_syncing_then_loaded() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let fakeOrder = Order.fake()
        mockOrderService.orderToReturn = fakeOrder
        var orderStates: [PointOfSaleInternalOrderState] = [sut.orderState]
        var orderStateAppendTask: Task<Void, Never>? = nil
        await confirmation(expectedCount: 2) { confirmation in
            @Sendable func observeOrderState() {
                withObservationTracking {
                    _ = sut.orderState
                } onChange: {
                    orderStateAppendTask = Task { @MainActor in
                        orderStates.append(sut.orderState)
                    }
                    confirmation()
                    observeOrderState()
                }
            }
            observeOrderState()

            // When
            await sut.syncOrder(for: [makeItem()], retryHandler: {})
        }

        await orderStateAppendTask?.value

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .loaded(.init(cartTotal: "$0.00", orderTotal: "", taxTotal: "", orderTotalDecimal: 0.0),
                    fakeOrder)
        ])
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_order_sync_failure_sets_orderState_syncing_then_error() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        mockOrderService.orderToReturn = nil

        var orderStates: [PointOfSaleInternalOrderState] = [sut.orderState]
        var orderStateAppendTask: Task<Void, Never>? = nil
        await confirmation(expectedCount: 2) { confirmation in
            @Sendable func observeOrderState() {
                withObservationTracking {
                    _ = sut.orderState
                } onChange: {
                    orderStateAppendTask = Task { @MainActor in
                        orderStates.append(sut.orderState)
                    }
                    confirmation()
                    observeOrderState()
                }
            }
            observeOrderState()

            // When
            await sut.syncOrder(for: [makeItem()], retryHandler: {})
        }

        await orderStateAppendTask?.value

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .error(.init(
                message: MockPOSOrderServiceError.noOrderToReturn.localizedDescription,
                handler: {}))
        ])
    }

    @available(iOS 17.0, *)
    @Test func sendReceipt_when_there_is_no_order_then_will_not_trigger() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let email = "test@example.com"

        // When
        try await sut.sendReceipt(recipientEmail: email)

        // Then
        #expect(!mockOrderService.updateOrderWasCalled)
        #expect(!mockReceiptService.sendReceiptWasCalled)
    }

    @available(iOS 17.0, *)
    @Test func sendReceipt_calls_both_updateOrder_and_sendReceipt() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let order = Order.fake()
        let recipientEmail = "test@fake.com"
        mockOrderService.orderToReturn = order

        // We need an existing order before we can update its email, and send a receipt:
        await sut.syncOrder(for: [makeItem()], retryHandler: { })

        // When
        try await sut.sendReceipt(recipientEmail: recipientEmail)

        // Then
        #expect(mockOrderService.updateOrderWasCalled)
        #expect(mockOrderService.orderToReturn?.billingAddress?.email == recipientEmail)
        #expect(mockReceiptService.sendReceiptWasCalled)
    }

    @available(iOS 17.0, *)
    @Test func collectCashPayment_when_no_order_then_fails_with_noOrder_error() async throws {
        do {
            // Given/When
            let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                                 receiptService: mockReceiptService)
            try await sut.collectCashPayment()
        } catch let error as PointOfSaleOrderController.PointOfSaleOrderControllerError {
            // Then
            #expect(error == .noOrder)
        }
    }

    @MainActor
    @available(iOS 17.0, *)
    @Test func collectCashPayment_when_successful_calls_celebrate() async throws {
        // Given
        let sampleSiteID: Int64 = 1234
        let mockStores = MockStoresManager(sessionManager: .testingInstance)
        mockStores.sessionManager.setStoreId(sampleSiteID)
        let mockPaymentCelebration = MockPaymentCaptureCelebration()
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             stores: mockStores,
                                             celebration: mockPaymentCelebration)

        let orderItem = OrderItem.fake()
        let fakeOrder = Order.fake().copy(items: [orderItem])
        mockOrderService.orderToReturn = fakeOrder
        await sut.syncOrder(for: [makeItem()], retryHandler: {})

        // When
        let completionResult: Bool = await withCheckedContinuation { continuation in
            mockStores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .updateOrder(_, order, _, _, onCompletion):
                    onCompletion(.success(order))
                    continuation.resume(returning: true)
                default:
                    #expect(Bool(false), "Unexpected action \(action)")
                }
            }
            Task { @MainActor in
                do {
                    try await sut.collectCashPayment()
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }

        // Then
        #expect(completionResult == true)
        #expect(mockPaymentCelebration.celebrationWasCalled == true)
    }

    struct AnalyticsTests {
        private let analytics: WooAnalytics
        private let analyticsProvider = MockAnalyticsProvider()
        private let orderService = MockPOSOrderService()
        private let receiptService = MockReceiptService()

        init() {
            analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        }

        @available(iOS 17.0, *)
        @Test func syncOrder_when_create_order_then_tracks_order_creation_success_event() async throws {
            // Given
            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptService: receiptService,
                                                 analytics: analytics)
            let fakeOrderItem = OrderItem.fake().copy(quantity: 1)
            let fakeOrder = Order.fake()
            let fakeCartItem = makeItem(orderItemsToMatch: [fakeOrderItem])
            orderService.orderToReturn = fakeOrder

            // When
            await sut.syncOrder(for: [fakeCartItem], retryHandler: { })

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "order_creation_success" }) != nil)
        }

        @available(iOS 17.0, *)
        @Test func syncOrder_when_create_order_fails_with_order_service_error_then_tracks_order_creation_failure_event() async throws {
            // Given
            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptService: receiptService,
                                                 analytics: analytics)
            orderService.orderToReturn = nil

            // When
            await sut.syncOrder(for: [makeItem()], retryHandler: {})

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "order_creation_failed" }) != nil)
        }
    }
}

private func makeItem(name: String = "",
                      formattedPrice: String = "",
                      quantity: Int = 1,
                      orderItemsToMatch: [OrderItem] = []) -> CartItem {
    return CartItem(id: UUID(),
                    item: MockPOSOrderableItem(name: name,
                                               formattedPrice: formattedPrice,
                                               orderItemsToMatch: orderItemsToMatch),
                    title: name,
                    subtitle: nil,
                    quantity: quantity)
}
