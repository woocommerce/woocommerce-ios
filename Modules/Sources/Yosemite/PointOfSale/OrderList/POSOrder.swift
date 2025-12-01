import Foundation
import Codegen
import struct NetworkingCore.Address
import struct NetworkingCore.OrderItem
import struct NetworkingCore.OrderRefundCondensed
import struct NetworkingCore.MetaData
import enum NetworkingCore.OrderStatusEnum
import struct NetworkingCore.Order

public struct POSOrder: Equatable, Hashable, GeneratedCopiable {
    public let id: Int64
    public let number: String
    public let dateCreated: Date
    public let status: OrderStatusEnum
    public let formattedTotal: String
    public let formattedSubtotal: String
    public let customerEmail: String?
    public let paymentMethodTitle: String
    public let lineItems: [POSOrderItem]
    public let refunds: [POSOrderRefundCondensed]
    public let formattedDiscountTotal: String?
    public let formattedTotalTax: String
    public let formattedPaymentTotal: String
    public let formattedNetAmount: String?

    public init(id: Int64,
                number: String,
                dateCreated: Date,
                status: OrderStatusEnum,
                formattedTotal: String,
                formattedSubtotal: String,
                customerEmail: String? = nil,
                paymentMethodTitle: String,
                lineItems: [POSOrderItem] = [],
                refunds: [POSOrderRefundCondensed] = [],
                formattedDiscountTotal: String?,
                formattedTotalTax: String,
                formattedPaymentTotal: String,
                formattedNetAmount: String? = nil) {
        self.id = id
        self.number = number
        self.dateCreated = dateCreated
        self.status = status
        self.formattedTotal = formattedTotal
        self.formattedSubtotal = formattedSubtotal
        self.customerEmail = customerEmail
        self.paymentMethodTitle = paymentMethodTitle
        self.lineItems = lineItems
        self.refunds = refunds
        self.formattedDiscountTotal = formattedDiscountTotal
        self.formattedTotalTax = formattedTotalTax
        self.formattedPaymentTotal = formattedPaymentTotal
        self.formattedNetAmount = formattedNetAmount
    }
}
