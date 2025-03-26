import Testing
import Observation
import Foundation

@testable import WooCommerce
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.OrderCouponLine
import enum Yosemite.OrderAction
import class WooFoundation.CurrencySettings
import protocol WooFoundation.Analytics
import enum Networking.DotcomError
import enum Networking.NetworkError

struct PointOfSaleOrderControllerTests {
    let mockOrderService = MockPOSOrderService()
    let mockReceiptService = MockReceiptService()

    @available(iOS 17.0, *)
    @Test func syncOrder_without_items_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)

        // When
        await sut.syncOrder(for: .init(), retryHandler: {})

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
        await sut.syncOrder(for: .init(items: [cartItem]), retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When
        await sut.syncOrder(for: .init(items: [cartItem]), retryHandler: {})

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
            await sut.syncOrder(for: .init(items: [makeItem(quantity: 1)]), retryHandler: {})
        }
        try await Task.sleep(nanoseconds: UInt64(100 * Double(NSEC_PER_MSEC)))
        mockOrderService.syncOrderWasCalled = false

        // When
        await sut.syncOrder(for: .init(items: [makeItem(quantity: 2),
                                               makeItem(quantity: 5)]),
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
        await sut.syncOrder(for: .init(items: [makeItem()]), retryHandler: {})

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
        await sut.syncOrder(for: .init(items: [cartItem,
                                               makeItem(quantity: 5, orderItemsToMatch: [futureOrderItem])]),
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
            await sut.syncOrder(for: .init(items: [makeItem()]), retryHandler: {})
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
            await sut.syncOrder(for: .init(items: [makeItem()]), retryHandler: {})
        }

        await orderStateAppendTask?.value

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .error(.other(MockPOSOrderServiceError.noOrderToReturn.localizedDescription), {})
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
        await sut.syncOrder(for: .init(items: [makeItem()]), retryHandler: { })

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
        await sut.syncOrder(for: .init(items: [makeItem()]), retryHandler: {})

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

    @available(iOS 17.0, *)
    @Test func syncOrder_when_successful_returns_newOrder_result() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let fakeOrderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake()
        let fakeCartItem = makeItem(orderItemsToMatch: [fakeOrderItem])
        mockOrderService.orderToReturn = fakeOrder

        // When
        let result = await sut.syncOrder(for: .init(items: [fakeCartItem]), retryHandler: { })

        // Then
        if case .success(let state) = result {
            #expect(state == .newOrder)
        } else {
            #expect(Bool(false), "Expected success result with new order")
        }
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_updating_existing_order_returns_orderUpdated_result() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let fakeOrderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake()
        mockOrderService.orderToReturn = fakeOrder

        // When
        // 1. Initial order
        _ = await sut.syncOrder(for: .init(items: [makeItem()]), retryHandler: {})

        // 2. Sync existing order
        let result = await sut.syncOrder(for: .init(items: [makeItem(), makeItem()]), retryHandler: {})

        // Then
        if case .success(let state) = result {
            #expect(state == .orderUpdated)
        } else {
            #expect(Bool(false), "Expected success result with order updated")
        }
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_cart_matching_order_then_returns_orderNotChanged_result() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // When
        // 1. Initial order
        _ = await sut.syncOrder(for: .init(items: [cartItem]), retryHandler: {})

        // 2. Syncing existing order with same cart should not update order
        let result = await sut.syncOrder(for: .init(items: [cartItem]), retryHandler: {})

        // Then
        if case .success(let state) = result {
            #expect(state == .orderNotChanged)
        } else {
            #expect(Bool(false), "Expected success result with no changes to existing order")
        }
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_orderService_fails_then_returns_syncOrderState_failure() async throws {
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let cartItem = makeItem(quantity: 1)

        // When
        mockOrderService.orderToReturn = nil
        let result = await sut.syncOrder(for: .init(items: [cartItem]), retryHandler: {})

        // Then
        if case .failure(let error) = result {
            #expect(error as? SyncOrderStateError == .syncFailure)
        } else {
            #expect(Bool(false), "Expected sync failure but got \(result)")
        }
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_cart_matching_order_and_coupons_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let couponCode = "SAVE10"
        let coupon = OrderCouponLine.fake().copy(code: couponCode)
        let fakeOrder = Order.fake().copy(items: [orderItem], coupons: [coupon])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync to set up the order
        await sut.syncOrder(for: .init(items: [cartItem], coupons: [.init(id: UUID(), code: couponCode)]), retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When - sync with same items and coupons
        await sut.syncOrder(for: .init(items: [cartItem], coupons: [.init(id: UUID(), code: couponCode)]), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_matching_items_but_different_coupons_calls_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let initialCouponCode = "SAVE10"
        let initialCoupon = OrderCouponLine.fake().copy(code: initialCouponCode)
        let fakeOrder = Order.fake().copy(items: [orderItem], coupons: [initialCoupon])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync
        await sut.syncOrder(for: .init(items: [cartItem], coupons: [.init(id: UUID(), code: initialCouponCode)]), retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When - sync with same items but different coupon
        await sut.syncOrder(for: .init(items: [cartItem], coupons: [.init(id: UUID(), code: "DIFFERENT20")]), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == true)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_matching_items_but_removed_coupon_calls_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService)
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let couponCode = "SAVE10"
        let coupon = OrderCouponLine.fake().copy(code: couponCode)
        let fakeOrder = Order.fake().copy(items: [orderItem], coupons: [coupon])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync with coupon
        await sut.syncOrder(for: .init(items: [cartItem], coupons: [.init(id: UUID(), code: couponCode)]), retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When - sync with same items but no coupons
        await sut.syncOrder(for: .init(items: [cartItem], coupons: []), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == true)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_orderService_fails_with_couponsError_then_sets_invalidCoupon_error() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                           receiptService: mockReceiptService)
        let errorMessage = "Invalid coupon code"
        mockOrderService.errorToReturn = DotcomError.unknown(code: "woocommerce_rest_invalid_coupon", message: errorMessage)

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
            await sut.syncOrder(for: .init(items: [makeItem()],
                                         coupons: [.init(id: UUID(), code: "INVALID")]),
                              retryHandler: {})
        }

        await orderStateAppendTask?.value

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .error(.invalidCoupon(errorMessage), {})
        ])
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_orderService_fails_with_networkError_containing_couponsError_then_sets_invalidCoupon_error() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                           receiptService: mockReceiptService)
        let errorMessage = "Coupon INVALID does not exist"
        let errorJSON = """
        {
            "code": "woocommerce_rest_invalid_coupon",
            "message": "\(errorMessage)"
        }
        """
        let errorData = errorJSON.data(using: .utf8)!
        mockOrderService.errorToReturn = NetworkError.unacceptableStatusCode(statusCode: 400, response: errorData)

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
            await sut.syncOrder(for: .init(items: [makeItem()],
                                         coupons: [.init(id: UUID(), code: "INVALID")]),
                              retryHandler: {})
        }

        await orderStateAppendTask?.value

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .error(.invalidCoupon(errorMessage), {})
        ])
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
            await sut.syncOrder(for: .init(items: [fakeCartItem]), retryHandler: { })

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
            await sut.syncOrder(for: .init(items: [makeItem()]), retryHandler: {})

            // Then
            #expect(analyticsProvider.receivedEvents.first(where: { $0 == "order_creation_failed" }) != nil)
        }

        @MainActor
        @available(iOS 17.0, *)
        @Test func collectCashPayment_when_failure_tracks_correct_event() async throws {
            // Given
            // In order to test the order controller failure we need to succeed first in both having a site and creating a successful order
            // which requires quite a bit of setup:
            let sampleSiteID: Int64 = 1234
            let mockStores = MockStoresManager(sessionManager: .testingInstance)
            mockStores.sessionManager.setStoreId(sampleSiteID)

            let mockOrderService = MockPOSOrderService()
            let mockAnalyticsProvider = MockAnalyticsProvider()
            let mockAnalytics = WooAnalytics(analyticsProvider: mockAnalyticsProvider)

            let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                                 receiptService: MockReceiptService(),
                                                 stores: mockStores,
                                                 analytics: mockAnalytics)

            let orderItem = OrderItem.fake()
            let fakeOrder = Order.fake().copy(items: [orderItem])
            mockOrderService.orderToReturn = fakeOrder
            await sut.syncOrder(for: .init(items: [makeItem()]), retryHandler: {})

            // When
            await withCheckedContinuation { continuation in
                mockStores.whenReceivingAction(ofType: OrderAction.self) { action in
                    switch action {
                    case let .updateOrder(_, _, _, _, onCompletion):
                        onCompletion(.failure(NSError(domain: "oops", code: -1)))
                        continuation.resume()
                    default:
                        #expect(Bool(false), "Unexpected action \(action)")
                    }
                }
                Task { @MainActor in
                    try await sut.collectCashPayment()
                }
            }

            // Then
            #expect(mockAnalyticsProvider.receivedEvents.first(where: { $0 == "cash_payment_failed" }) != nil)
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
