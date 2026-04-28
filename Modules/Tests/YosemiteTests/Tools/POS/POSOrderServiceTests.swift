import Foundation
import Testing
@testable import Yosemite
import enum Networking.DotcomError
import enum Networking.NetworkError
import enum Alamofire.AFError
import struct Networking.AnyDecodable

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
            coupons: [.init(id: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "SAVE10")]
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
                .init(id: POSItemIdentifier(underlyingType: .coupon, itemID: 1), code: "SAVE10"),
                .init(id: POSItemIdentifier(underlyingType: .coupon, itemID: 2), code: "FREESHIP"),
                .init(id: POSItemIdentifier(underlyingType: .coupon, itemID: 3), code: "EXTRA5")
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
    func syncOrder_adds_cart_custom_amounts_to_new_order() async throws {
        // Given
        let cart = POSCart(
            items: [makePOSCartItem(productID: 100, quantity: 1)],
            customAmounts: [
                POSCustomAmount(name: "Service fee", amount: "10.00", isTaxable: true),
                POSCustomAmount(name: "Delivery", amount: "5.50", isTaxable: false)
            ]
        )

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let createdOrderFees = try #require(mockOrdersRemote.spyCreatePOSOrder?.fees)
        #expect(createdOrderFees.count == 2)

        let serviceFee = try #require(createdOrderFees.first(where: { $0.name == "Service fee" }))
        #expect(serviceFee.total == "10.00")
        #expect(serviceFee.taxStatus == .taxable)

        let delivery = try #require(createdOrderFees.first(where: { $0.name == "Delivery" }))
        #expect(delivery.total == "5.50")
        #expect(delivery.taxStatus == .none)
    }

    @Test
    func syncOrder_includes_feeLines_in_request_fields_when_cart_has_custom_amounts() async throws {
        // Given
        let cart = POSCart(
            customAmounts: [POSCustomAmount(name: "Tip", amount: "3.00", isTaxable: false)]
        )

        // When
        _ = try await sut.syncOrder(cart: cart, currency: .USD)

        // Then
        let fields = try #require(mockOrdersRemote.spyCreatePOSOrderFields)
        #expect(fields.contains(.feeLines))
    }

    @Test
    func syncOrder_always_includes_feeLines_in_request_fields_even_for_empty_cart() async throws {
        // Given — no items, coupons, or custom amounts.

        // When
        _ = try await sut.syncOrder(cart: .init(), currency: .USD)

        // Then — `.feeLines` is always sent so the server doesn't keep stale fees from a previous draft.
        let fields = try #require(mockOrdersRemote.spyCreatePOSOrderFields)
        #expect(fields.contains(.feeLines))
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
            #expect(item.total.isEmpty, "Total should be empty string")
            #expect(item.subtotal.isEmpty, "Subtotal should be empty string")
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

    @Test func updatePOSOrder_calls_remote_updatePOSOrderEmail_with_correct_parameters() async throws {
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

    @Test func updatePOSOrder_throws_error_when_remote_call_fails() async throws {
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

    // MARK: - Missing Products Tests

    @Test func syncOrder_throws_error_when_order_is_missing_cart_products() async throws {
        // Given
        let cart = POSCart(items: [
            makePOSCartItem(productID: 100, quantity: 1),
            makePOSCartItem(productID: 200, quantity: 2)
        ])

        // Mock returns an order with only one of the products
        let orderWithMissingProduct = OrderFactory.newOrder(currency: .USD)
            .copy(
                siteID: 123,
                status: .autoDraft,
                items: [
                    OrderItem.fake().copy(productID: 100, quantity: 1)
                ]
            )
        mockOrdersRemote.createPOSOrderResult = .success(orderWithMissingProduct)

        // When/Then
        await #expect(performing: {
            try await sut.syncOrder(cart: cart, currency: .USD)
        }, throws: { error in
            if case .missingProductsInOrder(let missingItems) = error as? POSOrderService.POSOrderServiceError {
                #expect(missingItems.count == 1)
                #expect(missingItems.first?.productID == 200)
                #expect(missingItems.first?.name.isEmpty == true)
                return true
            }
            return false
        })
    }

    @Test func syncOrder_succeeds_when_all_cart_items_in_order() async throws {
        // Given
        let cart = POSCart(items: [
            makePOSCartItem(productID: 100, quantity: 1),
            makePOSCartItem(productID: 200, quantity: 2)
        ])

        // Mock returns an order with all cart items
        let completeOrder = OrderFactory.newOrder(currency: .USD)
            .copy(
                siteID: 123,
                status: .autoDraft,
                items: [
                    OrderItem.fake().copy(productID: 100, quantity: 1),
                    OrderItem.fake().copy(productID: 200, quantity: 2)
                ]
            )
        mockOrdersRemote.createPOSOrderResult = .success(completeOrder)

        // When/Then - Should not throw
        _ = try await sut.syncOrder(cart: cart, currency: .USD)
    }

    @Test func syncOrder_throws_error_when_order_missing_variation() async throws {
        // Given
        let cart = POSCart(items: [
            POSCartItem(
                item: POSVariation(
                    id: POSItemIdentifier(underlyingType: .variation, itemID: 500),
                    name: "Large",
                    formattedPrice: "$20",
                    price: "20",
                    productID: 100,
                    variationID: 500,
                    parentProductName: "T-Shirt"
                ),
                quantity: 1
            )
        ])

        // Mock returns an empty order
        mockOrdersRemote.createPOSOrderResult = .success(OrderFactory.newOrder(currency: .USD))

        // When/Then
        await #expect(performing: {
            try await sut.syncOrder(cart: cart, currency: .USD)
        }, throws: { error in
            if case .missingProductsInOrder(let missingItems) = error as? POSOrderService.POSOrderServiceError {
                #expect(missingItems.count == 1)
                #expect(missingItems.first?.variationID == 500)
                #expect(missingItems.first?.productID == 100)
                return true
            }
            return false
        })
    }

    @Test func syncOrder_distinguishes_between_variations_of_same_product() async throws {
        // Given
        let cart = POSCart(items: [
            POSCartItem(
                item: POSVariation(
                    id: POSItemIdentifier(underlyingType: .variation, itemID: 500),
                    name: "Small",
                    formattedPrice: "$15",
                    price: "15",
                    productID: 100,
                    variationID: 500,
                    parentProductName: "T-Shirt"
                ),
                quantity: 1
            ),
            POSCartItem(
                item: POSVariation(
                    id: POSItemIdentifier(underlyingType: .variation, itemID: 501),
                    name: "Large",
                    formattedPrice: "$20",
                    price: "20",
                    productID: 100,
                    variationID: 501,
                    parentProductName: "T-Shirt"
                ),
                quantity: 1
            )
        ])

        // Mock returns order with only one variation
        let orderWithOneVariation = OrderFactory.newOrder(currency: .USD)
            .copy(
                siteID: 123,
                status: .autoDraft,
                items: [
                    OrderItem.fake().copy(productID: 100, variationID: 500, quantity: 1)
                ]
            )
        mockOrdersRemote.createPOSOrderResult = .success(orderWithOneVariation)

        // When/Then
        await #expect(performing: {
            try await sut.syncOrder(cart: cart, currency: .USD)
        }, throws: { error in
            if case .missingProductsInOrder(let missingItems) = error as? POSOrderService.POSOrderServiceError {
                // Should only report the missing variation (variationID 501)
                #expect(missingItems.count == 1)
                #expect(missingItems.first?.variationID == 501)
                #expect(missingItems.first?.productID == 100)
                return true
            }
            return false
        })
    }

    // MARK: - Server-side Validation Error Tests

    @Test func syncOrder_throws_missingProducts_error_for_DotcomError_with_invalid_variation_code() async throws {
        // Given
        let cart = POSCart(items: [makePOSCartItem(productID: 100, quantity: 1)])
        let dotcomError = DotcomError.unknown(code: "order_item_product_invalid_variation_id", message: "Invalid variation", data: nil)
        mockOrdersRemote.createPOSOrderResult = .failure(dotcomError)

        // When/Then
        await #expect(performing: {
            try await sut.syncOrder(cart: cart, currency: .USD)
        }, throws: { error in
            if case .missingProductsInOrder(let missingItems) = error as? POSOrderService.POSOrderServiceError {
                #expect(missingItems.count == 1)
                #expect(missingItems.first?.productID == 0) // Generic error
                #expect(missingItems.first?.variationID == 0)
                #expect(missingItems.first?.name == "One or more products")
                return true
            }
            return false
        })
    }

    @Test func syncOrder_throws_missingProducts_error_for_NetworkError_with_invalid_variation_code_and_variation_id() async throws {
        // Given
        let cart = POSCart(items: [
            POSCartItem(
                item: POSVariation(
                    id: POSItemIdentifier(underlyingType: .variation, itemID: 500),
                    name: "Large",
                    formattedPrice: "$20",
                    price: "20",
                    productID: 100,
                    variationID: 500,
                    parentProductName: "T-Shirt"
                ),
                quantity: 1
            )
        ])

        let errorJSON = """
        {
            "code": "order_item_product_invalid_variation_id",
            "message": "Invalid variation",
            "data": {
                "variation_id": 500
            }
        }
        """
        let errorData = errorJSON.data(using: .utf8)!
        let networkError = NetworkError.unacceptableStatusCode(statusCode: 400, response: errorData)
        mockOrdersRemote.createPOSOrderResult = .failure(networkError)

        // When/Then
        await #expect(performing: {
            try await sut.syncOrder(cart: cart, currency: .USD)
        }, throws: { error in
            if case .missingProductsInOrder(let missingItems) = error as? POSOrderService.POSOrderServiceError {
                #expect(missingItems.count == 1)
                #expect(missingItems.first?.productID == 100)
                #expect(missingItems.first?.variationID == 500)
                #expect(missingItems.first?.name == "T-Shirt - Large")
                return true
            }
            return false
        })
    }

    @Test func syncOrder_throws_missingProducts_error_for_NetworkError_without_variation_id() async throws {
        // Given
        let cart = POSCart(items: [makePOSCartItem(productID: 100, quantity: 1)])
        let errorJSON = """
        {
            "code": "order_item_product_invalid_variation_id",
            "message": "Invalid variation"
        }
        """
        let errorData = errorJSON.data(using: .utf8)!
        let networkError = NetworkError.unacceptableStatusCode(statusCode: 400, response: errorData)
        mockOrdersRemote.createPOSOrderResult = .failure(networkError)

        // When/Then
        await #expect(performing: {
            try await sut.syncOrder(cart: cart, currency: .USD)
        }, throws: { error in
            if case .missingProductsInOrder(let missingItems) = error as? POSOrderService.POSOrderServiceError {
                #expect(missingItems.count == 1)
                #expect(missingItems.first?.productID == 0) // Generic error
                #expect(missingItems.first?.variationID == 0)
                return true
            }
            return false
        })
    }

    @Test func syncOrder_throws_missingProducts_error_for_AFError_wrapping_DotcomError() async throws {
        // Given
        let cart = POSCart(items: [makePOSCartItem(productID: 100, quantity: 1)])
        let dotcomError = DotcomError.unknown(code: "order_item_product_invalid_variation_id", message: "Invalid", data: nil)
        let afError = AFError.sessionTaskFailed(error: dotcomError)
        mockOrdersRemote.createPOSOrderResult = .failure(afError)

        // When/Then
        await #expect(performing: {
            try await sut.syncOrder(cart: cart, currency: .USD)
        }, throws: { error in
            if case .missingProductsInOrder(let missingItems) = error as? POSOrderService.POSOrderServiceError {
                #expect(missingItems.count == 1)
                return true
            }
            return false
        })
    }

    @Test func syncOrder_throws_original_error_for_unrecognized_DotcomError_code() async throws {
        // Given
        let cart = POSCart(items: [makePOSCartItem(productID: 100, quantity: 1)])
        let dotcomError = DotcomError.unknown(code: "some_other_error_code", message: "Different error", data: nil)
        mockOrdersRemote.createPOSOrderResult = .failure(dotcomError)

        // When/Then
        await #expect(performing: {
            try await sut.syncOrder(cart: cart, currency: .USD)
        }, throws: { error in
            // Should throw the original DotcomError, not missingProductsInOrder
            if case .unknown = error as? DotcomError {
                return true
            }
            return false
        })
    }

    @Test func syncOrder_throws_missingProducts_with_generic_name_when_variation_not_in_cart() async throws {
        // Given
        let cart = POSCart(items: [makePOSCartItem(productID: 100, quantity: 1)])
        let errorJSON = """
        {
            "code": "order_item_product_invalid_variation_id",
            "message": "Invalid variation",
            "data": {
                "variation_id": 999
            }
        }
        """
        let errorData = errorJSON.data(using: .utf8)!
        let networkError = NetworkError.unacceptableStatusCode(statusCode: 400, response: errorData)
        mockOrdersRemote.createPOSOrderResult = .failure(networkError)

        // When/Then
        await #expect(performing: {
            try await sut.syncOrder(cart: cart, currency: .USD)
        }, throws: { error in
            if case .missingProductsInOrder(let missingItems) = error as? POSOrderService.POSOrderServiceError {
                #expect(missingItems.count == 1)
                #expect(missingItems.first?.productID == 0)
                #expect(missingItems.first?.variationID == 999)
                #expect(missingItems.first?.name == "One or more products")
                return true
            }
            return false
        })
    }
}

private func makePOSCartItem(
    productID: Int64,
    quantity: Decimal) -> POSCartItem {
        return POSCartItem(
            item: POSSimpleProduct(id: POSItemIdentifier(underlyingType: .product, itemID: productID),
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
