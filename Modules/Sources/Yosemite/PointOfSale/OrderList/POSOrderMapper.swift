import Foundation
import class WooFoundationCore.CurrencyFormatter
import struct NetworkingCore.Order
import struct NetworkingCore.OrderItem
import struct NetworkingCore.OrderItemAttribute
import struct NetworkingCore.OrderRefundCondensed

enum POSOrderItemMappingError: Error {
    case invalidTaxValue(itemID: Int64, value: String)
    case priceFormattingFailed(itemID: Int64, price: NSDecimalNumber, currency: String)
    case totalFormattingFailed(itemID: Int64, total: String, currency: String)
}

struct POSOrderMapper {
    private let currencyFormatter: CurrencyFormatter

    init(currencyFormatter: CurrencyFormatter) {
        self.currencyFormatter = currencyFormatter
    }

    func map(order: NetworkingCore.Order) throws -> POSOrder {
        let customerEmail = order.billingAddress?.email

        let posLineItems = try order.items.map { try map(orderItem: $0, currency: order.currency) }

        let posRefunds = order.refunds.map { map(orderRefund: $0, currency: order.currency) }

        let formattedDiscountTotal: String? = {
            guard let discountTotalValue = Double(order.discountTotal), discountTotalValue > 0 else {
                return nil
            }
            return currencyFormatter.formatAmount(order.discountTotal, with: order.currency, isNegative: true) ?? ""
        }()

        let formattedNetAmount: String? = {
            guard !order.refunds.isEmpty else {
                return nil
            }
            return order.netAmount(currencyFormatter: currencyFormatter)
        }()

        // Aggregate quantities by product/variation ID for refund comparison
        let lineItemQuantitiesByProductOrVariationID = order.items.reduce(into: [Int64: Decimal]()) { acc, item in
            let id = item.variationID != 0 ? item.variationID : item.productID
            acc[id, default: 0] += item.quantity
        }

        return POSOrder(
            id: order.orderID,
            number: order.number,
            dateCreated: order.dateCreated,
            status: order.status,
            formattedTotal: currencyFormatter.formatAmount(order.total, with: order.currency) ?? "",
            formattedSubtotal: order.subtotalValue(currencyFormatter: currencyFormatter),
            customerEmail: customerEmail,
            paymentMethodID: order.paymentMethodID,
            paymentMethodTitle: order.paymentMethodTitle,
            lineItems: posLineItems,
            refunds: posRefunds,
            formattedDiscountTotal: formattedDiscountTotal,
            formattedTotalTax: currencyFormatter.formatAmount(order.totalTax, with: order.currency) ?? "",
            formattedPaymentTotal: order.paymentTotal(currencyFormatter: currencyFormatter),
            formattedNetAmount: formattedNetAmount,
            lineItemQuantitiesByProductOrVariationID: lineItemQuantitiesByProductOrVariationID
        )
    }

    private func map(orderItem: NetworkingCore.OrderItem, currency: String) throws -> POSOrderItem {
        guard let totalTax = Decimal(string: orderItem.totalTax) else {
            throw POSOrderItemMappingError.invalidTaxValue(itemID: orderItem.itemID, value: orderItem.totalTax)
        }
        guard let formattedPrice = currencyFormatter.formatAmount(orderItem.price, with: currency) else {
            throw POSOrderItemMappingError.priceFormattingFailed(itemID: orderItem.itemID, price: orderItem.price, currency: currency)
        }
        guard let formattedTotal = currencyFormatter.formatAmount(orderItem.total, with: currency) else {
            throw POSOrderItemMappingError.totalFormattingFailed(itemID: orderItem.itemID, total: orderItem.total, currency: currency)
        }

        return POSOrderItem(
            itemID: orderItem.itemID,
            name: orderItem.name,
            quantity: orderItem.quantity,
            price: orderItem.price as Decimal,
            totalTax: totalTax,
            formattedPrice: formattedPrice,
            formattedTotal: formattedTotal,
            imageSrc: orderItem.image?.src,
            attributes: orderItem.attributes
        )
    }

    private func map(orderRefund: NetworkingCore.OrderRefundCondensed, currency: String) -> POSOrderRefund {
        return POSOrderRefund(
            refundID: orderRefund.refundID,
            formattedTotal: currencyFormatter.formatAmount(orderRefund.total, with: currency) ?? "",
            reason: orderRefund.reason
        )
    }
}
