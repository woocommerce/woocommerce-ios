import Testing
import Observation
import Foundation

@testable import PointOfSale
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
import struct Yosemite.POSItemIdentifier
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation

struct PointOfSaleOrderControllerTests {
    let mockOrderService = MockPOSOrderService()
    let mockReceiptSender = MockPOSReceiptSender()

    @Test func syncOrder_without_items_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())

        // When
        await sut.syncOrder(for: Cart(), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @Test func syncOrder_with_cart_matching_order_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder
        await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})

        mockOrderService.syncOrderWasCalled = false

        // When
        await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @Test @MainActor func syncOrder_when_already_syncing_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())

        // Block the sync so it doesn't complete until we manually resume it
        mockOrderService.blockNextSync()

        // Start the first sync in a detached task so it runs concurrently
        let firstSyncTask = Task.detached {
            await sut.syncOrder(for: Cart(purchasableItems: [makeItem(quantity: 1)]), retryHandler: {})
        }

        // Wait for the order state to actually become syncing
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            @Sendable func observeOrderState() {
                withObservationTracking {
                    _ = sut.orderState
                } onChange: {
                    Task { @MainActor in
                        if sut.orderState.isSyncing {
                            continuation.resume()
                        } else {
                            observeOrderState()
                        }
                    }
                }
            }
            observeOrderState()
        }

        // Verify the state is actually syncing
        #expect(sut.orderState.isSyncing == true)
        #expect(mockOrderService.syncOrderWasCalled == true)

        // Reset the flag after confirming the sync has started
        mockOrderService.syncOrderWasCalled = false

        // When - try to sync while the first sync is still in progress
        await sut.syncOrder(for: Cart(purchasableItems: [makeItem(quantity: 2),
                                                          makeItem(quantity: 5)]),
                            retryHandler: {})

        // Then - the second sync should have been skipped
        #expect(mockOrderService.syncOrderWasCalled == false)

        // Cleanup - allow the first sync to complete
        mockOrderService.resumeBlockedSync()
        _ = await firstSyncTask.result
    }

    @Test func syncOrder_with_no_previous_order_calls_orderService() async throws {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .AUD,
                                                currencyPosition: .left,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(currencySettings: currencySettings),
                                             analytics: MockPOSAnalytics())

        // When
        await sut.syncOrder(for: Cart(purchasableItems: [makeItem()]), retryHandler: {})

        // Then
        #expect(mockOrderService.spySyncOrderCurrency == .AUD)
    }

    @Test func syncOrder_with_changes_from_previous_order_calls_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let cartItem = makeItem(quantity: 1)
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        let futureOrderItem = OrderItem.fake().copy(quantity: 5)

        // When
        await sut.syncOrder(for: Cart(purchasableItems: [cartItem,
                                                          makeItem(quantity: 5, orderItemsToMatch: [futureOrderItem])]),
                            retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled)
    }

    @Test func syncOrder_with_no_previous_order_sets_orderState_syncing_then_loaded() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
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
            await sut.syncOrder(for: Cart(purchasableItems: [makeItem()]), retryHandler: {})
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

    @Test func syncOrder_with_order_sync_failure_sets_orderState_syncing_then_error() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
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
            await sut.syncOrder(for: Cart(purchasableItems: [makeItem()]), retryHandler: {})
        }

        await orderStateAppendTask?.value

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .error(.other(MockPOSOrderServiceError.noOrderToReturn.localizedDescription), {})
        ])
    }

    @Test func sendReceipt_when_there_is_no_order_then_throws_noOrder_error() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let email = "test@example.com"

        // When
        do {
            try await sut.sendReceipt(recipientEmail: email)
        } catch {
            // Then
            #expect(error as? PointOfSaleOrderController.PointOfSaleOrderControllerError == .noOrder)
            #expect(!mockReceiptSender.sendReceiptWasCalled)
        }
    }

    @Test func sendReceipt_with_order_delegates_to_receiptSender() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let order = Order.fake()
        let recipientEmail = "test@fake.com"
        mockOrderService.orderToReturn = order

        // We need an existing order before we can send a receipt:
        await sut.syncOrder(for: Cart(purchasableItems: [makeItem()]), retryHandler: { })

        // When
        try await sut.sendReceipt(recipientEmail: recipientEmail)

        // Then
        #expect(mockReceiptSender.sendReceiptWasCalled)
        #expect(mockReceiptSender.sendReceiptCalledWithOrderID == order.orderID)
        #expect(mockReceiptSender.sendReceiptCalledWithEmail == recipientEmail)
    }

    @Test func collectCashPayment_when_no_order_then_fails_with_noOrder_error() async throws {
        do {
            // Given/When
            let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                                 receiptSender: mockReceiptSender,
                                                 currencySettingsProvider: MockCurrencySettingsProvider(),
                                                 analytics: MockPOSAnalytics())
            try await sut.collectCashPayment(changeDueAmount: nil)
        } catch let error as PointOfSaleOrderController.PointOfSaleOrderControllerError {
            // Then
            #expect(error == .noOrder)
        }
    }

    @Test func collectCashPayment_passes_changeDueAmount_to_order_service() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())

        let orderItem = OrderItem.fake()
        let fakeOrder = Order.fake().copy(items: [orderItem])
        mockOrderService.orderToReturn = fakeOrder
        await sut.syncOrder(for: Cart(purchasableItems: [makeItem()]), retryHandler: {})

        mockOrderService.resultToReturn = .success(())

        // When
        try await sut.collectCashPayment(changeDueAmount: "$6.0")

        // Then
        #expect(mockOrderService.spyCashPaymentChangeDueAmount == "$6.0")
    }

    @Test func syncOrder_when_successful_returns_newOrder_result() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let fakeOrderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake()
        let fakeCartItem = makeItem(orderItemsToMatch: [fakeOrderItem])
        mockOrderService.orderToReturn = fakeOrder

        // When
        let result = await sut.syncOrder(for: Cart(purchasableItems: [fakeCartItem]), retryHandler: { })

        // Then
        if case .success(let state) = result {
            #expect(state == .newOrder)
        } else {
            #expect(Bool(false), "Expected success result with new order")
        }
    }

    @Test func syncOrder_when_updating_existing_order_returns_newOrder_result() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let fakeOrder = Order.fake()
        mockOrderService.orderToReturn = fakeOrder

        // When
        // 1. Initial order
        _ = await sut.syncOrder(for: Cart(purchasableItems: [makeItem()]), retryHandler: {})

        // 2. Sync existing order
        let result = await sut.syncOrder(for: Cart(purchasableItems: [makeItem(), makeItem()]), retryHandler: {})

        // Then
        if case .success(let state) = result {
            #expect(state == .newOrder)
        } else {
            #expect(Bool(false), "Expected success result with new order")
        }
    }

    @Test func syncOrder_when_cart_matching_order_then_returns_orderNotChanged_result() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // When
        // 1. Initial order
        _ = await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})

        // 2. Syncing existing order with same cart should not update order
        let result = await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})

        // Then
        if case .success(let state) = result {
            #expect(state == .orderNotChanged)
        } else {
            #expect(Bool(false), "Expected success result with no changes to existing order")
        }
    }

    @Test func syncOrder_when_orderService_fails_then_returns_syncOrderState_failure() async throws {
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let cartItem = makeItem(quantity: 1)

        // When
        mockOrderService.orderToReturn = nil
        let result = await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})

        // Then
        if case .failure(let error) = result {
            #expect(error as? SyncOrderStateError == .syncFailure)
        } else {
            #expect(Bool(false), "Expected sync failure but got \(result)")
        }
    }

    @Test func syncOrder_with_cart_matching_order_and_coupons_doesnt_call_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let couponCode = "SAVE10"
        let coupon = OrderCouponLine.fake().copy(code: couponCode)
        let fakeOrder = Order.fake().copy(items: [orderItem], coupons: [coupon])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync to set up the order
        await sut.syncOrder(
            for: Cart(
                purchasableItems: [cartItem],
                coupons: [.init(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: couponCode, summary: "")]
            ),
            retryHandler: {}
        )

        mockOrderService.syncOrderWasCalled = false

        // When - sync with same items and coupons
        await sut.syncOrder(
            for: Cart(
                purchasableItems: [cartItem],
                coupons: [.init(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: couponCode, summary: "")]
            ),
            retryHandler: {}
        )

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @Test func syncOrder_with_matching_items_but_different_coupons_calls_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let initialCouponCode = "SAVE10"
        let initialCoupon = OrderCouponLine.fake().copy(code: initialCouponCode)
        let fakeOrder = Order.fake().copy(items: [orderItem], coupons: [initialCoupon])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync
        await sut.syncOrder(
            for: Cart(
                purchasableItems: [cartItem],
                coupons: [.init(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: initialCouponCode, summary: "")]
            ),
            retryHandler: {}
        )

        mockOrderService.syncOrderWasCalled = false

        // When - sync with same items but different coupon
        await sut.syncOrder(
            for: Cart(
                purchasableItems: [cartItem],
                coupons: [.init(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 2), code: "DIFFERENT20", summary: "")]
            ),
            retryHandler: {}
        )

        // Then
        #expect(mockOrderService.syncOrderWasCalled == true)
    }

    @Test func syncOrder_with_matching_items_but_removed_coupon_calls_orderService() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let couponCode = "SAVE10"
        let coupon = OrderCouponLine.fake().copy(code: couponCode)
        let fakeOrder = Order.fake().copy(items: [orderItem], coupons: [coupon])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync with coupon
        await sut.syncOrder(
            for: Cart(
                purchasableItems: [cartItem],
                coupons: [.init(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: couponCode, summary: "")]
            ),
            retryHandler: {}
        )

        mockOrderService.syncOrderWasCalled = false

        // When - sync with same items but no coupons
        await sut.syncOrder(for: Cart(purchasableItems: [cartItem], coupons: []), retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == true)
    }

    @Test func syncOrder_when_orderService_fails_with_couponsError_then_sets_invalidCoupon_error() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let errorMessage = "Invalid coupon code"
        mockOrderService.errorToReturn = DotcomError.unknown(code: "woocommerce_rest_invalid_coupon", message: errorMessage, data: nil)

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
            await sut.syncOrder(
                for: Cart(
                    purchasableItems: [makeItem()],
                    coupons: [.init(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "INVALID", summary: "")]
                ),
                retryHandler: {}
            )
        }

        await orderStateAppendTask?.value

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .error(.invalidCoupon(errorMessage), {})
        ])
    }

    @Test func syncOrder_when_orderService_fails_with_networkError_containing_couponsError_then_sets_invalidCoupon_error() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
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
            await sut.syncOrder(
                for: Cart(
                    purchasableItems: [makeItem()],
                    coupons: [.init(id: UUID(), posItemIdentifier: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "INVALID", summary: "")]
                ),
                retryHandler: {}
            )
        }

        await orderStateAppendTask?.value

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .error(.invalidCoupon(errorMessage), {})
        ])
    }

    @Test func syncOrder_when_fails_sets_order_to_nil() async throws {
        // Given
        let sut = PointOfSaleOrderController(orderService: mockOrderService,
                                             receiptSender: mockReceiptSender,
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())

        // First create a successful order
        let orderItem = OrderItem.fake().copy(quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        let cartItem = makeItem(orderItemsToMatch: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // Initial sync succeeds
        let initialResult = await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})
        switch initialResult {
        case .success(.newOrder):
            break
        default:
            #expect(Bool(false), "Expected success with new order, got \(initialResult)")
        }

        // Then simulate a failure
        mockOrderService.errorToReturn = SyncOrderStateError.syncFailure
        let failureResult = await sut.syncOrder(for: Cart(purchasableItems: [cartItem, cartItem]), retryHandler: {})
        switch failureResult {
        case .failure(SyncOrderStateError.syncFailure):
            break
        default:
            #expect(Bool(false), "Expected sync failure, got \(failureResult)")
        }

        // When - try syncing with the same cart again
        mockOrderService.errorToReturn = nil
        mockOrderService.orderToReturn = fakeOrder // Restore mock to return success
        let subsequentResult = await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})

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
        private let receiptSender = MockReceiptService()
        private let mockReceiptSender = MockPOSReceiptSender()

        @Test func syncOrder_when_create_order_then_tracks_order_creation_success_event() async throws {
            // Given
            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptSender: mockReceiptSender,
                                                 currencySettingsProvider: MockCurrencySettingsProvider(),
                                                 analytics: analytics)
            let fakeOrderItem = OrderItem.fake().copy(quantity: 1)
            let fakeOrder = Order.fake()
            let fakeCartItem = makeItem(orderItemsToMatch: [fakeOrderItem])
            orderService.orderToReturn = fakeOrder

            // When
            await sut.syncOrder(for: Cart(purchasableItems: [fakeCartItem]), retryHandler: { })

            // Then
            #expect(analytics.events.first(where: { $0.eventName == "order_creation_success" }) != nil)
        }

        @Test func syncOrder_when_create_order_fails_with_order_service_error_then_tracks_order_creation_failure_event() async throws {
            // Given
            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptSender: mockReceiptSender,
                                                 currencySettingsProvider: MockCurrencySettingsProvider(),
                                                 analytics: analytics)
            orderService.orderToReturn = nil

            // When
            await sut.syncOrder(for: Cart(purchasableItems: [makeItem()]), retryHandler: {})

            // Then
            #expect(analytics.events.first(where: { $0.eventName == "order_creation_failed" }) != nil)
        }

        @MainActor
        @Test func collectCashPayment_when_failure_tracks_correct_event() async throws {
            // Given
            let sut = PointOfSaleOrderController(orderService: orderService,
                                                 receiptSender: mockReceiptSender,
                                                 currencySettingsProvider: MockCurrencySettingsProvider(),
                                                 analytics: analytics)

            // In order to test the order controller failure we need to succeed first in creating a successful order:
            let orderItem = OrderItem.fake()
            let fakeOrder = Order.fake().copy(items: [orderItem])
            orderService.orderToReturn = fakeOrder
            await sut.syncOrder(for: Cart(purchasableItems: [makeItem()]), retryHandler: {})

            orderService.resultToReturn = .failure(NSError(domain: "test", code: 0, userInfo: nil))

            // When
            await #expect(performing: {
                try await sut.collectCashPayment(changeDueAmount: nil)
            }, throws: { _ in
                return true
            })

            // Then
            #expect(analytics.events.first(where: { $0.eventName == "cash_payment_failed" }) != nil)
        }
    }

    // MARK: - Price Updates

    @MainActor
    @Test func priceUpdates_when_no_order_returns_empty() {
        // Given
        let sut = PointOfSaleOrderController(orderService: MockPOSOrderService(),
                                             receiptSender: MockPOSReceiptSender(),
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let cart = Cart(purchasableItems: [makeSimpleProductCartItem(price: "10.00", productID: 1)])

        // When
        let updates = sut.priceUpdates(for: cart)

        // Then
        #expect(updates.isEmpty)
    }

    @MainActor
    @Test func priceUpdates_when_prices_match_returns_empty() async {
        // Given
        let orderService = MockPOSOrderService()
        let sut = PointOfSaleOrderController(orderService: orderService,
                                             receiptSender: MockPOSReceiptSender(),
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let product = makeSimpleProduct(price: "10.00", productID: 1)
        let cartItem = Cart.PurchasableItem(id: UUID(), item: product, title: product.name, subtitle: nil, quantity: 1)
        let orderItem = OrderItem.fake().copy(productID: 1, quantity: 1, price: NSDecimalNumber(string: "10.00"))
        orderService.orderToReturn = Order.fake().copy(items: [orderItem])
        await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})

        // When
        let updates = sut.priceUpdates(for: Cart(purchasableItems: [cartItem]))

        // Then
        #expect(updates.isEmpty)
    }

    @MainActor
    @Test func priceUpdates_when_simple_product_price_changed_returns_update() async throws {
        // Given
        let orderService = MockPOSOrderService()
        let sut = PointOfSaleOrderController(orderService: orderService,
                                             receiptSender: MockPOSReceiptSender(),
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let product = makeSimpleProduct(price: "10.00", productID: 42)
        let cartItemID = UUID()
        let cartItem = Cart.PurchasableItem(id: cartItemID, item: product, title: product.name, subtitle: nil, quantity: 1)
        let orderItem = OrderItem.fake().copy(productID: 42, quantity: 1, price: NSDecimalNumber(string: "15.00"))
        orderService.orderToReturn = Order.fake().copy(currency: "USD", items: [orderItem])
        await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})

        // When
        let updates = sut.priceUpdates(for: Cart(purchasableItems: [cartItem]))

        // Then
        #expect(updates.count == 1)
        #expect(updates.first?.cartItemID == cartItemID)
        let updatedProduct = try #require(updates.first?.updatedItem as? POSSimpleProduct)
        #expect(updatedProduct.price == "15")
    }

    @MainActor
    @Test func priceUpdates_when_variation_price_changed_returns_update() async throws {
        // Given
        let orderService = MockPOSOrderService()
        let sut = PointOfSaleOrderController(orderService: orderService,
                                             receiptSender: MockPOSReceiptSender(),
                                             currencySettingsProvider: MockCurrencySettingsProvider(),
                                             analytics: MockPOSAnalytics())
        let variation = makeVariation(price: "5.00", productID: 10, variationID: 20)
        let cartItemID = UUID()
        let cartItem = Cart.PurchasableItem(id: cartItemID, item: variation, title: variation.parentProductName, subtitle: variation.name, quantity: 1)
        let orderItem = OrderItem.fake().copy(productID: 10, variationID: 20, quantity: 1, price: NSDecimalNumber(string: "8.00"))
        orderService.orderToReturn = Order.fake().copy(currency: "USD", items: [orderItem])
        await sut.syncOrder(for: Cart(purchasableItems: [cartItem]), retryHandler: {})

        // When
        let updates = sut.priceUpdates(for: Cart(purchasableItems: [cartItem]))

        // Then
        #expect(updates.count == 1)
        #expect(updates.first?.cartItemID == cartItemID)
        let updatedVariation = try #require(updates.first?.updatedItem as? POSVariation)
        #expect(updatedVariation.price == "8")
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

private func makeSimpleProduct(price: String, productID: Int64) -> POSSimpleProduct {
    POSSimpleProduct(
        id: POSItemIdentifier(underlyingType: .product, itemID: productID),
        name: "Product \(productID)",
        formattedPrice: "$\(price)",
        productID: productID,
        price: price,
        manageStock: false,
        stockQuantity: nil,
        stockStatusKey: "instock"
    )
}

private func makeSimpleProductCartItem(price: String, productID: Int64) -> Cart.PurchasableItem {
    let product = makeSimpleProduct(price: price, productID: productID)
    return Cart.PurchasableItem(id: UUID(), item: product, title: product.name, subtitle: nil, quantity: 1)
}

private func makeVariation(price: String, productID: Int64, variationID: Int64) -> POSVariation {
    POSVariation(
        id: POSItemIdentifier(underlyingType: .variation, itemID: variationID),
        name: "Variation \(variationID)",
        formattedPrice: "$\(price)",
        price: price,
        productID: productID,
        variationID: variationID,
        parentProductName: "Parent \(productID)"
    )
}

// MARK: - Mock Currency Settings Provider

final class MockCurrencySettingsProvider: POSCurrencySettingsProviding {
    let currencySettings: CurrencySettings

    init(currencySettings: CurrencySettings = CurrencySettings(currencyCode: .USD,
                                                                 currencyPosition: .left,
                                                                 thousandSeparator: ",",
                                                                 decimalSeparator: ".",
                                                                 numberOfDecimals: 2)) {
        self.currencySettings = currencySettings
    }
}
