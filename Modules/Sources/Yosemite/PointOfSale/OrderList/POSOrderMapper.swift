import Foundation
import class WooFoundationCore.CurrencyFormatter
import struct NetworkingCore.Order
import struct NetworkingCore.OrderItem
import struct NetworkingCore.OrderItemAttribute
import struct NetworkingCore.OrderRefundCondensed

struct POSOrderMapper {
    private let currencyFormatter: CurrencyFormatter

    init(currencyFormatter: CurrencyFormatter) {
        self.currencyFormatter = currencyFormatter
    }

    func map(order: NetworkingCore.Order) -> POSOrder {
        let customerEmail = order.billingAddress?.email

        let posLineItems = order.items.map { map(orderItem: $0, currency: order.currency) }

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

        return POSOrder(
            id: order.orderID,
            number: order.number,
            dateCreated: order.dateCreated,
            status: order.status,
            formattedTotal: currencyFormatter.formatAmount(order.total, with: order.currency) ?? "",
            formattedSubtotal: order.subtotalValue(currencyFormatter: currencyFormatter),
            customerEmail: customerEmail,
            paymentMethodTitle: order.paymentMethodTitle,
            lineItems: posLineItems,
            refunds: posRefunds,
            formattedDiscountTotal: formattedDiscountTotal,
            formattedTotalTax: currencyFormatter.formatAmount(order.totalTax, with: order.currency) ?? "",
            formattedPaymentTotal: order.paymentTotal(currencyFormatter: currencyFormatter),
            formattedNetAmount: formattedNetAmount
        )
    }

    private func map(orderItem: NetworkingCore.OrderItem, currency: String) -> POSOrderItem {
        return POSOrderItem(
            itemID: orderItem.itemID,
            name: orderItem.name,
            quantity: orderItem.quantity,
            formattedPrice: currencyFormatter.formatAmount(orderItem.price, with: currency) ?? "",
            formattedTotal: currencyFormatter.formatAmount(orderItem.total, with: currency) ?? "",
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
