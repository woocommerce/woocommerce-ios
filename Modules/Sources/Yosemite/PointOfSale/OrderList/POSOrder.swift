import Foundation
import struct NetworkingCore.Address
import struct NetworkingCore.OrderItem
import struct NetworkingCore.OrderRefundCondensed
import struct NetworkingCore.MetaData
import enum NetworkingCore.OrderStatusEnum
import struct NetworkingCore.Order

public struct POSOrder: Equatable, Hashable {
    public let id: Int64
    public let number: String
    public let dateCreated: Date
    public let datePaid: Date?
    public let status: OrderStatusEnum
    public let total: String
    public let customerEmail: String?
    public let paymentMethodID: String
    public let paymentMethodTitle: String
    public let lineItems: [POSOrderItem]
    public let refunds: [POSOrderRefund]
    public let currency: String
    public let discountTotal: String
    public let totalTax: String

    public init(id: Int64,
                number: String,
                dateCreated: Date,
                datePaid: Date? = nil,
                status: OrderStatusEnum,
                total: String,
                customerEmail: String? = nil,
                paymentMethodID: String,
                paymentMethodTitle: String,
                lineItems: [POSOrderItem] = [],
                refunds: [POSOrderRefund] = [],
                currency: String,
                discountTotal: String,
                totalTax: String) {
        self.id = id
        self.number = number
        self.dateCreated = dateCreated
        self.datePaid = datePaid
        self.status = status
        self.total = total
        self.customerEmail = customerEmail
        self.paymentMethodID = paymentMethodID
        self.paymentMethodTitle = paymentMethodTitle
        self.lineItems = lineItems
        self.refunds = refunds
        self.currency = currency
        self.discountTotal = discountTotal
        self.totalTax = totalTax
    }
}

// MARK: - Conversion from NetworkingCore.Order
public extension POSOrder {
    init(from order: NetworkingCore.Order) {
        // Extract customer email from billing address
        let customerEmail = order.billingAddress?.email

        // Convert line items to POS format
        let posLineItems = order.items.map { POSOrderItem(from: $0) }

        // Convert refunds to POS format
        let posRefunds = order.refunds.map { POSOrderRefund(from: $0) }

        self.init(
            id: order.orderID,
            number: order.number,
            dateCreated: order.dateCreated,
            datePaid: order.datePaid,
            status: order.status,
            total: order.total,
            customerEmail: customerEmail,
            paymentMethodID: order.paymentMethodID,
            paymentMethodTitle: order.paymentMethodTitle,
            lineItems: posLineItems,
            refunds: posRefunds,
            currency: order.currency,
            discountTotal: order.discountTotal,
            totalTax: order.totalTax
        )
    }
}
