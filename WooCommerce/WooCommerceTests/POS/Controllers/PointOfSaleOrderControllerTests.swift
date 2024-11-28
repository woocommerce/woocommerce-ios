import Testing
import Combine
import Foundation

@testable import WooCommerce
import struct Yosemite.Order
import struct Yosemite.OrderItem

struct PointOfSaleOrderControllerTests {
    let sut: PointOfSaleOrderController
    let mockOrderService = MockPOSOrderService()

    init() {
        self.sut = PointOfSaleOrderController(orderService: mockOrderService)
    }

    @Test func syncOrder_without_items_doesnt_call_orderService() async throws {
        // Given

        // When
        await sut.syncOrder(for: [], retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @Test func syncOrder_with_unchanged_items_doesnt_call_orderService() async throws {
        // Given
        let productID: Int64 = 123
        let cartItem = makeItem(productID: productID, quantity: 1)
        let orderItem = OrderItem.fake().copy(productID: productID, quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
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
            await sut.syncOrder(for: [makeItem(productID: 1, quantity: 1)], retryHandler: {})
        }
        try await Task.sleep(nanoseconds: UInt64(100 * Double(NSEC_PER_MSEC)))
        mockOrderService.syncOrderWasCalled = false

        // When
        await sut.syncOrder(for: [makeItem(productID: 1, quantity: 2),
                                  makeItem(productID: 5, quantity: 5)],
                            retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled == false)
    }

    @Test func syncOrder_with_no_previous_order_calls_orderService() async throws {
        // Given

        // When
        await sut.syncOrder(for: [makeItem()], retryHandler: {})

        // Then
        #expect(mockOrderService.syncOrderWasCalled)
    }

    @Test func syncOrder_with_changes_from_previous_order_calls_orderService() async throws {
        // Given
        let cartItem = makeItem(productID: 5, quantity: 1)
        let orderItem = OrderItem.fake().copy(productID: 5, quantity: 1)
        let fakeOrder = Order.fake().copy(items: [orderItem])
        mockOrderService.orderToReturn = fakeOrder

        // When
        await sut.syncOrder(for: [cartItem, makeItem(productID: 9, quantity: 1)], retryHandler: {})

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
}

private func makeItem(productID: Int64 = 1,
                      name: String = "",
                      formattedPrice: String = "",
                      quantity: Int = 1) -> CartItem {
    return CartItem(id: UUID(),
                    item: MockPOSItem(name: name,
                                      formattedPrice: formattedPrice),
                    quantity: quantity)
}
