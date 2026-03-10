import Foundation
import struct NetworkingCore.Refund
import class WooFoundationCore.CurrencyFormatter

struct POSRefundMapper {
    func map(refund: NetworkingCore.Refund,
                            orderItems: [POSOrderItem],
                            currencyFormatter: CurrencyFormatter,
                            currency: String) -> [POSRefundItem] {
        let orderItemsByID = Dictionary(uniqueKeysWithValues: orderItems.map { ($0.itemID, $0) })

        return refund.items.map { item in
            let refundedItemID = item.refundedItemID.flatMap { Int64($0) }
            let matchedOrderItem = refundedItemID.flatMap { orderItemsByID[$0] }

            let formattedPrice = currencyFormatter.formatAmount(item.price.abs(), with: currency) ?? ""
            let formattedTotal = currencyFormatter.formatAmount(item.total, with: currency) ?? ""

            return POSRefundItem(
                refundedItemID: refundedItemID,
                quantity: abs(item.quantity),
                name: item.name,
                formattedPrice: formattedPrice,
                formattedTotal: formattedTotal,
                imageSrc: matchedOrderItem?.imageSrc
            )
        }
    }
}
