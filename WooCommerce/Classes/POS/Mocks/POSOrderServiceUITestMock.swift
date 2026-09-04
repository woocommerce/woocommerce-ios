#if DEBUG

import Foundation
import Yosemite
import WooFoundationCore
import struct NetworkingCore.OrderItem
import PointOfSale

final class POSOrderServiceUITestMock: POSOrderServiceProtocol {
    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order {
        let orderItems = cart.items.enumerated().map { index, cartItem in
            makeOrderItem(from: cartItem, itemID: Int64(index + 1))
        }
        let total = orderItems
            .map { NSDecimalNumber(string: $0.total) }
            .reduce(NSDecimalNumber(value: 0)) { $0.adding($1) }
            .stringValue
        let tax = "0.00"

        return Order(siteID: 0,
                     orderID: 1,
                     parentID: 0,
                     customerID: 0,
                     orderKey: "",
                     isEditable: true,
                     needsPayment: true,
                     needsProcessing: true,
                     number: "1",
                     status: .pending,
                     currency: currency.rawValue,
                     currencySymbol: "$",
                     customerNote: nil,
                     dateCreated: Date(),
                     dateModified: Date(),
                     datePaid: nil,
                     discountTotal: "0.00",
                     discountTax: "0.00",
                     shippingTotal: "0.00",
                     shippingTax: "0.00",
                     total: total,
                     totalTax: tax,
                     paymentMethodID: "",
                     paymentMethodTitle: "",
                     paymentURL: nil,
                     chargeID: nil,
                     items: orderItems,
                     billingAddress: nil,
                     shippingAddress: nil,
                     shippingLines: [],
                     coupons: [],
                     refunds: [],
                     fees: [],
                     taxes: [],
                     customFields: [],
                     renewalSubscriptionID: nil,
                     appliedGiftCards: [],
                     attributionInfo: nil,
                     shippingLabels: [],
                     createdVia: "pos")
    }

    func loadOrder(orderID: Int64) async throws -> Order {
        try await syncOrder(cart: POSCart(items: [], coupons: []), currency: .USD)
    }

    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {}

    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws {}

    func markOrderAsCompletedManually(order: Order) async throws {}

    func promoteOrderToPending(order: Order) async throws -> Order { order }

    func addOrderNote(orderID: Int64, isCustomerNote: Bool, note: String) async throws {}

    func recordScanToPayPaymentMethod(order: Order) async throws {}

    private func makeOrderItem(from cartItem: POSCartItem, itemID: Int64) -> OrderItem {
        let productIdentifiers = productIdentifiers(for: cartItem.item)
        let price = NSDecimalNumber(string: productIdentifiers.price)
        let quantity = cartItem.quantity
        let subtotal = price.multiplying(by: NSDecimalNumber(decimal: quantity)).stringValue

        return OrderItem(
            itemID: itemID,
            name: cartItem.item.name,
            productID: productIdentifiers.productID,
            variationID: productIdentifiers.variationID,
            quantity: quantity,
            price: price,
            sku: nil,
            subtotal: subtotal,
            subtotalTax: "0.00",
            taxClass: "",
            taxes: [],
            total: subtotal,
            totalTax: "0.00",
            attributes: [],
            addOns: [],
            image: nil,
            parent: nil,
            bundleConfiguration: []
        )
    }

    private func productIdentifiers(for item: POSOrderableItem) -> (productID: Int64, variationID: Int64, price: String) {
        if let product = item as? POSSimpleProduct {
            return (product.productID, 0, product.price)
        }
        if let variation = item as? POSVariation {
            return (variation.productID, variation.productVariationID, variation.price)
        }
        return (item.id.itemID, 0, "0.00")
    }
}

#endif
