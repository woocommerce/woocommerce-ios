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
    public let formattedTotal: String
    public let formattedSubtotal: String
    public let customerEmail: String?
    public let paymentMethodID: String
    public let paymentMethodTitle: String
    public let lineItems: [POSOrderItem]
    public let refunds: [POSOrderRefund]
    public let currency: String
    public let discountTotal: String
    public let formattedDiscountTotal: String?
    public let totalTax: String
    public let formattedTotalTax: String
    public let formattedPaymentTotal: String
    public let formattedNetAmount: String?

    public init(id: Int64,
                number: String,
                dateCreated: Date,
                datePaid: Date? = nil,
                status: OrderStatusEnum,
                total: String,
                formattedTotal: String,
                formattedSubtotal: String,
                customerEmail: String? = nil,
                paymentMethodID: String,
                paymentMethodTitle: String,
                lineItems: [POSOrderItem] = [],
                refunds: [POSOrderRefund] = [],
                currency: String,
                discountTotal: String,
                totalTax: String,
                formattedTotalTax: String,
                formattedDiscountTotal: String?,
                formattedPaymentTotal: String,
                formattedNetAmount: String? = nil) {
        self.id = id
        self.number = number
        self.dateCreated = dateCreated
        self.datePaid = datePaid
        self.status = status
        self.total = total
        self.formattedTotal = formattedTotal
        self.formattedSubtotal = formattedSubtotal
        self.customerEmail = customerEmail
        self.paymentMethodID = paymentMethodID
        self.paymentMethodTitle = paymentMethodTitle
        self.lineItems = lineItems
        self.refunds = refunds
        self.currency = currency
        self.discountTotal = discountTotal
        self.totalTax = totalTax
        self.formattedTotalTax = formattedTotalTax
        self.formattedDiscountTotal = formattedDiscountTotal
        self.formattedPaymentTotal = formattedPaymentTotal
        self.formattedNetAmount = formattedNetAmount
    }
}
