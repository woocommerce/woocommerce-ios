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
        let posLineItems = try order.items.map { item in
            try mapLineItem(
                itemID: item.itemID,
                name: item.name,
                quantity: item.quantity,
                price: item.price,
                total: item.total,
                totalTax: item.totalTax,
                imageSrc: item.image?.src,
                attributes: item.attributes,
                currency: order.currency
            )
        }

        let posRefunds = order.refunds.map { refund in
            mapRefund(refundID: refund.refundID, total: refund.total, reason: refund.reason, currency: order.currency)
        }

        let formattedNetAmount: String? = {
            guard !order.refunds.isEmpty else {
                return nil
            }
            return formatNetAmount(total: order.total, refundTotals: order.refunds.map(\.total), currency: order.currency)
        }()

        let lineItemQuantitiesByProductOrVariationID = Self.aggregateLineItemQuantities(
            items: order.items.map { ($0.productID, $0.variationID, $0.quantity) }
        )

        return POSOrder(
            id: order.orderID,
            number: order.number,
            dateCreated: order.dateCreated,
            status: order.status,
            formattedTotal: currencyFormatter.formatAmount(order.total, with: order.currency) ?? "",
            formattedSubtotal: order.subtotalValue(currencyFormatter: currencyFormatter),
            customerEmail: order.billingAddress?.email,
            paymentMethodID: order.paymentMethodID,
            paymentMethodTitle: order.paymentMethodTitle,
            lineItems: posLineItems,
            refunds: posRefunds,
            formattedDiscountTotal: formatDiscountTotal(order.discountTotal, currency: order.currency),
            formattedTotalTax: currencyFormatter.formatAmount(order.totalTax, with: order.currency) ?? "",
            formattedPaymentTotal: order.paymentTotal(currencyFormatter: currencyFormatter),
            formattedNetAmount: formattedNetAmount,
            datePaid: order.datePaid,
            lineItemQuantitiesByProductOrVariationID: lineItemQuantitiesByProductOrVariationID
        )
    }

    // MARK: - Shared Mapping Helpers

    func mapLineItem(
        itemID: Int64,
        name: String,
        quantity: Decimal,
        price: NSDecimalNumber,
        total: String,
        totalTax: String,
        imageSrc: String?,
        attributes: [OrderItemAttribute],
        currency: String
    ) throws -> POSOrderItem {
        guard let totalTaxDecimal = Decimal(string: totalTax) else {
            throw POSOrderItemMappingError.invalidTaxValue(itemID: itemID, value: totalTax)
        }
        guard let formattedPrice = currencyFormatter.formatAmount(price, with: currency) else {
            throw POSOrderItemMappingError.priceFormattingFailed(itemID: itemID, price: price, currency: currency)
        }
        guard let formattedTotal = currencyFormatter.formatAmount(total, with: currency) else {
            throw POSOrderItemMappingError.totalFormattingFailed(itemID: itemID, total: total, currency: currency)
        }

        let totalDecimal = Decimal(string: total) ?? (price as Decimal) * quantity

        return POSOrderItem(
            itemID: itemID,
            name: name,
            quantity: quantity,
            price: price as Decimal,
            total: totalDecimal,
            totalTax: totalTaxDecimal,
            formattedPrice: formattedPrice,
            formattedTotal: formattedTotal,
            imageSrc: imageSrc,
            attributes: attributes
        )
    }

    func mapRefund(refundID: Int64, total: String, reason: String?, currency: String) -> POSOrderRefund {
        POSOrderRefund(
            refundID: refundID,
            formattedTotal: currencyFormatter.formatAmount(total, with: currency) ?? "",
            reason: reason
        )
    }

    func formatDiscountTotal(_ discountTotal: String, currency: String) -> String? {
        guard let discountTotalValue = Double(discountTotal), discountTotalValue > 0 else {
            return nil
        }
        return currencyFormatter.formatAmount(discountTotal, with: currency, isNegative: true) ?? ""
    }

    func formatNetAmount(total: String, refundTotals: [String], currency: String) -> String? {
        guard let totalDecimal = Decimal(string: total) else {
            return nil
        }
        // Normalize each refund total to negative, since the API can briefly
        // return a positive value right after issuing a refund.
        let refundSum = refundTotals.reduce(Decimal.zero) { acc, refundTotal in
            let value = Decimal(string: refundTotal) ?? 0
            return acc + (value > 0 ? -value : value)
        }
        let netAmount = totalDecimal + refundSum
        return currencyFormatter.formatAmount(netAmount, with: currency)
    }

    static func aggregateLineItemQuantities(
        items: [(productID: Int64, variationID: Int64, quantity: Decimal)]
    ) -> [Int64: Decimal] {
        items.reduce(into: [Int64: Decimal]()) { acc, item in
            let id = item.variationID != 0 ? item.variationID : item.productID
            acc[id, default: 0] += item.quantity
        }
    }
}
