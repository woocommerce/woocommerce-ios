import Testing
import Observation
import Foundation

@testable import WooCommerce
import struct Yosemite.Order
import struct Yosemite.OrderItem
import struct Yosemite.OrderCouponLine
import struct Yosemite.SystemPlugin
import enum Yosemite.OrderAction
import protocol Yosemite.PluginsServiceProtocol
import class WooFoundation.CurrencySettings
import protocol WooFoundation.Analytics
import enum Networking.DotcomError
import enum Networking.NetworkError
import PointOfSale

struct PointOfSaleOrderControllerTests {
    let mockOrderService = MockPOSOrderService()
    let mockReceiptService = MockReceiptService()

    @available(iOS 17.0, *)
    @Test func syncOrder_without_items_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())

        // When
        await sut.syncOrder(for: .init(), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_cart_matching_order_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder
        await sut.syncOrder(for: .init(purchasableItems: [cartItem]), retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When
        await sut.syncOrder(for: .init(purchasableItems: [cartItem]), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_already_syncing_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        mockOrderService.simulateSyncing = true
        Task {
            await sut.syncOrder(for: .init(purchasableItems: [makeItem(quantity: 1)]), retryHandler: {})
        }
        try await Task.sleep(nanoseconds: UInt64(100 * Double(NSEC_PER_MSEC)))
        mockOrderService.syncOrderWasCalled = false

        // When
        await sut.syncOrder(for: .init(purchasableItems: [makeItem(quantity: 2),
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
                                             currencySettings: currencySettings,
                                             analytics: MockPOSAnalytics())

        // When
        await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: {})

        // Then
        #expect(mockOrderService.spySyncOrderCurrency == .AUD)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_changes_from_previous_order_calls_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let cartItem = makeItem(quantity: 1)
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        let futureOrderItem = OrderItem.fake().copy(quantity: 5)

        // When
        await sut.syncOrder(for: .init(purchasableItems: [cartItem,
                                                          makeItem(quantity: 5, orderItemsToMatch: [futureOrderItem])]),
                            retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_no_previous_order_sets_orderState_syncing_then_loaded() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
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
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: {})
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
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
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
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: {})
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
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let email = "test@example.com"

        // When
        do {
            try await sut.sendReceipt(recipientEmail: email)
        } catch {
            // Then
            #expect(error as? PointOfSaleOrderController.PointOfSaleOrderControllerError == .noOrder)
            #expect(!mockOrderService.updateOrderWasCalled)
            #expect(mockReceiptService.sendReceiptWasCalled == nil)
        }
    }

    @available(iOS 17.0, *)
    @Test func sendReceipt_calls_both_updateOrder_and_sendReceipt() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let order = Order.fake()
        let recipientEmail = "test@fake.com"
        mockOrderService.orderToReturn = order

        // We need an existing order before we can update its email, and send a receipt:
        await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: { })

        // When
        try await sut.sendReceipt(recipientEmail: recipientEmail)

        // Then
        #expect(mockOrderService.updateOrderWasCalled)
        #expect(mockOrderService.orderToReturn?.billingAddress?.email == recipientEmail)
    }

    @available(iOS 17.0, *)
    @Test func collectCashPayment_when_no_order_then_fails_with_noOrder_error() async throws {
        do {
            // Given/When
            let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                                 receiptService: mockReceiptService,
                                                 currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
            try await sut.collectCashPayment(changeDueAmount: nil)
        } catch let error as PointOfSaleOrderController.PointOfSaleOrderControllerError {
            // Then
            #expect(error == .noOrder)
        }
    }

    @MainActor
    @available(iOS 17.0, *)
    @Test func collectCashPayment_when_successful_calls_celebrate() async throws {
        // Given
        let mockPaymentCelebration = MockPaymentCaptureCelebration()
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics(),
                                             celebration: mockPaymentCelebration)

        let orderItem = OrderItem.fake()
        let fakeOrder = Order.fake().copy(items: [orderItem])
        mockOrderService.orderToReturn = fakeOrder
        await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: {})

        mockOrderService.resultToReturn = .success(())

        // When
        try await sut.collectCashPayment(changeDueAmount: nil)

        // Then
        #expect(mockPaymentCelebration.celebrationWasCalled == true)
    }

    @available(iOS 17.0, *)
    @Test func collectCashPayment_passes_changeDueAmount_to_order_service() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())

        let orderItem = OrderItem.fake()
        let fakeOrder = Order.fake().copy(items: [orderItem])
        mockOrderService.orderToReturn = fakeOrder
        await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: {})

        mockOrderService.resultToReturn = .success(())

        // When
        try await sut.collectCashPayment(changeDueAmount: "$6.0")

        // Then
        #expect(mockOrderService.spyCashPaymentChangeDueAmount == "$6.0")
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_successful_returns_newOrder_result() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let fakeOrderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake()
        let fakeCartItem = makeItem(orderItemsToMatch: [fakeOrderItem])
        mockOrderService.orderToReturn = fakeOrder

        // When
        let result = await sut.syncOrder(for: .init(purchasableItems: [fakeCartItem]), retryHandler: { })

        // Then
        if case .success(let state) = result {
            #expect(state == .newOrder)
        } else {
            #expect(Bool(false), "Expected success result with new order")
        }
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_updating_existing_order_returns_newOrder_result() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let fakeOrder = Order.fake()
        mockOrderService.orderToReturn = fakeOrder

        // When
        // 1. Initial order
        _ = await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: {})

        // 2. Sync existing order
        let result = await sut.syncOrder(for: .init(purchasableItems: [makeItem(), makeItem()]), retryHandler: {})

        // Then
        if case .success(let state) = result {
            #expect(state == .newOrder)
        } else {
            #expect(Bool(false), "Expected success result with new order")
        }
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_cart_matching_order_then_returns_orderNotChanged_result() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // When
        // 1. Initial order
        _ = await sut.syncOrder(for: .init(purchasableItems: [cartItem]), retryHandler: {})

        // 2. Syncing existing order with same cart should not update order
        let result = await sut.syncOrder(for: .init(purchasableItems: [cartItem]), retryHandler: {})

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
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let cartItem = makeItem(quantity: 1)

        // When
        mockOrderService.orderToReturn = nil
        let result = await sut.syncOrder(for: .init(purchasableItems: [cartItem]), retryHandler: {})

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
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let couponCode = "SAVE10"
        let coupon = OrderCouponLine.fake().copy(code: couponCode)
        let fakeOrder = Order.fake().copy(items: [orderItem], coupons: [coupon])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync to set up the order
        await sut.syncOrder(for: .init(purchasableItems: [cartItem], coupons: [.init(id: UUID(), code: couponCode, summary: "")]), retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When - sync with same items and coupons
        await sut.syncOrder(for: .init(purchasableItems: [cartItem], coupons: [.init(id: UUID(), code: couponCode, summary: "")]), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_matching_items_but_different_coupons_calls_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let initialCouponCode = "SAVE10"
        let initialCoupon = OrderCouponLine.fake().copy(code: initialCouponCode)
        let fakeOrder = Order.fake().copy(items: [orderItem], coupons: [initialCoupon])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync
        await sut.syncOrder(for: .init(purchasableItems: [cartItem], coupons: [.init(id: UUID(), code: initialCouponCode, summary: "")]), retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When - sync with same items but different coupon
        await sut.syncOrder(for: .init(purchasableItems: [cartItem], coupons: [.init(id: UUID(), code: "DIFFERENT20", summary: "")]), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == true)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_with_matching_items_but_removed_coupon_calls_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let couponCode = "SAVE10"
        let coupon = OrderCouponLine.fake().copy(code: couponCode)
        let fakeOrder = Order.fake().copy(items: [orderItem], coupons: [coupon])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync with coupon
        await sut.syncOrder(for: .init(purchasableItems: [cartItem], coupons: [.init(id: UUID(), code: couponCode, summary: "")]), retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When - sync with same items but no coupons
        await sut.syncOrder(for: .init(purchasableItems: [cartItem], coupons: []), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == true)
    }

    @available(iOS 17.0, *)
    @Test func syncOrder_when_orderService_fails_with_couponsError_then_sets_invalidCoupon_error() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
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
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()],
                                           coupons: [.init(id: UUID(), code: "INVALID", summary: "")]),
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
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())
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
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()],
                                           coupons: [.init(id: UUID(), code: "INVALID", summary: "")]),
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
    @Test func syncOrder_when_fails_sets_order_to_nil() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptService: mockReceiptService,
                                             currencySettings: CurrencySettings(),
                                             analytics: MockPOSAnalytics())

        // First create a successful order
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync succeeds
        let initialResult = await sut.syncOrder(for: .init(purchasableItems: [cartItem]), retryHandler: {})
        switch initialResult {
        case .success(.newOrder):
            break
        default:
            #expect(Bool(false), "Expected success with new order, got \(initialResult)")
        }

        // Then simulate a failure
        mockOrderService.errorToReturn = SyncOrderStateError.syncFailure
        let failureResult = await sut.syncOrder(for: .init(purchasableItems: [cartItem, cartItem]), retryHandler: {})
        switch failureResult {
        case .failure(SyncOrderStateError.syncFailure):
            break
        default:
            #expect(Bool(false), "Expected sync failure, got \(failureResult)")
        }

        // When - try syncing with the same cart again
        mockOrderService.errorToReturn = nil
        mockOrderService.orderToReturn = fakeOrder // Restore mock to return success
        let subsequentResult = await sut.syncOrder(for: .init(purchasableItems: [cartItem]), retryHandler: {})

        // Then - should be treated as new order since previous order was cleared
        switch subsequentResult {
        case .success(.newOrder):
            break
        default:
            #expect(Bool(false), "Expected new order after failure cleared previous order, got \(subsequentResult)")
        }
    }

    @MainActor
    struct AnalyticsTests {
        private let analytics = MockPOSAnalytics()
        private let orderService = MockPOSOrderService()
        private let receiptService = MockReceiptService()

        @available(iOS 17.0, *)
        @Test func syncOrder_when_create_order_then_tracks_order_creation_success_event() async throws {
            // Given
            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptService: receiptService,
                                                 currencySettings: CurrencySettings(),
                                                 analytics: analytics)
            let fakeOrderItem = OrderItem.fake().copy(quantity: 1)
            let fakeOrder = Order.fake()
            let fakeCartItem = makeItem(orderItemsToMatch: [fakeOrderItem])
            orderService.orderToReturn = fakeOrder

            // When
            await sut.syncOrder(for: .init(purchasableItems: [fakeCartItem]), retryHandler: { })

            // Then
            #expect(analytics.events.first(where: { $0.eventName == "order_creation_success" }) != nil)
        }

        @available(iOS 17.0, *)
        @Test func syncOrder_when_create_order_fails_with_order_service_error_then_tracks_order_creation_failure_event() async throws {
            // Given
            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptService: receiptService,
                                                 currencySettings: CurrencySettings(),
                                                 analytics: analytics)
            orderService.orderToReturn = nil

            // When
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: {})

            // Then
            #expect(analytics.events.first(where: { $0.eventName == "order_creation_failed" }) != nil)
        }

        @MainActor
        @available(iOS 17.0, *)
        @Test func collectCashPayment_when_failure_tracks_correct_event() async throws {
            // Given
            let mockAnalytics = MockPOSAnalytics()

            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptService: MockReceiptService(),
                                                 currencySettings: CurrencySettings(),
                                                 analytics: mockAnalytics)

            // In order to test the order controller failure we need to succeed first in creating a successful order:
            let orderItem = OrderItem.fake()
            let fakeOrder = Order.fake().copy(items: [orderItem])
            orderService.orderToReturn = fakeOrder
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: {})

            orderService.resultToReturn = .failure(NSError(domain: "test", code: 0, userInfo: nil))

            // When
            await #expect(performing: {
                try await sut.collectCashPayment(changeDueAmount: nil)
            }, throws: { _ in
                return true
            })

            // Then
            #expect(mockAnalytics.events.first(where: { $0.eventName == "cash_payment_failed" }) != nil)
        }

        @available(iOS 17.0, *)
        @Test func sendReceipt_tracks_success_with_eligible_for_pos_receipt() async throws {
            // Given
            let mockPluginsService = MockPluginsService()
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: "10.0.0-dev",
                                                                                    active: true))

            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptService: receiptService,
                                                 currencySettings: CurrencySettings(),
                                                 analytics: analytics,
                                                 pluginsService: mockPluginsService)
            let order = Order.fake()
            orderService.orderToReturn = order

            // We need an existing order before we can send a receipt
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: { })

            // When
            try await sut.sendReceipt(recipientEmail: "test@example.com")

            // Then
            let indexOfEvent = try #require(analytics.events.firstIndex(where: { $0.eventName == "receipt_email_success" }))
            #expect(analytics.events.map(\.properties)[indexOfEvent]["eligible_for_pos_receipt"] as? Bool == true)
        }

        @available(iOS 17.0, *)
        @Test func sendReceipt_without_order_tracks_failure_without_eligible_for_pos_receipt() async throws {
            // Given
            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptService: receiptService,
                                                 currencySettings: CurrencySettings(),
                                                 analytics: analytics)

            // When
            do {
                try await sut.sendReceipt(recipientEmail: "test@example.com")
            } catch {
                // Then
                let indexOfEvent = try #require(analytics.events.firstIndex(where: { $0.eventName == "receipt_email_failed" }))
                #expect(analytics.events.map(\.properties)[indexOfEvent]["eligible_for_pos_receipt"] == nil)
            }
        }

        @available(iOS 17.0, *)
        @Test func sendReceipt_tracks_failure_with_eligible_for_pos_receipt() async throws {
            // Given
            let mockPluginsService = MockPluginsService()
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: "10.0.0-dev",
                                                                                    active: true))

            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptService: receiptService,
                                                 currencySettings: CurrencySettings(),
                                                 analytics: analytics,
                                                 pluginsService: mockPluginsService)

            receiptService.sendReceiptResult = .failure(DotcomError.unknown(code: "test_error", message: "Test error"))

            let order = Order.fake()
            orderService.orderToReturn = order

            // We need an existing order before we can send a receipt
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: { })

            // When
            do {
                try await sut.sendReceipt(recipientEmail: "test@example.com")
            } catch {
                // Then
                let indexOfEvent = try #require(analytics.events.firstIndex(where: { $0.eventName == "receipt_email_failed" }))
                #expect(analytics.events.map(\.properties)[indexOfEvent]["eligible_for_pos_receipt"] as? Bool == true)
                #expect(analytics.events.map(\.error)[indexOfEvent] != nil)
            }
        }
    }

    @MainActor
    struct ReceiptTests {
        private let mockOrderService = MockPOSOrderService()

        @available(iOS 17.0, *)
        @Test("Eligible core plugin versions with feature flag enabled", arguments: Constants.eligibleWCPluginVersions)
        func sendReceipt_when_feature_flag_enabled_and_eligible_plugin_version_sets_isEligibleForPOSReceipt_true(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockFeatureFlagService = MockFeatureFlagService()
            let mockPluginsService = MockPluginsService()
            mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = true
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))

            let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                                 receiptService: mockReceiptService,
                                                 currencySettings: CurrencySettings(),
                                                 analytics: MockPOSAnalytics(),
                                                 featureFlagService: mockFeatureFlagService,
                                                 pluginsService: mockPluginsService)
            mockOrderService.orderToReturn = Order.fake()

            // We need an existing order before we can update its email, and send a receipt:
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: { })

            // When
            try await sut.sendReceipt(recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == true)
        }

        @available(iOS 17.0, *)
        @Test(
            "All core plugin versions with feature flag disabled",
            arguments: Constants.eligibleWCPluginVersions + Constants.ineligibleWCPluginVersions
        )
        func sendReceipt_when_feature_flag_disabled_and_eligible_plugin_version_sets_isEligibleForPOSReceipt_false(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockFeatureFlagService = MockFeatureFlagService()
            let mockPluginsService = MockPluginsService()
            mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = false
            // Plugin setup is irrelevant when feature flag is disabled
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))

            let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                                 receiptService: mockReceiptService,
                                                 currencySettings: CurrencySettings(),
                                                 analytics: MockPOSAnalytics(),
                                                 featureFlagService: mockFeatureFlagService,
                                                 pluginsService: mockPluginsService)
            mockOrderService.orderToReturn = Order.fake()

            // We need an existing order before we can update its email, and send a receipt:
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: { })

            // When
            try await sut.sendReceipt(recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == false)
        }

        @available(iOS 17.0, *)
        @Test("Ineligible core plugin versions with feature flag enabled", arguments: Constants.ineligibleWCPluginVersions)
        func sendReceipt_when_feature_flag_enabled_and_ineligible_plugin_version_sets_isEligibleForPOSReceipt_false(wcPluginVersion: String) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockFeatureFlagService = MockFeatureFlagService()
            let mockPluginsService = MockPluginsService()
            mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = true
            mockPluginsService.setMockPlugin(.wooCommerce,
                                             systemPlugin: SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                                                                    version: wcPluginVersion,
                                                                                    active: true))

            let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                                 receiptService: mockReceiptService,
                                                 currencySettings: CurrencySettings(),
                                                 analytics: MockPOSAnalytics(),
                                                 featureFlagService: mockFeatureFlagService,
                                                 pluginsService: mockPluginsService)
            mockOrderService.orderToReturn = Order.fake()

            // We need an existing order before we can update its email, and send a receipt:
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: { })

            // When
            try await sut.sendReceipt(recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == false)
        }

        @available(iOS 17.0, *)
        @Test("Unavailable core plugin with feature flag enabled",
              arguments: [
                SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", active: false),
                nil
              ])
        func sendReceipt_when_feature_flag_enabled_and_plugin_unavailable_sets_isEligibleForPOSReceipt_false(plugin: SystemPlugin?) async throws {
            // Given
            let mockReceiptService = MockReceiptService()
            let mockFeatureFlagService = MockFeatureFlagService()
            let mockPluginsService = MockPluginsService()
            mockFeatureFlagService.isFeatureFlagEnabledReturnValue[.pointOfSaleReceipts] = true
            mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)

            let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                                 receiptService: mockReceiptService,
                                                 currencySettings: CurrencySettings(),
                                                 analytics: MockPOSAnalytics(),
                                                 featureFlagService: mockFeatureFlagService,
                                                 pluginsService: mockPluginsService)
            mockOrderService.orderToReturn = Order.fake()

            // We need an existing order before we can update its email, and send a receipt:
            await sut.syncOrder(for: .init(purchasableItems: [makeItem()]), retryHandler: { })

            // When
            try await sut.sendReceipt(recipientEmail: "test@example.com")

            // Then
            #expect(mockReceiptService.sendReceiptWasCalled == true)
            #expect(mockReceiptService.spyIsEligibleForPOSReceipt == false)
        }

        private enum Constants {
            static let eligibleWCPluginVersions = ["10.0.0", "10.0.0-dev", "10.0.0-beta", "10.0.1", "10.1"]
            static let ineligibleWCPluginVersions = ["9.9.0", "9.9.9", "9.9.9-beta.9", "9.9.9-dev"]
        }
    }
}

private func makeItem(name: String = "",
                      formattedPrice: String = "",
                      quantity: Int = 1,
                      orderItemsToMatch: [OrderItem] = []) -> Cart.PurchasableItem {
    return .init(id: UUID(),
                 item: MockPOSOrderableItem(name: name,
                                            formattedPrice: formattedPrice,
                                            orderItemsToMatch: orderItemsToMatch),
                 title: name,
                 subtitle: nil,
                 quantity: quantity)
}
