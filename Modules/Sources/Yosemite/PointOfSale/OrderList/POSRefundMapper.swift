import Foundation
import struct NetworkingCore.Refund
import class WooFoundationCore.CurrencyFormatter

struct POSRefundMapper {
    func map(refund: NetworkingCore.Refund,
                            orderItems: [POSOrderItem],
                            customAmounts: [POSOrderCustomAmount] = [],
                            currencyFormatter: CurrencyFormatter,
                            currency: String) -> [POSRefundItem] {
        let orderItemsByID = Dictionary(uniqueKeysWithValues: orderItems.map { ($0.itemID, $0) })
        let feeIDs = Set(customAmounts.map(\.id))

        return refund.items.map { item in
            let refundedItemID = item.refundedItemID.flatMap { Int64($0) }
            let matchedOrderItem = refundedItemID.flatMap { orderItemsByID[$0] }
            let isLumpSum = refundedItemID.map(feeIDs.contains) ?? false

            let formattedPrice = currencyFormatter.formatAmount(item.price.abs(), with: currency) ?? ""
            let formattedTotal = currencyFormatter.formatAmount(item.total, with: currency) ?? ""

            return POSRefundItem(
                refundedItemID: refundedItemID,
                quantity: abs(item.quantity),
                name: item.name,
                formattedPrice: formattedPrice,
                formattedTotal: formattedTotal,
                imageSrc: matchedOrderItem?.imageSrc,
                isLumpSum: isLumpSum
            )
        }
    }

    /// Computes formatted items subtotal and tax for a refund.
    /// - `item.total` is the line item refund amount (negative from API, made absolute).
    /// - `item.totalTax` is the tax for that item (negative from API, made absolute).
    func mapSubtotalAndTax(refund: NetworkingCore.Refund,
                           currencyFormatter: CurrencyFormatter,
                           currency: String) -> (formattedSubtotal: String, formattedTax: String) {
        var subtotal = Decimal.zero
        var tax = Decimal.zero

        for item in refund.items {
            subtotal += abs(Decimal(string: item.total) ?? .zero)
            tax += abs(Decimal(string: item.totalTax) ?? .zero)
        }

        let formattedSubtotal = currencyFormatter.formatAmount(subtotal, with: currency) ?? ""
        let formattedTax = currencyFormatter.formatAmount(tax, with: currency) ?? ""
        return (formattedSubtotal, formattedTax)
    }
}
