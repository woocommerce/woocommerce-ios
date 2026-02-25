// periphery:ignore:all
import Foundation

public struct BookingOrderInfo: Hashable {
    public let statusKey: String
    public let orderID: Int64
    public let orderNumber: String
    public let dateCreated: Date
    public let datePaid: Date?
    public let discountTotal: String
    public let customerEmail: String?
    public let paymentInfo: BookingPaymentInfo?
    public let customerInfo: BookingCustomerInfo?
    public let productInfo: BookingProductInfo?
    public let lineItems: [BookingOrderLineItem]
    public let refunds: [BookingOrderRefund]

    public init(statusKey: String,
                orderID: Int64 = 0,
                orderNumber: String = "",
                dateCreated: Date = Date(),
                datePaid: Date? = nil,
                discountTotal: String = "",
                customerEmail: String? = nil,
                paymentInfo: BookingPaymentInfo?,
                customerInfo: BookingCustomerInfo?,
                productInfo: BookingProductInfo?,
                lineItems: [BookingOrderLineItem] = [],
                refunds: [BookingOrderRefund] = []) {
        self.statusKey = statusKey
        self.orderID = orderID
        self.orderNumber = orderNumber
        self.dateCreated = dateCreated
        self.datePaid = datePaid
        self.discountTotal = discountTotal
        self.customerEmail = customerEmail
        self.paymentInfo = paymentInfo
        self.customerInfo = customerInfo
        self.productInfo = productInfo
        self.lineItems = lineItems
        self.refunds = refunds
    }

    public init(booking: Booking, order: Order) {
        self.orderID = order.orderID
        self.orderNumber = order.number
        self.dateCreated = order.dateCreated
        self.datePaid = order.datePaid
        self.discountTotal = order.discountTotal
        self.customerEmail = order.billingAddress?.email
        self.customerInfo = {
            guard let billingAddress = order.billingAddress else {
                return nil
            }
            return BookingCustomerInfo(
                billingAddress: billingAddress,
                note: order.customerNote
            )
        }()
        self.productInfo = BookingProductInfo(name: order.items.first(where: { $0.productID == booking.productID })?.name ?? "")
        self.paymentInfo = BookingPaymentInfo(
            paymentMethodID: order.paymentMethodID,
            paymentMethodTitle: order.paymentMethodTitle,
            subtotal: order.items.map({ Double($0.subtotal) ?? 0 }).reduce(0, +).description,
            subtotalTax: order.items.map({ Double($0.subtotalTax) ?? 0 }).reduce(0, +).description,
            total: order.total,
            totalTax: order.totalTax
        )
        self.lineItems = order.items.map { item in
            BookingOrderLineItem(
                itemID: item.itemID,
                name: item.name,
                productID: item.productID,
                variationID: item.variationID,
                quantity: item.quantity,
                price: item.price,
                subtotal: item.subtotal,
                total: item.total,
                totalTax: item.totalTax,
                imageSrc: item.image?.src
            )
        }
        self.refunds = order.refunds.map { refund in
            BookingOrderRefund(
                refundID: refund.refundID,
                reason: refund.reason,
                total: refund.total
            )
        }
        self.statusKey = order.status.rawValue
    }
}
