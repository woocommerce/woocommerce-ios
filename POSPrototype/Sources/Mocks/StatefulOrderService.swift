import Foundation
import Yosemite
import struct Networking.Order
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
        return Order.empty.copy(
            siteID: 1,
            orderID: orderCounter,
            status: .pending,
            currency: configuration.currencyCode,
            total: "0.00"
        )
    }

    func loadOrder(orderID: Int64) async throws -> Order {
        Order.empty.copy(siteID: 1, orderID: orderID)
    }

    func updatePOSOrder(orderID: Int64, recipientEmail: String) async throws {
        // no-op for prototype
    }

    func markOrderAsCompletedWithCashPayment(order: Order, changeDueAmount: String?) async throws {
        // no-op for prototype
    }
}
