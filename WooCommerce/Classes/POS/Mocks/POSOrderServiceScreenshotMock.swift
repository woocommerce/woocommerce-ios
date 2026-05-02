import Foundation
import Yosemite
import WooFoundationCore
import class WooFoundation.CurrencySettings
import struct NetworkingCore.OrderItem
import PointOfSale

/// Mock order service for screenshot tests that returns immediate loaded state
final class POSOrderServiceScreenshotMock: POSOrderServiceProtocol {
    // periphery: ignore - needed for conformance, not explicitely for the mock
    private let currency: String

    init(currency: String) {
        self.currency = currency
    }

    func syncOrder(cart: POSCart, currency: CurrencyCode) async throws -> Order {
        // Create a mock order with totals calculated from the cart
        // For screenshot tests with 2 products: $35.00 + $45.00 = $80.00
        let orderItems = [
            OrderItem(
                itemID: 1,
                name: "Product 1",
                productID: 1,
                variationID: 0,
                quantity: 1,
                price: NSDecimalNumber(string: "35.00"),
                sku: nil,
                subtotal: "35.00",
                subtotalTax: "0.00",
                taxClass: "",
                taxes: [],
                total: "35.00",
                totalTax: "0.00",
                attributes: [],
                addOns: [],
                image: nil,
                parent: nil,
                bundleConfiguration: []
            ),
            OrderItem(
                itemID: 2,
                name: "Product 2",
                productID: 2,
                variationID: 0,
                quantity: 1,
                price: NSDecimalNumber(string: "45.00"),
                sku: nil,
                subtotal: "45.00",
                subtotalTax: "0.00",
                taxClass: "",
                taxes: [],
                total: "45.00",
                totalTax: "0.00",
                attributes: [],
                addOns: [],
                image: nil,
                parent: nil,
                bundleConfiguration: []
            )
        ]

        let total = "80.00"
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
                    items: orderItems,  // Necessary for the card payment flow to be presented in POS
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
}
