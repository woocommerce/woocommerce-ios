import Testing
import Combine
import Foundation

@testable import WooCommerce
import struct Yosemite.Order
import struct Yosemite.OrderItem
import class WooFoundation.CurrencySettings

struct PointOfSaleOrderControllerTests {
    let sut: PointOfSaleOrderController
    let mockOrderService = MockPOSOrderService()
    let mockReceiptService = MockReceiptService()

    init() {
        self.sut = PointOfSaleOrderController(orderService: mockOrderService, receiptService: mockReceiptService)
    }

    @Test func syncOrder_without_items_doesnt_call_orderService() async throws {
        // Given

        // When
        await sut.syncOrder(for: [], retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @Test func syncOrder_with_cart_matching_order_doesnt_call_orderService() async throws {
        // Given
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

    @Test func syncOrder_when_already_syncing_doesnt_call_orderService() async throws {
        // Given
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

    @Test func syncOrder_with_changes_from_previous_order_calls_orderService() async throws {
        // Given
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

    @Test func syncOrder_with_no_previous_order_sets_orderState_syncing_then_loaded() async throws {
        // Given
        let fakeOrder = Order.fake()
        mockOrderService.orderToReturn = fakeOrder
        var cancellables = Set<AnyCancellable>()
        var orderStates: [PointOfSaleInternalOrderState] = []
        await confirmation() { confirmation in
            // We can use `withObservationTracking` when we move to @Observable
            sut.orderStatePublisher.collect(3)
                .sink { orderState in
                    orderStates.append(contentsOf: orderState)
                    confirmation()
                }
                .store(in: &cancellables)

            // When
            await sut.syncOrder(for: [makeItem()], retryHandler: {})
        }

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .loaded(.init(cartTotal: "$0.00", orderTotal: "", taxTotal: ""),
                    fakeOrder)
        ])
    }

    @Test func syncOrder_with_order_sync_failure_sets_orderState_syncing_then_error() async throws {
        // Given
        mockOrderService.orderToReturn = nil

        var cancellables = Set<AnyCancellable>()
        var orderStates: [PointOfSaleInternalOrderState] = []
        await confirmation() { confirmation in
            // We can use `withObservationTracking` when we move to @Observable
            sut.orderStatePublisher.collect(3)
                .sink { orderState in
                    orderStates.append(contentsOf: orderState)
                    confirmation()
                }
                .store(in: &cancellables)

            // When
            await sut.syncOrder(for: [makeItem()], retryHandler: {})
        }

        // Then
        #expect(orderStates == [
            .idle,
            .syncing,
            .error(.init(
                message: MockPOSOrderServiceError.noOrderToReturn.localizedDescription,
                handler: {}))
        ])
    }

    @Test func sendReceipt_when_there_is_no_order_then_will_not_trigger() async throws {
        // Given
        let email = "test@example.com"

        // When
        try await sut.sendReceipt(recipientEmail: email)

        // Then
        #expect(!mockOrderService.updateOrderWasCalled)
        #expect(!mockReceiptService.sendReceiptWasCalled)
    }

    @Test func sendReceipt_calls_both_updateOrder_and_sendReceipt() async throws {
        // Given
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

    @Test func collectCashPayment_when_no_order_then_fails_with_noOrder_error() async throws {
        do {
            // Given/When
            try await sut.collectCashPayment()
        } catch let error as PointOfSaleOrderController.PointOfSaleOrderControllerError {
            // Then
            #expect(error == .noOrder)
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
