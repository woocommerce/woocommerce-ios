import Foundation
import Yosemite
import struct Networking.Order
import struct Networking.OrderItem
import struct Networking.OrderItemProductImage
import enum WooFoundation.CurrencyCode

final class StatefulOrderService: POSOrderServiceProtocol {
    private let configuration: MockConfiguration
    private var orderCounter: Int64 = 1000

    init(configuration: MockConfiguration) {
        self.configuration = configuration
    }

    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order {
        try await Task.sleep(nanoseconds: UInt64(configuration.orderSyncDelay * 1_000_000_000))

        if configuration.orderSyncShouldFail {
            throw NSError(domain: "POSPrototype", code: 100, userInfo: [
                NSLocalizedDescriptionKey: "Order sync failed (mock)"
            ])
        }

        orderCounter += 1

        // Compute totals from cart items
        var subtotal: Decimal = 0
        var orderItems: [OrderItem] = []
        for (index, cartItem) in cart.items.enumerated() {
            let price = Decimal(string: cartItem.item.formattedPrice
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")) ?? 0
            let lineTotal = price * cartItem.quantity
            subtotal += lineTotal

            orderItems.append(OrderItem(
                itemID: Int64(index + 1),
                name: cartItem.item.name,
                productID: 0,
                variationID: 0,
                quantity: cartItem.quantity,
                price: price as NSDecimalNumber,
                sku: nil,
                subtotal: "\(lineTotal)",
                subtotalTax: "0.00",
                taxClass: "",
                taxes: [],
                total: "\(lineTotal)",
                totalTax: "0.00",
                attributes: [],
                addOns: [],
                image: nil,
                parent: nil,
                bundleConfiguration: []
            ))
        }

        let tax = subtotal * configuration.taxRate
        let total = subtotal + tax

        return Order.empty.copy(
            siteID: 1,
            orderID: orderCounter,
            needsPayment: true,
            number: "\(orderCounter)",
            status: .pending,
            currency: configuration.currencyCode,
            total: "\(total)",
            totalTax: "\(tax)",
            items: orderItems
        )
    }

    func loadOrder(orderID: Int64) async throws -> Order {
        Order.empty.copy(siteID: 1, orderID: orderID, needsPayment: true, total: "10.00")
    }

    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {
        // no-op for prototype
    }

    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws {
        // no-op for prototype
    }
}
