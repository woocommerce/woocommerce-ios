import Foundation
import Testing
@testable import Yosemite

struct POSOrderServiceTests {
    let sut: POSOrderService
    let mockOrdersRemote: MockPOSOrdersRemote

    init() {
        let mockOrdersRemote = MockPOSOrdersRemote()
        self.mockOrdersRemote = mockOrdersRemote
        self.sut = POSOrderService(siteID: 123, ordersRemote: mockOrdersRemote)
    }

    @Test
    func syncOrder_creates_a_new_order() async throws {
        // Given

        // When
        _ = try await sut.syncOrder(cart: .init(), currency: .USD)

        // Then
        #expect(mockOrdersRemote.createPOSOrderCalled == true)
    }

    @Test
    func syncOrder_creates_a_new_order_using_passed_currency() async throws {
        // Given

        // When
        _ = try await sut.syncOrder(cart: .init(), currency: .EUR)

        // Then
        #expect(mockOrdersRemote.spyCreatePOSOrder?.currency.uppercased() == "EUR")
        let fields = try #require(mockOrdersRemote.spyCreatePOSOrderFields)
        #expect(fields.contains(.currency) == true)
    }

    @Test
    func syncOrder_adds_cart_items_to_new_order() async throws {
        // Given
        let cart = POSCart(items: [
            makePOSCartItem(productID: 100, quantity: 2),
            makePOSCartItem(productID: 102, quantity: 1)
        ])

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let createdOrderItems = try #require(mockOrdersRemote.spyCreatePOSOrder?.items)
        #expect(createdOrderItems.contains(where: { (item: OrderItem) -> Bool in
            item.productID == 100 && item.quantity == 2
        }))
        #expect(createdOrderItems.contains(where: { (item: OrderItem) -> Bool in
            item.productID == 102 && item.quantity == 1
        }))
    }

    @Test
    func syncOrder_adds_cart_coupons_to_new_order() async throws {
        // Given
        let cart = POSCart(
            items: [makePOSCartItem(productID: 100, quantity: 1)],
            coupons: [.init(id: UUID(), code: "SAVE10")]
        )

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let createdOrderCoupons = try #require(mockOrdersRemote.spyCreatePOSOrder?.coupons)
        #expect(createdOrderCoupons.count == 1)
        #expect(createdOrderCoupons.first?.code == "SAVE10")
    }

    @Test
    func syncOrder_with_multiple_coupons_adds_all_to_new_order() async throws {
        // Given
        let cart = POSCart(
            items: [makePOSCartItem(productID: 100, quantity: 1)],
            coupons: [
                .init(id: UUID(), code: "SAVE10"),
                .init(id: UUID(), code: "FREESHIP"),
                .init(id: UUID(), code: "EXTRA5")
            ]
        )

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let createdOrderCoupons = try #require(mockOrdersRemote.spyCreatePOSOrder?.coupons)
        #expect(createdOrderCoupons.count == 3)
        #expect(createdOrderCoupons.contains(where: { $0.code == "SAVE10" }))
        #expect(createdOrderCoupons.contains(where: { $0.code == "FREESHIP" }))
        #expect(createdOrderCoupons.contains(where: { $0.code == "EXTRA5" }))
    }

    @Test
    func syncOrder_sanitizes_items_before_sending_to_remote() async throws {
        // Given
        let cart = POSCart(items: [
            makePOSCartItem(productID: 100, quantity: 2),
            makePOSCartItem(productID: 101, quantity: 1)
        ])

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let orderSentToRemote = try #require(mockOrdersRemote.spyCreatePOSOrder)

        // Verify all items in the order are sanitized
        for item in orderSentToRemote.items {
            #expect(item.itemID == 0, "Item ID should be zero for new items")
            #expect(item.total == "", "Total should be empty string")
            #expect(item.subtotal == "", "Subtotal should be empty string")
        }
    }

    @Test
    func markOrderAsCompletedWithCashPayment_updates_order_status_and_payment_method() async throws {
        // Given
        let order = OrderFactory.newOrder(currency: .USD)

        // When
        try await sut.markOrderAsCompletedWithCashPayment(order: order, changeDueAmount: nil)

        // Then
        let updatedOrder = try #require(mockOrdersRemote.spyUpdatePOSOrder)
        #expect(updatedOrder.status == .completed)
        #expect(updatedOrder.paymentMethodID == PaymentGateway.Constants.cashOnDeliveryGatewayID)
        #expect(updatedOrder.paymentMethodTitle == "Pay in Person")

        let fields = try #require(mockOrdersRemote.spyUpdatePOSOrderFields)
        #expect(fields.contains(.status))
        #expect(fields.contains(.paymentMethodID))
        #expect(fields.contains(.paymentMethodTitle))
    }

    @Test
    func markOrderAsCompletedWithCashPayment_passes_change_due_amount() async throws {
        // Given
        let order = OrderFactory.newOrder(currency: .USD)

        // When
        try await sut.markOrderAsCompletedWithCashPayment(order: order, changeDueAmount: "$6.02")

        // Then
        let changeDueAmount = try #require(mockOrdersRemote.spyUpdatePOSOrderCashPaymentChangeDueAmount)
        #expect(changeDueAmount == "$6.02")
    }

    @Test
    func markOrderAsCompletedWithCashPayment_throws_error_when_update_fails() async throws {
        // Given
        let order = OrderFactory.newOrder(currency: .USD)
        mockOrdersRemote.updatePOSOrderResult = .failure(NSError(domain: "", code: 0))

        // When/Then
        await #expect(performing: {
            try await sut.markOrderAsCompletedWithCashPayment(order: order, changeDueAmount: nil)
        }, throws: { _ in
            // The actual error `POSOrderServiceError.updateOrderFailed` is private, thus we cannot check against the exact error.
            return true
        })
    }

    @Test
    func updatePOSOrder_calls_remote_updatePOSOrderEmail_with_correct_parameters() async throws {
        // Given
        let siteID: Int64 = 123
        let orderID: Int64 = 456
        let recipientEmail = "test@example.com"

        // When
        try await sut.updatePOSOrder(orderID: orderID, recipientEmail: recipientEmail)

        // Then
        #expect(mockOrdersRemote.updatePOSOrderEmailCalled == true)
        #expect(mockOrdersRemote.spyUpdatePOSOrderEmailSiteID == siteID)
        #expect(mockOrdersRemote.spyUpdatePOSOrderEmailOrderID == orderID)
        #expect(mockOrdersRemote.spyUpdatePOSOrderEmailAddress == recipientEmail)
    }

    @Test
    func updatePOSOrder_throws_error_when_remote_call_fails() async throws {
        // Given
        mockOrdersRemote.updatePOSOrderEmailResult = .failure(NSError(domain: "", code: 0))

        // When/Then
        await #expect(performing: {
            try await sut.updatePOSOrder(orderID: 456, recipientEmail: "test@example.com")
        }, throws: { _ in
            // The actual error `POSOrderServiceError.updateOrderFailed` is private, thus we cannot check against the exact error.
            return true
        })
    }
}

private func makePOSCartItem(
    productID: Int64,
    quantity: Decimal) -> POSCartItem {
        return POSCartItem(
            item: POSSimpleProduct(id: UUID(),
                                   name: "",
                                   formattedPrice: "",
                                   productID: productID,
                                   price: "",
                                   manageStock: false,
                                   stockQuantity: nil,
                                   stockStatusKey: ""),
            quantity: quantity
        )
    }
